from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('anfragen/', include('messagearea.urls')),
]
