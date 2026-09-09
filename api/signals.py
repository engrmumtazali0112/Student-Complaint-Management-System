from django.db.models.signals import post_save
from django.dispatch import receiver
from django.utils import timezone
from .models import Complaint, Notification, AdminProfile
from django.contrib.auth.models import User


@receiver(post_save, sender=Complaint)
def create_complaint_notifications(sender, instance, created, **kwargs):
    """
    Fires on every Complaint save.

    Created  → mark unseen for admin (no admin notification model yet).
    Updated  → notify student on status change:
                 • resolved  → prompt student to rate the admin
                 • rejected  → tell student the rejection reason
    """

    if created:
        # Mark new complaint unseen without triggering the signal again
        try:
            AdminProfile.objects.filter(role=instance.admin_type)  # just validate dept exists
            Complaint.objects.filter(pk=instance.pk).update(is_seen_by_admin=False)
        except Exception as e:
            print(f"[signals] Error on complaint creation: {e}")

    else:
        # ── Resolved ──────────────────────────────────────────────────────
        if instance.status == "resolved":
            # Avoid duplicate notifications on repeated saves
            already = Notification.objects.filter(
                student=instance.student,
                message__startswith=f"✅ Your complaint '{instance.title or instance.complaint_type}' has been resolved",
            ).exists()

            if not already:
                Notification.objects.create(
                    student=instance.student,
                    message=(
                        f"✅ Your complaint '{instance.title or instance.complaint_type}' "
                        f"has been resolved. Please rate the admin's performance by going to "
                        f"My Complaints → view this complaint → Rate Admin."
                    ),
                    created_at=timezone.now(),
                )

        # ── Rejected ──────────────────────────────────────────────────────
        elif instance.status == "rejected" and instance.rejection_remarks:
            already = Notification.objects.filter(
                student=instance.student,
                message__startswith=f"❌ Your complaint '{instance.title or instance.complaint_type}' was rejected",
            ).exists()

            if not already:
                Notification.objects.create(
                    student=instance.student,
                    message=(
                        f"❌ Your complaint '{instance.title or instance.complaint_type}' "
                        f"was rejected. Reason: {instance.rejection_remarks}"
                    ),
                    created_at=timezone.now(),
                )