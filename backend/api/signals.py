from django.db.models.signals import post_save
from django.dispatch import receiver
from django.contrib.auth.models import User
from .models import Student

@receiver(post_save, sender=User)
def create_student(sender, instance, created, **kwargs):
    if created:
        # Automatically create a Student for the new User
        student_data = getattr(instance, 'student_data', None)
        if student_data:
            Student.objects.create(
                user=instance,
                student_id=student_data.get('student_id'),
                name=student_data.get('name'),
                father_name= student_data.get('father_name'),
                department=student_data.get('department'),
                session=student_data.get('session')
        )

@receiver(post_save, sender=User)
def save_student(sender, instance, **kwargs):
    if hasattr(instance, 'student'):
        instance.student.save()
