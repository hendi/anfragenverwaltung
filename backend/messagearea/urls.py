from django.urls import re_path

from .views import ConversationListForImmobilie, ChangeConversation, MessageListForConversation, ReplyToConversation, MassReply, MassTrash


urlpatterns = [
    re_path(r"^immobilie/(?P<immo_id>\d+)/conversations$", ConversationListForImmobilie.as_view()),
    re_path(r"^immobilie/(?P<immo_id>\d+)/conversations/(?P<conversation_id>\d+)$", ChangeConversation.as_view()),
    re_path(r"^immobilie/(?P<immo_id>\d+)/conversations/(?P<conversation_id>\d+)/messages$", MessageListForConversation.as_view()),
    re_path(r"^immobilie/(?P<immo_id>\d+)/conversations/(?P<conversation_id>\d+)/reply$", ReplyToConversation.as_view()),
    re_path(r"^immobilie/(?P<immo_id>\d+)/massreply$", MassReply.as_view()),
    re_path(r"^immobilie/(?P<immo_id>\d+)/masstrash$", MassTrash.as_view()),
]
