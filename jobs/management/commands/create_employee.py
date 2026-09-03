from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand, CommandError
from rest_framework.authtoken.models import Token


class Command(BaseCommand):
    help = "إنشاء موظف مع توكن API"

    def add_arguments(self, parser):
        parser.add_argument("username")
        parser.add_argument("password")

    def handle(self, *args, **options):
        user_model = get_user_model()
        username = options["username"]
        if user_model.objects.filter(username=username).exists():
            raise CommandError(f"المستخدم {username} موجود مسبقاً.")

        user = user_model.objects.create_user(
            username=username,
            password=options["password"],
            is_staff=True,
        )
        token, _ = Token.objects.get_or_create(user=user)
        self.stdout.write(self.style.SUCCESS(f"تم إنشاء الموظف: {username}"))
        self.stdout.write(f"Token: {token.key}")
