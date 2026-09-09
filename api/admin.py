from django.contrib import admin
from .models import Student, Complaint, Notification

# Register your models here.
@admin.register(Student)
class StudentAdmin(admin.ModelAdmin):
    list_display = ('student_id', 'name', 'department', 'user')
    search_fields = ('student_id', 'name', 'department')


@admin.register(Complaint)
class ComplaintAdmin(admin.ModelAdmin):
    list_display = ('get_student_id', 'student', 'complaint_type', 'status', 'created_at')
    list_filter = ('status', 'department', 'complaint_type')
    search_fields = ('get_student_id', 'complaint_type', 'description')
    
    def get_student_id(self, obj):
        return obj.student.student_id

    get_student_id.short_description = 'Student ID'


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ('student', 'message', 'created_at')
    search_fields = ('student__student_id', 'message')
