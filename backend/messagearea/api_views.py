import re
import json
import time
from datetime import datetime

from django.template.loader import render_to_string

from django.views.generic import TemplateView, View
from django.shortcuts import render, get_object_or_404
from django.core.exceptions import PermissionDenied
from django.db import connection
from django.utils import timezone
from django.db.models import Q
from django.http import HttpResponse, HttpResponseRedirect, Http404
from django.contrib import messages
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator


from braces.views import JSONResponseMixin, JsonRequestResponseMixin, CsrfExemptMixin

from .models import Conversation, Message, IncomingMessage, OutgoingMessage
from .views import qs_for_folder, reply_to_conversation, reply_to_conversations


class LoginView(CsrfExemptMixin, JsonRequestResponseMixin, View):
    require_json = True

    def post(self, request):
        if not self.request_json.get("username") \
           or not self.request_json.get("password") \
           or "device_label" not in self.request_json:
            return self.render_json_response({
                "errors": ["missing username and/or password and/or device_label"],
            }, status=400)

        if self.request_json["password"] == "pass":
            return self.render_json_response({
                "status": "success",
                "token": "bearer-token-1234-valid",
            })

        return self.render_json_response({
            "errors": ["INVALID_PASSWORD"],
        })


class AuthenticatedApiView(JsonRequestResponseMixin, View):
    def check_token(self, token):
        try:
            bearer, token = token.split(" ")
            assert bearer.lower() == "bearer"

            if token.endswith("-valid"):
                return True
        except:
            return self.render_json_response({
                "errors": ["invalid Authorization header"],
            }, status=400)

        return False

    @method_decorator(csrf_exempt)
    def dispatch(self, request, *args, **kwargs):
        res = self.check_token(request.META.get("HTTP_AUTHORIZATION", ""))
        if res is True:
            return super().dispatch(request, *args, **kwargs)
        elif res is False:
            return self.render_json_response({
                "errors": ["INVALID_TOKEN"],
            })
        else:
            return res


class ImmobilieListView(AuthenticatedApiView):
    def get(self, request):
        return self.render_json_response([
            {
                "id": 123456,
                "title": "Schönes Haus am Stadtrand",
                "zipcode": 51503,
                "city": "Rösrath",
                "image": "https://cdn.pixabay.com/photo/2017/04/10/22/28/residence-2219972__340.jpg",
                "is_archived": False,
                "delete_messages": False,
                "new_messages": qs_for_folder(Conversation.objects.filter(immobilie_id=123456), "New").count(),
            },
            {
                "id": 177865,
                "title": "Test-Immobilie mit vielen Nachrichten",
                "zipcode": 21509,
                "city": "Glinde",
                "image": "https://cdn.pixabay.com/photo/2019/03/01/18/52/house-4028391__340.jpg",
                "is_archived": False,
                "delete_messages": False,
                "new_messages": qs_for_folder(Conversation.objects.filter(immobilie_id=177865), "New").count(),
            },
            {
                "id": 1,
                "title": "Altes Objekt in der Speicherstadt, das mittlerweile verkauft wurde und die Anzeige nicht mehr einsehbar ist",
                "zipcode": 22417,
                "city": "Hamburg",
                "image": "https://cdn.pixabay.com/photo/2018/01/09/12/20/hamburg-3071437__480.jpg",
                "is_archived": True,
                "delete_messages": True,
                "new_messages": None,
            },            
        ])


class ConversationListForImmobilie(AuthenticatedApiView):
    def get(self, request, immo_id):
        try:
            since = timezone.make_aware(datetime.fromtimestamp(int(request.GET["since"])))
        except:
            since = None

        # include ALL messages
        qs = Conversation.objects.filter(immobilie_id=immo_id)

        if since:
            qs = [x for x in qs if x.date_last_change > since]

        conversations = [conversation.to_json(include_messages=True, since=since) for conversation in qs]

        return self.render_json_response(
            {
                "now": int(time.time()),
                "conversations": sorted(conversations, reverse=True, key=lambda k: k["date_last_message"]),
            }
        )


class ChangeConversation(AuthenticatedApiView):
    require_json = True

    def patch(self, request, immo_id, conversation_id):
        conversation = get_object_or_404(Conversation, id=conversation_id, immobilie_id=immo_id)

        if self.request_json.get("rating") in ["green", "yellow", "red", ""]:
            conversation.rating = self.request_json["rating"]
            conversation.save(update_fields=["rating", "date_last_change"])

        if "is_in_trash" in self.request_json:
            conversation.is_in_trash = self.request_json["is_in_trash"]
            conversation.save(update_fields=["is_in_trash", "date_last_change"])

        if "is_junk" in self.request_json:
            conversation.is_junk = self.request_json["is_junk"]
            conversation.save(update_fields=["is_junk", "date_last_change"])

        if "is_ignored" in self.request_json:
            conversation.is_ignored = self.request_json.get("is_ignored")
            conversation.save(update_fields=["is_ignored", "date_last_change"])

        if "is_read" in self.request_json:
            conversation.is_read = self.request_json.get("is_read")
            conversation.save(update_fields=["is_read", "date_last_change"])

        if "notes" in self.request_json:
            conversation.notes = self.request_json["notes"].strip()
            conversation.save(update_fields=["notes", "date_last_change"])

        return self.render_json_response(conversation.to_json())


class ReplyToConversation(AuthenticatedApiView):
    require_json = True

    def post(self, request, immo_id, conversation_id):
        if "message" not in self.request_json:
            return self.render_json_response({
                "errors": ["missing message"],
            }, status=400)

        message_text = self.request_json["message"].replace("\x00", "")

        return self.render_json_response(
            reply_to_conversation(immo_id, conversation_id, message_text)
        )


class MassReply(AuthenticatedApiView):
    require_json = True

    def post(self, request, immo_id):
        if "message" not in self.request_json:
            return self.render_json_response({
                "errors": ["missing message"],
            }, status=400)

        if "conversation_ids" not in self.request_json:
            return self.render_json_response({
                "errors": ["missing conversation_ids"],
            }, status=400)

        reply_to_conversations(immo_id, self.request_json["conversation_ids"], self.request_json["message"])

        return self.render_json_response({"status": "ok"})


class MassChange(AuthenticatedApiView):
    require_json = True

    def post(self, request, immo_id):
        if "conversation_ids" not in self.request_json:
            return self.render_json_response({
                "errors": ["missing conversation_ids"],
            }, status=400)

        conversations = Conversation.objects.filter(id__in=self.request_json["conversation_ids"])

        if self.request_json.get("rating") in ["green", "yellow", "red", ""]:
            conversations.update(rating=self.request_json["rating"], date_last_change=timezone.now())

        if "is_in_trash" in self.request_json:
            conversations.update(is_in_trash=self.request_json["is_in_trash"], date_last_change=timezone.now())

        if "is_junk" in self.request_json:
            conversations.update(is_junk=self.request_json["is_junk"], date_last_change=timezone.now())

        if "is_ignored" in self.request_json:
            conversations.update(is_ignored=self.request_json["is_ignored"], date_last_change=timezone.now())

        if "is_read" in self.request_json:
            conversations.update(is_read=self.request_json["is_read"], date_last_change=timezone.now())

        if "notes" in self.request_json:
            conversations.update(notes=self.request_json["notes"].strip(), date_last_change=timezone.now())

        return self.render_json_response({"status": "ok"})
