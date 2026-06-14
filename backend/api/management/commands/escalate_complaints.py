"""
Management command: escalate_complaints
Run via cron or celery-beat, e.g.:
    python manage.py escalate_complaints
    python manage.py escalate_complaints --threshold 2

Escalates complaints that have been PENDING for >= threshold days
(default = 2 days, configurable via --threshold flag or settings.ESCALATION_THRESHOLD_DAYS).
"""

from django.core.management.base import BaseCommand
from django.utils import timezone
from django.conf import settings
from datetime import timedelta

from api.models import Complaint, EscalationLog, Notification


class Command(BaseCommand):
    help = "Automatically escalate complaints pending beyond threshold days"

    def add_arguments(self, parser):
        parser.add_argument(
            "--threshold",
            type=int,
            default=getattr(settings, "ESCALATION_THRESHOLD_DAYS", 2),
            help="Number of days after which a pending complaint is escalated (default: 2)",
        )
        parser.add_argument(
            "--dry-run",
            action="store_true",
            help="Preview escalations without saving to DB",
        )

    def handle(self, *args, **options):
        threshold = options["threshold"]
        dry_run = options["dry_run"]
        cutoff = timezone.now() - timedelta(days=threshold)

        # Get complaints pending beyond threshold that haven't been escalated yet
        already_escalated_ids = EscalationLog.objects.values_list(
            "complaint_id", flat=True
        )
        stale_complaints = Complaint.objects.filter(
            status="pending",
            created_at__lte=cutoff,
        ).exclude(id__in=already_escalated_ids).select_related("student")

        count = stale_complaints.count()
        self.stdout.write(
            self.style.WARNING(
                f"[escalate_complaints] Found {count} complaint(s) to escalate "
                f"(threshold: {threshold} day(s), dry_run: {dry_run})"
            )
        )

        for complaint in stale_complaints:
            days_pending = (timezone.now() - complaint.created_at).days
            reason = f"Pending for {days_pending} day(s) — exceeded {threshold}-day threshold"

            if dry_run:
                self.stdout.write(
                    f"  [DRY-RUN] Would escalate Complaint #{complaint.id}: "
                    f"{complaint.title or complaint.complaint_type} "
                    f"({complaint.student.student_id})"
                )
                continue

            # Create escalation log
            EscalationLog.objects.create(
                complaint=complaint,
                reason=reason
            )

            # Notify the student
            Notification.objects.create(
                student=complaint.student,
                message=(
                    f"⚠️ Your complaint '{complaint.title or complaint.complaint_type}' "
                    f"has been escalated to the Super Admin for faster resolution "
                    f"(pending for {days_pending} day(s))."
                ),
            )

            self.stdout.write(
                self.style.SUCCESS(
                    f"  ✓ Escalated Complaint #{complaint.id} "
                    f"[{complaint.admin_type}] — {complaint.student.student_id}"
                )
            )

        if not dry_run:
            self.stdout.write(
                self.style.SUCCESS(
                    f"[escalate_complaints] Done. {count} complaint(s) escalated."
                )
            )
        else:
            self.stdout.write(
                self.style.SUCCESS(
                    f"[escalate_complaints] Dry run completed. Would escalate {count} complaint(s)."
                )
            )