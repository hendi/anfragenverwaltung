import re
import json

from django.template.loader import render_to_string

from django.views.generic import TemplateView, View
from django.shortcuts import render, get_object_or_404
from django.core.exceptions import PermissionDenied
from django.db import connection
from django.utils import timezone
from django.db.models import Q
from django.http import HttpResponse, HttpResponseRedirect, Http404
from django.contrib import messages


from braces.views import JSONResponseMixin, CsrfExemptMixin

from .models import Conversation, Message, IncomingMessage, OutgoingMessage


def reply_to_conversation(immobilie_id, conversation_id, message_text):
    conversation = get_object_or_404(Conversation,
                                     id=conversation_id,
                                     immobilie_id=immobilie_id)

    message = OutgoingMessage.objects.create(
        conversation=conversation,
        immobilie_id=immobilie_id,
        message=message_text,
        date_sent=timezone.now(),
        to_email=conversation.sender_email,
    )

    # mark all previous IncomingMessages as read and replied-to
    IncomingMessage.objects.filter(
        conversation=conversation,
        immobilie_id=immobilie_id,
        date_sent__lte=timezone.now(),
    ).update(is_replied_to=True, is_read=True)

    # also mark conversation
    conversation.is_replied_to = True
    conversation.is_read = True
    conversation.save(update_fields=["is_replied_to", "is_read"])

    return {
        "conversation_id": conversation.id,
        "id": message.id,
        "message_type": "outgoing",
        "content": message.message,
        "date": message.date_sent,
        "attachments": [],
    }


def reply_to_conversations(immobilie_id, conversation_ids, message_text):
    conversations = Conversation.objects.filter(id__in=conversation_ids,
                                                immobilie_id=immobilie_id)

    for conversation in conversations:
        message = OutgoingMessage.objects.create(
            conversation=conversation,
            immobilie_id=immobilie_id,
            message=message_text,
            date_sent=timezone.now(),
            to_email=conversation.sender_email,
        )

    # mark all previous IncomingMessages as read and replied-to
    IncomingMessage.objects.filter(
        conversation__in=conversations,
        immobilie_id=immobilie_id,
        date_sent__lte=timezone.now(),
    ).update(is_replied_to=True, is_read=True)

    # also mark conversations
    conversations.update(is_replied_to=True, is_read=True)


class ConversationListForImmobilie(View, JSONResponseMixin):
    def get(self, request, immo_id):
        # show all messages
        qs = Conversation.objects.filter(immobilie_id=immo_id)
        conversations = [conversation.to_json() for conversation in qs]
        return self.render_json_response(sorted(conversations, reverse=True, key=lambda k: k["date_last_message"]))


class MessageListForConversation(View, JSONResponseMixin):
    def get(self, request, immo_id, conversation_id):
        conversation = get_object_or_404(Conversation, id=conversation_id, immobilie_id=immo_id)

        # mark all IncomingMessages for this conversation as read
        IncomingMessage.objects.filter(conversation=conversation).update(is_read=True)

        # same for Conversation
        #conversation.is_read = True
        #conversation.save(update_fields=["is_read"])

        messages = [
            {
                "id": x.id,
                "conversation_id": conversation.id,
                "message_type": x.type,
                "content": x.message,
                "date": x.date_sent,
                "attachments": []
            } for x in conversation.message_set.filter(Q(
                Q(incomingmessage__isnull=False)
                | Q(outgoingmessage__isnull=False)
            ))
        ]

        return self.render_json_response(sorted(messages, key=lambda k: k["date"] or timezone.now()))


class ReplyToConversation(CsrfExemptMixin, View, JSONResponseMixin):
    def post(self, request, immo_id, conversation_id):
        message_text = json.loads(request.body.decode("utf-8")).get("message").replace("\x00", "")

        return self.render_json_response(
            reply_to_conversation(immo_id, conversation_id, message_text)
        )


class MassReply(CsrfExemptMixin, View, JSONResponseMixin):
    def post(self, request, immo_id):
        data = json.loads(request.body.decode("utf-8"))
        reply_to_conversations(immo_id, data.get("conversation_ids", []), data.get("message"))

        return self.render_json_response({"status": "ok"})


class MassTrash(CsrfExemptMixin, View, JSONResponseMixin):
    def post(self, request, immo_id):
        data = json.loads(request.body.decode("utf-8"))

        conversations = Conversation.objects.filter(id__in=data.get("conversation_ids", []), immobilie_id=immo_id)
        conversations.update(is_in_trash=True, is_read=True)

        return self.render_json_response({"status": "ok"})


class ChangeConversation(CsrfExemptMixin, View, JSONResponseMixin):
    def post(self, request, immo_id, conversation_id):
        conversation = get_object_or_404(Conversation, id=conversation_id, immobilie_id=immo_id)

        data = json.loads(request.body.decode("utf-8"))

        if data.get("rating") in ["green", "yellow", "red", ""]:
            IncomingMessage.objects.filter(conversation=conversation).update(is_read=True)
            conversation.is_read = True
            conversation.rating = data["rating"]
            conversation.save(update_fields=["is_read", "rating"])

        if data.get("trash"):
            conversation.is_in_trash = True
            conversation.is_read = True
            conversation.save(update_fields=["is_in_trash", "is_read"])
            IncomingMessage.objects.filter(conversation=conversation).update(is_read=True)

        if data.get("untrash"):
            conversation.is_in_trash = False
            conversation.is_read = False
            conversation.save(update_fields=["is_in_trash", "is_read"])

            # to mark untrash-ed message as "unread"
            latest_incoming = IncomingMessage.objects.filter(conversation=conversation).latest()
            latest_incoming.is_read = False
            latest_incoming.save(update_fields=["is_read"])

        if data.get("junk"):
            conversation.is_junk = True
            conversation.is_read = True
            conversation.save(update_fields=["is_junk", "is_read"])

            # mark message as read
            IncomingMessage.objects.filter(conversation=conversation).update(is_read=True)

        if data.get("unjunk"):
            conversation.is_junk = False
            conversation.is_read = False
            conversation.save(update_fields=["is_junk", "is_read"])

            # to mark unjunk-ed message as "unread"
            latest_incoming = IncomingMessage.objects.filter(conversation=conversation).latest()
            latest_incoming.is_read = False
            latest_incoming.save(update_fields=["is_read"])

        if data.get("ignore"):
            conversation.is_ignored = True
            conversation.save(update_fields=["is_ignored"])

        if data.get("unignore"):
            conversation.is_ignored = False
            conversation.save(update_fields=["is_ignored"])

        if "is_read" in data:
            conversation.is_read = bool(data.get("is_read"))
            conversation.save(update_fields=["is_read"])

        if "notes" in data:
            conversation.notes = data["notes"].strip()
            conversation.save(update_fields=["notes"])

        return self.render_json_response(conversation.to_json())


def qs_for_folder(qs, folder):
    if folder == "New":
        return qs.filter(is_in_trash=False). \
            filter(
                Q(rating="", is_replied_to=False, is_ignored=False)
                | Q(is_read=False)
            )

    elif folder == "Unreplied":
        return qs.filter(is_in_trash=False, is_replied_to=False, is_ignored=False)

    elif folder == "Green":
        return qs.filter(is_in_trash=False, rating="green")

    elif folder == "Yellow":
        return qs.filter(is_in_trash=False, rating="yellow")

    elif folder == "Red":
        return qs.filter(is_in_trash=False, rating="red")

    elif folder == "Unrated":
        return qs.filter(is_in_trash=False, rating="")

    elif folder == "Replied":
        return qs.filter(is_in_trash=False, has_been_replied_to=True)

    elif folder == "All":
        return qs.filter(is_in_trash=False)

    elif folder == "Trash":
        return qs.filter(is_in_trash=True)

    else:
        raise Exception("invalid `folder`")


class FolderCountsForImmobilie(View, JSONResponseMixin):
    def get(self, request, immo_id):
        # show all messages
        qs = Conversation.objects.filter(immobilie_id=immo_id)

        counts = {
            "New": qs_for_folder(qs, "New").count(),
            "Unreplied": qs_for_folder(qs, "Unreplied").count(),
            "Green": qs_for_folder(qs, "Green").count(),
            "Yellow": qs_for_folder(qs, "Yellow").count(),
            "Red": qs_for_folder(qs, "Red").count(),
            "Unrated": qs_for_folder(qs, "Unrated").count(),
            "Replied": qs_for_folder(qs, "Replied").count(),
            "All": qs_for_folder(qs, "All").count(),
            "Trash": qs_for_folder(qs, "Trash").count(),
        }

        return self.render_json_response(counts)


def search_by_string(conv, s):
    return s in conv["name"].lower() \
        or s in conv["email"].lower() \
        or s in conv["phone"].lower() \
        or s in conv["city"].lower() \
        or s in conv["zipcode"].lower() \
        or s in conv["street"].lower() \
        or s in conv["latest_message"]["content"].lower() \
        or s in conv["notes"].lower()


class ConversationListForFolder(View, JSONResponseMixin):
    def get(self, request, immo_id, folder):
        # filter by Immobilie
        qs = Conversation.objects.filter(immobilie_id=immo_id)

        # filter by Folder
        try:
            qs = qs_for_folder(qs, folder)
        except:
            raise Http404

        conversations = [conversation.to_json() for conversation in qs]
        conversations = sorted(conversations, reverse=True, key=lambda k: k["date_last_message"])

        # handle search
        search_string = request.GET.get("search", "").strip().lower()
        if len(search_string) >= 3:
            conversations = [conv for conv in conversations if search_by_string(conv, search_string)]

        # handle limit and pagination
        try:
            limit = max(min(50, int(request.GET.get("limit"))), 1)
        except:
            limit = 10

        try:
            page = max(int(request.GET.get("page")), 1)
        except:
            page = 1

        start = (page-1) * limit
        end = start + limit

        return self.render_json_response({
            "data": conversations[start:end],
            "more": end < len(conversations),
            "result_count": len(conversations),
        })
