from django.db.models.signals import post_save
from django.dispatch import receiver
from django.utils import timezone
from .models import Complaint, Notification, AdminProfile
from django.contrib.auth.models import User

@receiver(post_save, sender=Complaint)
def create_complaint_notifications(sender, instance, created, **kwargs):
    """Create notifications when complaint is created or updated"""
    
    if created:
        # New complaint submitted - notify the assigned admin department
        try:
            # Find admin users with matching role
            admin_profiles = AdminProfile.objects.filter(role=instance.admin_type)
            
            for admin_profile in admin_profiles:
                # Create notification for admin (you'll need an AdminNotification model)
                # For now, we'll mark complaint as unseen
                instance.is_seen_by_admin = False
                instance.save(update_fields=['is_seen_by_admin'])
                
        except Exception as e:
            print(f"Error creating admin notification: {e}")
    
    else:
        # Status changed - notify student
        if instance.status == 'resolved':
            Notification.objects.create(
                student=instance.student,
                message=f"✅ Your complaint '{instance.title or instance.complaint_type}' has been resolved.",
                created_at=timezone.now()
            )
        elif instance.status == 'rejected' and instance.rejection_remarks:
            Notification.objects.create(
                student=instance.student,
                message=f"❌ Your complaint '{instance.title or instance.complaint_type}' was rejected. Reason: {instance.rejection_remarks}",
                created_at=timezone.now()
            )