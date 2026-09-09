from rest_framework import serializers
from .models import Complaint, AdminProfile


class ComplaintDetailSerializer(serializers.ModelSerializer):
    submitted_on = serializers.SerializerMethodField()
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    # Anonymous fields
    display_name = serializers.SerializerMethodField()
    display_student_id = serializers.SerializerMethodField()

    class Meta:
        model = Complaint
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
            'is_anonymous',
            'anonymous_display_id',
            'display_name',
            'display_student_id',
        ]

    def get_display_name(self, obj):
        return obj.get_display_name()

    def get_display_student_id(self, obj):
        return obj.get_display_student_id()

    def get_submitted_on(self, obj):
        return obj.created_at.strftime("%b %d, %Y") if obj.created_at else None


class SolvedComplaintSerializer(serializers.ModelSerializer):
    resolved_at = serializers.SerializerMethodField()
    display_name = serializers.SerializerMethodField()
    display_student_id = serializers.SerializerMethodField()

    class Meta:
        model = Complaint
        fields = [
            'id',
            'complaint_type',
            'department',
            'resolved_at',
            'admin_type',
            'is_anonymous',
            'display_name',
            'display_student_id',
        ]

    def get_display_name(self, obj):
        return obj.get_display_name()

    def get_display_student_id(self, obj):
        return obj.get_display_student_id()

    def get_resolved_at(self, obj):
        return obj.resolved_at.strftime("%b %d, %Y") if obj.resolved_at else None


class PendingComplaintSerializer(serializers.ModelSerializer):
    student_name = serializers.SerializerMethodField()
    student_id_display = serializers.SerializerMethodField()

    class Meta:
        model = Complaint
        fields = [
            'id',
            'student_name',
            'student_id_display',
            'complaint_type',
            'status',
            'admin_type',
            'is_anonymous',
        ]

    def get_student_name(self, obj):
        return obj.get_display_name()

    def get_student_id_display(self, obj):
        return obj.get_display_student_id()


class AdminProfileSerializer(serializers.ModelSerializer):
    username = serializers.CharField(source='user.username', read_only=True)
    email = serializers.CharField(source='user.email', read_only=True)

    class Meta:
        model = AdminProfile
        fields = ['id', 'username', 'email', 'role', 'phone', 'department']


class AdminComplaintListSerializer(serializers.ModelSerializer):
    complainant = serializers.SerializerMethodField()
    student_id_display = serializers.SerializerMethodField()
    # FIX: model has no `date` field — it's `created_at`. Aliased here so the
    # API output key stays `date` without breaking serializer validation.
    date = serializers.SerializerMethodField()

    class Meta:
        model = Complaint
        fields = [
            'id',
            'complainant',
            'student_id_display',
            'title',
            'complaint_type',
            'status',
            'date',
            'admin_type',
            'attachment',
            'attachment_name',
            'is_anonymous',
        ]

    def get_complainant(self, obj):
        return obj.get_display_name()

    def get_student_id_display(self, obj):
        return obj.get_display_student_id()

    def get_date(self, obj):
        return obj.created_at.strftime("%b %d, %Y") if obj.created_at else None