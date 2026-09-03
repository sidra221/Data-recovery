from django.contrib import admin
from django.urls import include, path

admin.site.site_header = "01 Data Recovery"
admin.site.site_title = "01 Data Recovery"
admin.site.index_title = "لوحة التحكم"

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/", include("jobs.urls")),
]
