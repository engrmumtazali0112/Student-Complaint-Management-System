from rest_framework import serializers
from .models import Complaint, AdminProfile


class ComplaintDetailSerializer(serializers.ModelSerializer):
    submitted_on   = serializers.DateTimeField(source='created_at', format="%b %d, %Y")
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model  = Complaint
        fields = [
            'id',
            'title',
            'complaint_type',
            'department',
            'description',
            'submitted_on',
            'status',
            'status_display',
            'attachment',  
            'attachment_name', 
            'session',
            'roll_number',
            'resolved_at',
            'admin_type',
        ]


class SolvedComplaintSerializer(serializers.ModelSerializer):
    resolved_at = serializers.DateTimeField(format="%b %d, %Y")

    class Meta:
        model  = Complaint
        fields = [
            'id',
            'complaint_type',
            'department',
            'resolved_at',
            'admin_type',
        ]


class PendingComplaintSerializer(serializers.ModelSerializer):
    student_name = serializers.CharField(source='student.name', read_only=True)

    class Meta:
        model  = Complaint
        fields = [
            'id',
            'student_name',
            'complaint_type',
            'status',
            'admin_type',
        ]


class AdminProfileSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    email    = serializers.CharField(source='user.email',    read_only=True)

    class Meta:
        model  = AdminProfile
        fields = ['id', 'username', 'email', 'role', 'phone', 'department']