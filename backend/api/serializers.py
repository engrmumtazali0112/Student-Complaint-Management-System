from rest_framework import serializers
from .models import Complaint

class ComplaintDetailSerializer(serializers.ModelSerializer):
    submitted_on = serializers.DateTimeField(source='created_at', format="%b %d, %Y")

    class Meta:
        model = Complaint
        fields = [
            'department',
            'description',
            'submitted_on',
        ]

    # for sloved complians 
class SolvedComplaintSerializer(serializers.ModelSerializer):
    resolved_at = serializers.DateTimeField(format="%b %d, %Y")

    class Meta:
        model = Complaint
        fields = [
            'id',
            'complaint_type',
            'department',
            'resolved_at',
        ]

  # for pending complains
class PendingComplaintSerializer(serializers.ModelSerializer):
    student_name = serializers.CharField(source='student.name', read_only=True)

    class Meta:
        model = Complaint
        fields = [
            'id',
            'student_name',
            'complaint_type',
            'status',
        ]
