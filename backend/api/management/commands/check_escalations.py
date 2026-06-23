from django.core.management.base import BaseCommand
from api.models import Complaint, EscalationLog


class Command(BaseCommand):
    help = (
        'Scan pending complaints and create an EscalationLog entry for any '
        'complaint that has crossed Complaint.ESCALATION_THRESHOLD. Run this '
        'manually while testing, or schedule it (cron / Task Scheduler) to '
        'run periodically in production.'
    )

    def handle(self, *args, **kwargs):
        already_escalated_ids = set(
            EscalationLog.objects.values_list('complaint_id', flat=True)
        )

        candidates = Complaint.objects.filter(status='pending').exclude(
            id__in=already_escalated_ids
        )

        created = 0
        for complaint in candidates:
            if complaint.is_escalation_needed():
                EscalationLog.objects.create(
                    complaint=complaint,
                    reason=f'Pending for more than {Complaint.ESCALATION_LABEL}',
                )
                created += 1
                self.stdout.write(self.style.SUCCESS(
                    f'  Escalated: #{complaint.pk} '
                    f'"{complaint.title or complaint.complaint_type}" '
                    f'[{complaint.admin_type}]'
                ))

        if created == 0:
            self.stdout.write('No complaints needed escalation right now.')
        else:
            self.stdout.write(self.style.SUCCESS(
                f'\nDone! {created} complaint(s) escalated.'
            ))