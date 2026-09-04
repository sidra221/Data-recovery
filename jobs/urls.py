from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import (
    CustomerViewSet,
    JobViewSet,
    LoginView,
    QuotationViewSet,
    dashboard_stats,
    health,
    meta,
)

router = DefaultRouter()
router.register("jobs", JobViewSet, basename="job")
router.register("customers", CustomerViewSet, basename="customer")
router.register("quotations", QuotationViewSet, basename="quotation")

urlpatterns = [
    path("health/", health, name="health"),
    path("auth/login/", LoginView.as_view(), name="login"),
    path("meta/", meta, name="meta"),
    path("dashboard/stats/", dashboard_stats, name="dashboard-stats"),
    path("", include(router.urls)),
]
