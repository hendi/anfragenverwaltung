import re
import json

from django.db import models
from django.db.models import Q
from django.utils import timezone


class Conversation(models.Model):
    class Meta:
        unique_together = ("immobilie_id", "sender_email")

    # pkey
    sender_email = models.TextField(
        verbose_name="E-Mail",
        db_index=True,
    )

    immobilie_id = models.IntegerField()

    # data
    name = models.TextField()
    phone = models.TextField(blank=True)
    street = models.TextField(blank=True)
    zipcode = models.TextField(blank=True)
    city = models.TextField(blank=True)
    source = models.TextField(blank=True)
    rating = models.CharField(max_length=32, default="")
    is_in_trash = models.BooleanField(default=False)
    is_ignored = models.BooleanField(default=False)
    is_junk = models.BooleanField(default=False)
    notes = models.TextField(blank=True)
    is_read = models.BooleanField(default=False)
    is_replied_to = models.BooleanField(default=False)
    has_been_replied_to = models.BooleanField(default=False)
    count_messages = models.IntegerField()
    date_last_change = models.DateTimeField(auto_now=True)

    @property
    def _latest(self):
        return self.message_set.filter(Q(Q(incomingmessage__isnull=False) | Q(outgoingmessage__isnull=False))).latest()

    @property
    def date_last_message(self):
        return self._latest.date_sent

    @property
    def latest_message(self):
        return self._latest

    @property
    def has_attachments(self):
        for message in self.message_set.all():
            if message.attachment_set.exists():
                return True

        return False

    def to_json(self, include_messages=False, since=None):
        data = {
            "id": self.id,
            "immobilie_id": self.immobilie_id,

            "name": self.name,
            "email": self.sender_email,
            "phone": self.phone,
            "street": self.street,
            "zipcode": self.zipcode,
            "city": self.city,
            "source": self.source or "",

            "has_attachments": self.has_attachments,
            "rating": self.rating,

            "notes": self.notes,
            "is_read": self.is_read or False,
            "is_replied_to": self.is_replied_to or False,
            "has_been_replied_to": self.has_been_replied_to or False,
            "is_in_trash": self.is_in_trash or False,
            "is_ignored": self.is_ignored or False,
            "is_junk": self.is_junk or False,

            "date_last_message": str(self.date_last_message),
            "count_messages": self.count_messages or 0,

            "latest_message": {
                "id": self._latest.id,
                "conversation_id": self.id,
                "type": self._latest.type,
                "content": self._latest.message,
                "date": str(self._latest.date_sent),
                "attachments": [{
                    "filename": att.filename,
                    "url": "https://dev-mobileapp.ohne-makler.net/anfragen/api/immobilien/%d/attachments/%d" % (self.immobilie_id, att.id),
                } for att in self._latest.attachment_set.all()],
            },
        }

        if include_messages is True:
            data["messages"] = sorted(
                [
                    {
                        "id": x.id,
                        "conversation_id": self.id,
                        "type": x.type,
                        "content": x.message,
                        "date": x.date_sent,
                        "attachments": [{
                            "filename": att.filename,
                            "url": "https://dev-mobileapp.ohne-makler.net/anfragen/api/immobilien/%d/attachments/%d" % (self.immobilie_id, att.id),
                        } for att in x.attachment_set.all()],
                    } for x in self.message_set.filter(Q(
                        Q(incomingmessage__isnull=False)
                        | Q(outgoingmessage__isnull=False)
                    ))
                ],
                reverse=False,
                key=lambda k: (k["date"] or timezone.now())
            )

            if since:
                data["messages"] = [x for x in data["messages"] if x["date"] is None or x["date"] > since]

        return data


class Message(models.Model):
    class Meta:
        get_latest_by = "date_sent"

    conversation = models.ForeignKey(to=Conversation, on_delete=models.CASCADE)
    immobilie_id = models.IntegerField()
    message = models.TextField()
    date_sent = models.DateTimeField(blank=True, null=True)

    @property
    def type(self):
        if IncomingMessage.objects.filter(message_ptr=self.id).exists():
            return "incoming"
        elif OutgoingMessage.objects.filter(message_ptr=self.id).exists():
            return "outgoing"


class IncomingMessage(Message):
    from_email = models.TextField(blank=True)
    is_read = models.BooleanField(default=False)
    is_replied_to = models.BooleanField(default=False)

    def save(self, *args, **kwargs):
        if self.is_read is False and self.conversation.is_read is not False:
            self.conversation.is_read = False
            self.conversation.save(update_fields=["is_read", "date_last_change"])

        if self.is_replied_to is False and self.conversation.is_replied_to is not False:
            self.conversation.is_replied_to = False
            self.conversation.save(update_fields=["is_replied_to", "date_last_change"])

        return super().save(*args, **kwargs)


class OutgoingMessage(Message):
    to_email = models.TextField(blank=True)

    def save(self, *args, **kwargs):
        if self.conversation.has_been_replied_to is not True:
            self.conversation.has_been_replied_to = True
            self.conversation.save(update_fields=["has_been_replied_to", "date_last_change"])

        return super().save(*args, **kwargs)


class Attachment(models.Model):
    immobilie_id = models.IntegerField()

    filename = models.CharField(max_length=255)
    content = models.TextField()

    messages = models.ManyToManyField(Message)


class User(models.Model):
    email = models.CharField(max_length=255)
    password = models.CharField(max_length=255)


class SessionToken(models.Model):
    user = models.ForeignKey(
        to=User,
        on_delete=models.CASCADE,
    )

    token = models.CharField(max_length=255)


class DeviceToken(models.Model):
    user = models.ForeignKey(
        to=User,
        on_delete=models.CASCADE,
    )

    token = models.CharField(max_length=255)
    label = models.CharField(max_length=255)
