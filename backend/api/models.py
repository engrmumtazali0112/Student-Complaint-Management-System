from django.db import models
from django.contrib.auth.models import User

from django.core.validators import RegexValidator
 
    # student model...

class Student(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE , related_name='student')
    reg_no_validator = RegexValidator(
        regex=r'^[A-Z]{2}-\d{2}[A-Z]/\d{2}-\d{2}$',
        message="Format must be like CS-06F/22-26"
    )
    student_id = models.CharField(
        max_length=20,
        unique=True,
        validators=[reg_no_validator]
    )
    #student_id = models.CharField(max_length=20, unique=True)
    father_name= models.CharField(max_length=100)
    name = models.CharField(max_length=100)
    department = models.CharField(max_length=100)
    session = models.CharField(max_length=50 ,null=True , blank=True)   # i added this line now 
    created_at = models.DateTimeField(auto_now_add=True) # i added this now 

    def save(self, *args, **kwargs):
        self.student_id = self.student_id.upper()  # normalize input
        super().save(*args, **kwargs)

    def __str__(self):
        return self.student_id



class Notification(models.Model):
    student = models.ForeignKey(Student, on_delete=models.CASCADE)
    message = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.message
    

# view complain part 
class Complaint(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('resolved', 'Resolved'),
        ('rejected', 'Rejected'),
    ]
    is_seen_by_admin = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name='complaints')
    roll_number = models.CharField(max_length=20)
    department = models.CharField(max_length=50)
    session = models.CharField(max_length=50)
    complaint_type = models.CharField(max_length=100)
    description = models.TextField()
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return f"{self.student.student_id} - {self.complaint_type}"