from django.urls import path

from . import views

app_name = "apitokens"

urlpatterns = [
    path("tokens/", views.dashboard, name="dashboard"),
    path("tokens/<int:pk>/toggle/", views.toggle_active, name="toggle"),
]
