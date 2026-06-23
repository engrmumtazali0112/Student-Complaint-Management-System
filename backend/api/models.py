from django.db import models
from django.contrib.auth.models import User
from django.core.validators import RegexValidator
from django.utils import timezone
from datetime import timedelta


# ─────────────────────────────────────────────
# Admin Role Choices – all 10 departments
# ─────────────────────────────────────────────

class AdminRole(models.TextChoices):
    WARDEN = 'warden', 'Warden'
    ADMINISTRATION = 'administration', 'Administration'
    EXAMINATION = 'examination', 'Examination'
    TREASURY = 'treasury', 'Treasury'
    SECURITY = 'security', 'Security'
    TRANSPORT = 'transport', 'Transport'
    LIBRARY = 'library', 'Library'
    HOSTEL = 'hostel', 'Hostel'
    SPORTS = 'sports', 'Sports'
    IT = 'it', 'IT'


class AdminProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='admin_profile')
    role = models.CharField(max_length=20, choices=AdminRole.choices)
    phone = models.CharField(max_length=15, blank=True, null=True)
    department = models.CharField(max_length=100, blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    profile_picture = models.ImageField(upload_to='profile_pics/', blank=True, null=True)
    email = models.EmailField(blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    date_of_birth = models.DateField(blank=True, null=True)

    def __str__(self):
        return f"{self.user.username} – {self.get_role_display()}"
    
    def get_role_display(self):
        """Return the display value for the role field."""
        for role_value, role_label in AdminRole.choices:
            if role_value == self.role:
                return role_label
        return self.role
    
    def get_role_display_name(self):
        """Return display name for the role (for API responses)"""
        role_names = {
            'administration': 'Administration',
            'warden': 'Warden',
            'examination': 'Examination',
            'treasury': 'Treasury',
            'security': 'Security',
            'transport': 'Transport',
            'library': 'Library',
            'hostel': 'Hostel',
            'sports': 'Sports',
            'it': 'IT Department',
        }
        return role_names.get(self.role, self.role.capitalize())


# ─────────────────────────────────────────────
# Student model
# ─────────────────────────────────────────────

class Student(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='student')
    reg_no_validator = RegexValidator(
        regex=r'^[A-Z]{2}-\d{2}[A-Z]/\d{2}-\d{2}$',
        message="Format must be like CS-06F/22-26"
    )
    student_id = models.CharField(max_length=20, unique=True, validators=[reg_no_validator])
    father_name = models.CharField(max_length=100, blank=False, null=False)
    name = models.CharField(max_length=100)
    department = models.CharField(max_length=100)
    session = models.CharField(max_length=50, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    profile_picture = models.ImageField(upload_to='profile_pics/', blank=True, null=True)
    phone = models.CharField(max_length=15, blank=True, null=True)
    email = models.EmailField(blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    date_of_birth = models.DateField(blank=True, null=True)

    def save(self, *args, **kwargs):
        self.student_id = self.student_id.upper()
        super().save(*args, **kwargs)

    def __str__(self):
        return self.student_id


# ─────────────────────────────────────────────
# Notification model
# ─────────────────────────────────────────────

class Notification(models.Model):
    student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name='notifications')
    message = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)
    is_read = models.BooleanField(default=False)

    def __str__(self):
        return self.message


# ─────────────────────────────────────────────
# Complaint model
# ─────────────────────────────────────────────

class Complaint(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('resolved', 'Resolved'),
        ('rejected', 'Rejected'),
    ]

    ADMIN_TYPE_CHOICES = [
        ('warden', 'Warden'),
        ('administration', 'Administration'),
        ('examination', 'Examination'),
        ('treasury', 'Treasury'),
        ('security', 'Security'),
        ('transport', 'Transport'),
        ('library', 'Library'),
        ('hostel', 'Hostel'),
        ('sports', 'Sports'),
        ('it', 'IT Department'),
    ]

    # Basic info
    student = models.ForeignKey(Student, on_delete=models.CASCADE, related_name='complaints')
    roll_number = models.CharField(max_length=20)
    department = models.CharField(max_length=50)
    session = models.CharField(max_length=50)
    complaint_type = models.CharField(max_length=100)
    title = models.CharField(max_length=200, blank=True, null=True)
    description = models.TextField()

    # Which admin department handles this complaint
    admin_type = models.CharField(max_length=20, choices=ADMIN_TYPE_CHOICES, default='administration')

    # Status tracking
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    is_seen_by_admin = models.BooleanField(default=False)
    rejection_remarks = models.TextField(blank=True, null=True)
    rejected_at = models.DateTimeField(null=True, blank=True)

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    resolved_at = models.DateTimeField(null=True, blank=True)

    # File upload
    attachment = models.FileField(upload_to='complaints/', blank=True, null=True)
    attachment_name = models.CharField(max_length=255, blank=True, null=True)
    attachment_type = models.CharField(max_length=50, blank=True, null=True)

    # ✅ Anonymous Complaint Fields
    is_anonymous = models.BooleanField(default=False)
    anonymous_display_id = models.CharField(max_length=20, blank=True, null=True)
    
    def get_display_name(self):
        """Return display name - hides real identity if anonymous"""
        if self.is_anonymous:
            return f"Anonymous #{self.anonymous_display_id or self.pk}"
        return self.student.name
    
    def get_display_student_id(self):
        """Return display student ID - hides real ID if anonymous"""
        if self.is_anonymous:
            return f"ANON-{self.anonymous_display_id or self.pk}"
        return self.student.student_id

    def __str__(self):
        return f"{self.student.student_id} – {self.complaint_type} [{self.admin_type}]"
    
    # ── Escalation threshold ──────────────────────────────────
    # PRODUCTION value: timedelta(days=1)
    # While you're testing the escalation pipeline end-to-end, set this
    # to something short (e.g. timedelta(minutes=10)) so you don't have
    # to wait a full day to confirm it works. Revert to days=1 when done.
    ESCALATION_THRESHOLD = timedelta(minutes=10)  # TEST MODE — change back to timedelta(days=1) after testing
    ESCALATION_LABEL = '10 minutes (TEST MODE)'   # shown in the EscalationLog reason text

    def is_escalation_needed(self):
        """Check if complaint has been pending longer than ESCALATION_THRESHOLD."""
        if self.status == 'pending' and self.created_at:
            delta = timezone.now() - self.created_at
            return delta >= self.ESCALATION_THRESHOLD
        return False


# ─────────────────────────────────────────────
# Super Admin model
# ─────────────────────────────────────────────

class SuperAdmin(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='super_admin')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Super Admin: {self.user.username}"


# ─────────────────────────────────────────────
# Escalation Log model
# ─────────────────────────────────────────────

class EscalationLog(models.Model):
    complaint = models.ForeignKey(Complaint, on_delete=models.CASCADE, related_name='escalations')
    escalated_at = models.DateTimeField(auto_now_add=True)
    reason = models.CharField(max_length=255, default="Pending for more than 1 day")
    is_resolved_by_super_admin = models.BooleanField(default=False)

    def __str__(self):
        return f"Complaint #{self.complaint.pk} escalated on {self.escalated_at}"


# ─────────────────────────────────────────────
# Admin Rating model
# ─────────────────────────────────────────────

class AdminRating(models.Model):
    complaint = models.OneToOneField(Complaint, on_delete=models.CASCADE, related_name='rating')
    admin = models.ForeignKey(AdminProfile, on_delete=models.CASCADE, related_name='ratings')
    student = models.ForeignKey(Student, on_delete=models.CASCADE)
    rating = models.IntegerField(choices=[(1, '1 Star'), (2, '2 Stars'), (3, '3 Stars'), (4, '4 Stars'), (5, '5 Stars')])
    comment = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Rating {self.rating} for {self.admin.user.username} (Complaint #{self.complaint.pk})"