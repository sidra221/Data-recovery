from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import JobViewSet, LoginView, health, meta

router = DefaultRouter()
router.register("jobs", JobViewSet, basename="job")

urlpatterns = [
    path("health/", health, name="health"),
    path("auth/login/", LoginView.as_view(), name="login"),
    path("meta/", meta, name="meta"),
    path("", include(router.urls)),
]
