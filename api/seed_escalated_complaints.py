from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from api.models import Student, Complaint, EscalationLog


class Command(BaseCommand):
    help = 'Seed 6 escalated complaints for Super Admin testing'

    def handle(self, *args, **kwargs):
        student = Student.objects.first()
        if not student:
            self.stdout.write(self.style.ERROR('No students found. Register at least one student first.'))
            return

        self.stdout.write(f'Using student: {student.student_id} - {student.name}')

        complaints_data = [
            {
                'title': 'Library books not returned on time',
                'complaint_type': 'Library Issue',
                'description': 'Several books borrowed 3 months ago have not been returned. Library staff not responding.',
                'admin_type': 'library',
                'days_old': 5,
                'is_anonymous': False,
            },
            {
                'title': 'Hostel water supply interrupted',
                'complaint_type': 'Hostel Issue',
                'description': 'No water supply in Block C since last week. Multiple requests ignored.',
                'admin_type': 'hostel',
                'days_old': 7,
                'is_anonymous': False,
            },
            {
                'title': 'Transport bus not showing up',
                'complaint_type': 'Transport Issue',
                'description': 'Bus route 4 has been missing for 4 days. Students stranded every morning.',
                'admin_type': 'transport',
                'days_old': 4,
                'is_anonymous': False,
            },
            {
                'title': 'Exam result not updated',
                'complaint_type': 'Examination Issue',
                'description': 'Mid-term result from last month still not updated in the portal.',
                'admin_type': 'examination',
                'days_old': 6,
                'is_anonymous': False,
            },
            {
                'title': 'Fee challan not generated',
                'complaint_type': 'Treasury Issue',
                'description': 'Semester fee challan not generated yet. Deadline approaching.',
                'admin_type': 'treasury',
                'days_old': 8,
                'is_anonymous': False,
            },
            {
                'title': 'Security issue near parking area',
                'complaint_type': 'Security Issue',
                'description': 'Unauthorized vehicles parked daily near main gate. Security not addressing this.',
                'admin_type': 'security',
                'days_old': 5,
                'is_anonymous': True,
            },
        ]

        created = 0
        for i, item in enumerate(complaints_data):
            days_old = item['days_old']
            is_anonymous = item['is_anonymous']

            complaint = Complaint.objects.create(
                student=student,
                roll_number=student.student_id,
                department=student.department,
                session=student.session or '2024-2028',
                title=item['title'],
                complaint_type=item['complaint_type'],
                description=item['description'],
                admin_type=item['admin_type'],
                status='pending',
                is_seen_by_admin=True,
                is_anonymous=is_anonymous,
                anonymous_display_id=f'ANON-{9000 + i:04d}' if is_anonymous else None,
            )

            # Backdate created_at to simulate old complaint
            backdated = timezone.now() - timedelta(days=days_old)
            Complaint.objects.filter(pk=complaint.pk).update(created_at=backdated)

            # Create EscalationLog — this is what Super Admin reads
            EscalationLog.objects.create(
                complaint=complaint,
                reason=f'Pending for more than 1 day ({days_old} days)',
                escalated_at=timezone.now() - timedelta(days=days_old - 1),
            )

            label = 'Anonymous' if is_anonymous else student.name
            self.stdout.write(self.style.SUCCESS(
                f'  Created: #{complaint.pk} "{complaint.title}" [{complaint.admin_type}] - {days_old} days old | {label}'
            ))
            created += 1

        self.stdout.write(self.style.SUCCESS(f'\nDone! {created} escalated complaints created.'))
        self.stdout.write('Open Super Admin -> Escalated Complaints to see them.')