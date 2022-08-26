from django.urls import re_path, path

from .views import ConversationListForImmobilie, ChangeConversation, MessageListForConversation, ReplyToConversation, MassReply, MassTrash
from .views import FolderCountsForImmobilie, ConversationListForFolder

from . import api_views

urlpatterns = [
    # mobile app
    path("api/login", api_views.LoginView.as_view()),
    path("api/immobilien", api_views.ImmobilieListView.as_view()),
    re_path(r"^api/immobilien/(?P<immo_id>\d+)/conversations$", api_views.ConversationListForImmobilie.as_view()),
    re_path(r"^api/immobilien/(?P<immo_id>\d+)/conversations/(?P<conversation_id>\d+)$", api_views.ChangeConversation.as_view()),
    re_path(r"^api/immobilien/(?P<immo_id>\d+)/conversations/(?P<conversation_id>\d+)/reply$", api_views.ReplyToConversation.as_view()),
    re_path(r"^api/immobilien/(?P<immo_id>\d+)/conversations/massreply$", api_views.MassReply.as_view()),
    re_path(r"^api/immobilien/(?P<immo_id>\d+)/conversations/masschange$", api_views.MassChange.as_view()),

    # reason app
    #re_path(r"^immobilie/(?P<immo_id>\d+)/conversations$", ConversationListForImmobilie.as_view()),
    #re_path(r"^immobilie/(?P<immo_id>\d+)/conversations/(?P<conversation_id>\d+)$", ChangeConversation.as_view()),
    #re_path(r"^immobilie/(?P<immo_id>\d+)/conversations/(?P<conversation_id>\d+)/messages$", MessageListForConversation.as_view()),
    #re_path(r"^immobilie/(?P<immo_id>\d+)/conversations/(?P<conversation_id>\d+)/reply$", ReplyToConversation.as_view()),
    #re_path(r"^immobilie/(?P<immo_id>\d+)/massreply$", MassReply.as_view()),
    #re_path(r"^immobilie/(?P<immo_id>\d+)/masstrash$", MassTrash.as_view()),
    #re_path(r"^immobilie/(?P<immo_id>\d+)/folder_counts$", FolderCountsForImmobilie.as_view()),
    #re_path(r"^immobilie/(?P<immo_id>\d+)/conversations/folder/(?P<folder>[A-Z][a-z]+)$", ConversationListForFolder.as_view()),
]
