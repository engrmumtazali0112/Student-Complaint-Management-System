from django.contrib.auth import authenticate
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth.models import User
from django.conf import settings
from django.db.models import Q
from django.utils import timezone
from django.shortcuts import get_object_or_404

from .models import Student, Complaint, Notification, AdminProfile
from .serializers import (
    ComplaintDetailSerializer,
    SolvedComplaintSerializer,
    PendingComplaintSerializer,
)


# ─────────────────────────────────────────────
# Student endpoints
# ─────────────────────────────────────────────

@api_view(['POST'])
def student_login(request):
    student_id = request.data.get('student_id')
    password = request.data.get('password')

    user = authenticate(username=student_id, password=password)

    if user is not None:
        if not user.is_staff:
            return Response({
                'success': True,
                'message': 'Login successful',
                'user_id': user.pk,
                'student_id': user.username,
                'name': user.first_name,
            })
        return Response({'success': False, 'message': 'Not a student account'}, status=403)

    return Response({'success': False, 'message': 'Invalid Student ID or Password'}, status=401)


@api_view(['POST'])
def student_register(request):
    name = request.data.get('name')
    father_name = request.data.get('father_name')
    roll_number = request.data.get('roll_no')
    department = request.data.get('department')
    session = request.data.get('session')
    password = request.data.get('password')
    confirm_password = request.data.get('confirm_password')

    if password != confirm_password:
        return Response({'success': False, 'message': 'Passwords do not match'}, status=400)

    if User.objects.filter(username=roll_number).exists():
        return Response({'success': False, 'message': 'Student already registered'}, status=400)

    user = User.objects.create_user(
        username=roll_number,
        password=password,
        first_name=name,
    )

    Student.objects.create(
        user=user,
        student_id=roll_number,
        father_name=father_name,
        name=name,
        department=department,
        session=session,
    )

    return Response({'success': True, 'message': 'Registration successful'})


@api_view(['POST'])
def submit_complaint(request):
    try:
        # Handle file upload
        attachment = request.FILES.get('attachment')
        attachment_name = request.POST.get('attachment_name')
        attachment_type = request.POST.get('attachment_type')
        
        data = request.POST.dict() if request.POST else request.data
    except:
        return Response({
            "success": False,
            "message": "Invalid request data"
        }, status=400)

    student_id = data.get('roll_number')
    department = data.get('department')
    session = data.get('session')
    complaint_type = data.get('complaint_type')
    title = data.get('title')
    description = data.get('description')
    admin_type = data.get('admin_type', 'administration')

    if not all([student_id, department, session, complaint_type, description]):
        return Response({
            "success": False,
            "message": "All fields are required"
        }, status=400)

    student = Student.objects.filter(
        student_id__iexact=student_id
    ).first()

    if not student:
        return Response({
            "success": False,
            "message": "Student not found"
        }, status=404)

    complaint = Complaint.objects.create(
        student=student,
        roll_number=student_id,
        department=department,
        session=session,
        complaint_type=complaint_type,
        title=title,
        description=description,
        admin_type=admin_type,
        status='pending',
        attachment=attachment,
        attachment_name=attachment_name,
        attachment_type=attachment_type,
    )

    return Response({
        "success": True,
        "message": "Complaint submitted successfully",
        "complaint_id": complaint.pk
    }, status=201)


@api_view(['GET'])
def student_dashboard(request, student_id):
    student = Student.objects.filter(student_id__iexact=student_id).first()

    if not student:
        return Response({'success': False, 'message': 'Student not found'}, status=404)

    total_complaints = Complaint.objects.filter(student=student).count()
    pending_count = Complaint.objects.filter(student=student, status='pending').count()
    resolved_count = Complaint.objects.filter(student=student, status='resolved').count()

    notifications_qs = Notification.objects.filter(student=student).order_by('-created_at')[:10]
    notifications = [
        {'message': n.message, 'date': n.created_at.strftime('%Y-%m-%d %H:%M')}
        for n in notifications_qs
    ]

    return Response({
        'success': True,
        'student': {
            'name': student.name,
            'student_id': student.student_id,
            'department': student.department,
        },
        'notifications': notifications,
        'stats': {
            'total': total_complaints,
            'pending': pending_count,
            'resolved': resolved_count,
        },
    })


@api_view(['GET'])
def complaint_detail(request, student_id, complaint_id):
    student = get_object_or_404(Student, student_id=student_id)

    try:
        complaint = Complaint.objects.get(pk=complaint_id, student=student)
    except Complaint.DoesNotExist:
        return Response(
            {'success': False, 'message': 'Complaint not found'},
            status=status.HTTP_404_NOT_FOUND,
        )

    return Response({
        'success': True,
        'data': {
            'id': complaint.pk,
            'title': complaint.title or complaint.complaint_type,
            'complaint_type': complaint.complaint_type,
            'department': complaint.department,
            'description': complaint.description,
            'submitted_on': complaint.created_at.strftime('%b %d, %Y'),
            'status': complaint.status,
            'session': complaint.session,
            'roll_number': complaint.roll_number or complaint.student.student_id,
            'admin_type': complaint.admin_type,
            'resolved_at': complaint.resolved_at.strftime('%b %d, %Y') if complaint.resolved_at else None,
        },
    }, status=status.HTTP_200_OK)


@api_view(['GET'])
def track_complaints(request, student_id):
    student = get_object_or_404(Student, student_id=student_id)
    search_query = request.GET.get('search', '').strip()

    complaints = Complaint.objects.filter(student=student)
    if search_query:
        complaints = complaints.filter(
            Q(title__icontains=search_query) |
            Q(complaint_type__icontains=search_query) |
            Q(status__icontains=search_query) |
            Q(pk__icontains=search_query)
        )
    complaints = complaints.order_by('-created_at')

    data = [
        {
            'id': c.pk,
            'title': c.title or c.complaint_type,
            'complaint_type': c.complaint_type,
            'status': c.status,
            'created_at': c.created_at.strftime('%b %d, %Y'),
            'department': c.department,
            'session': c.session,
            'roll_number': c.roll_number,
            'description': c.description,
            'admin_type': c.admin_type,
        }
        for c in complaints
    ]

    return Response({'success': True, 'count': complaints.count(), 'data': data},
                    status=status.HTTP_200_OK)


# ─────────────────────────────────────────────
# Admin complaint endpoints
# ─────────────────────────────────────────────

@api_view(['GET'])
def complaint_list(request):
    search_query = request.GET.get('search', '').strip()
    complaints = Complaint.objects.select_related('student').all()

    if search_query:
        complaints = complaints.filter(
            Q(student__name__icontains=search_query) |
            Q(complaint_type__icontains=search_query) |
            Q(title__icontains=search_query)
        )
    complaints = complaints.order_by('-created_at')

    data = [
        {
            'id': c.pk,
            'complainant': c.student.name,
            'student_id': c.student.student_id,
            'title': c.title or c.complaint_type,
            'complaint_type': c.complaint_type,
            'status': c.status,
            'date': c.created_at.strftime('%b %d, %Y'),
            'admin_type': c.admin_type,
        }
        for c in complaints
    ]

    return Response({'success': True, 'count': complaints.count(), 'data': data},
                    status=status.HTTP_200_OK)


@api_view(['PATCH'])
def update_complaint_status(request, pk):
    try:
        complaint = Complaint.objects.get(pk=pk)
    except Complaint.DoesNotExist:
        return Response({'error': 'Complaint not found'}, status=404)

    new_status = request.data.get('status')
    if new_status not in ['pending', 'resolved', 'rejected']:
        return Response({'error': 'Invalid status'}, status=400)

    if new_status == 'resolved':
        complaint.resolved_at = timezone.now()
        complaint.rejection_remarks = None
        Notification.objects.create(
            student=complaint.student,
            message=f"✅ Your complaint '{complaint.title or complaint.complaint_type}' has been resolved.",
        )

    elif new_status == 'rejected':
        remarks = str(request.data.get('rejection_remarks', '')).strip()
        if not remarks:
            return Response(
                {'error': 'rejection_remarks is required when rejecting a complaint.'},
                status=400,
            )
        complaint.rejection_remarks = remarks
        complaint.resolved_at = None
        complaint.rejected_at = timezone.now()
        Notification.objects.create(
            student=complaint.student,
            message=f"❌ Your complaint '{complaint.title or complaint.complaint_type}' was rejected. Reason: {remarks}",
        )

    else:
        complaint.resolved_at = None
        complaint.rejection_remarks = None
        complaint.rejected_at = None

    complaint.status = new_status
    complaint.save()
    return Response({'message': 'Status updated successfully'})


@api_view(['POST'])
def reject_complaint(request, pk):
    try:
        complaint = Complaint.objects.select_related('student').get(pk=pk)
    except Complaint.DoesNotExist:
        return Response({'success': False, 'message': 'Complaint not found.'}, status=404)

    if complaint.status != 'pending':
        return Response(
            {'success': False,
             'message': f"Complaint is already '{complaint.status}'. Only pending complaints can be rejected."},
            status=400,
        )

    remarks = str(request.data.get('rejection_remarks', '')).strip()
    if not remarks:
        return Response({'success': False, 'message': 'rejection_remarks is required.'}, status=400)

    complaint.status = 'rejected'
    complaint.rejection_remarks = remarks
    complaint.rejected_at = timezone.now()
    complaint.resolved_at = None
    complaint.save()

    rejected_at_str = complaint.rejected_at.strftime('%b %d, %Y') if complaint.rejected_at else ''

    Notification.objects.create(
        student=complaint.student,
        message=f"❌ Your complaint '{complaint.title or complaint.complaint_type}' was rejected. Reason: {remarks}",
    )

    return Response({
        'success': True,
        'message': 'Complaint rejected successfully.',
        'complaint_id': complaint.pk,
        'rejection_remarks': remarks,
        'rejected_at': rejected_at_str,
    }, status=200)


@api_view(['GET'])
def rejected_complaints(request):
    query = request.GET.get('search', '').strip()
    complaints = Complaint.objects.filter(status='rejected').select_related('student')

    if query:
        complaints = complaints.filter(
            Q(complaint_type__icontains=query) |
            Q(title__icontains=query) |
            Q(student__name__icontains=query) |
            Q(department__icontains=query) |
            Q(rejection_remarks__icontains=query) |
            Q(pk__icontains=query)
        )
    complaints = complaints.order_by('-rejected_at')

    data = [
        {
            'id': c.pk,
            'complaint_type': c.complaint_type,
            'title': c.title or c.complaint_type,
            'department': c.department,
            'student_id': c.student.student_id,
            'student_name': c.student.name,
            'rejection_remarks': c.rejection_remarks or 'No reason provided.',
            'created_at': c.created_at.strftime('%b %d, %Y'),
            'rejected_at': c.rejected_at.strftime('%b %d, %Y') if c.rejected_at else None,
        }
        for c in complaints
    ]

    return Response({'data': data})


@api_view(['GET'])
def complaint_detail_by_id(request, complaint_id):
    try:
        complaint = Complaint.objects.select_related('student').get(pk=complaint_id)
    except Complaint.DoesNotExist:
        return Response({'success': False, 'message': 'Complaint not found'},
                        status=status.HTTP_404_NOT_FOUND)

    student = complaint.student

    return Response({
        'success': True,
        'data': {
            'id': complaint.pk,
            'title': complaint.title or complaint.complaint_type,
            'complaint_type': complaint.complaint_type,
            'department': complaint.department,
            'description': complaint.description,
            'submitted_on': complaint.created_at.strftime('%b %d, %Y'),
            'status': complaint.status,
            'session': complaint.session,
            'roll_number': complaint.roll_number or student.student_id,
            'student_name': student.name,
            'student_id': student.student_id,
            'admin_type': complaint.admin_type,
            'rejection_remarks': complaint.rejection_remarks or None,
            'rejected_at': complaint.rejected_at.strftime('%b %d, %Y') if complaint.rejected_at else None,
            'resolved_at': complaint.resolved_at.strftime('%b %d, %Y') if complaint.resolved_at else None,
        },
    }, status=status.HTTP_200_OK)


@api_view(['GET'])
def solved_complaints(request):
    query = request.GET.get('search', '')
    complaints = Complaint.objects.filter(status='resolved').select_related('student')

    if query:
        complaints = complaints.filter(
            Q(complaint_type__icontains=query) |
            Q(title__icontains=query) |
            Q(student__name__icontains=query) |
            Q(department__icontains=query) |
            Q(pk__icontains=query)
        )
    complaints = complaints.order_by('-resolved_at')

    data = [
        {
            'id': c.pk,
            'complaint_type': c.complaint_type,
            'title': c.title or c.complaint_type,
            'department': c.department,
            'resolved_at': c.resolved_at.strftime('%b %d, %Y') if c.resolved_at else 'N/A',
            'student_id': c.student.student_id,
            'student_name': c.student.name,
            'admin_type': c.admin_type,
        }
        for c in complaints
    ]

    return Response({'data': data})


@api_view(['GET'])
def pending_complaints(request):
    query = request.GET.get('search', '')
    complaints = Complaint.objects.filter(status='pending')

    if query:
        complaints = complaints.filter(
            Q(complaint_type__icontains=query) |
            Q(title__icontains=query) |
            Q(student__name__icontains=query) |
            Q(status__icontains=query) |
            Q(pk__icontains=query)
        )
    complaints = complaints.order_by('-created_at')

    serializer = PendingComplaintSerializer(complaints, many=True)
    return Response({'data': serializer.data})


@api_view(['GET'])
def new_complaint_count(request):
    count = Complaint.objects.filter(is_seen_by_admin=False, status='pending').count()
    return Response({'new_count': count})


# ─────────────────────────────────────────────
# Admin auth endpoints
# ─────────────────────────────────────────────


@api_view(['POST'])
def admin_login(request):
    username = request.data.get('username')
    password = request.data.get('password')

    if not username or not password:
        return Response({'success': False, 'message': 'Username and password are required.'}, status=400)

    user = authenticate(username=username, password=password)

    if user is not None:
        is_admin = user.is_staff or hasattr(user, 'admin_profile')
        
        if is_admin:
            role = None
            name = user.get_full_name() or user.username
            if hasattr(user, 'admin_profile') and user.admin_profile:
                role = getattr(user.admin_profile, 'role', None)
            
            return Response({
                'success': True,
                'message': 'Login successful',
                'admin_id': user.pk,
                'username': user.username,
                'name': name,
                'role': role,
            })
        return Response({'success': False, 'message': 'Access denied. Not an admin account.'}, status=403)

    return Response({'success': False, 'message': 'Invalid credentials.'}, status=401)


@api_view(['POST'])
def admin_register(request):
    ADMIN_SECRET_KEY = getattr(settings, 'ADMIN_SECRET_KEY', 'ADMIN_SECRET_2026')

    VALID_ROLES = [
        'warden', 'administration', 'examination',
        'treasury', 'security', 'transport',
        'library', 'hostel', 'sports', 'it',
    ]

    name = str(request.data.get('name', '')).strip()
    username = str(request.data.get('username', '')).strip()
    password = str(request.data.get('password', ''))
    confirm_password = str(request.data.get('confirm_password', ''))
    secret_key = str(request.data.get('admin_secret_key', '')).strip()
    role = str(request.data.get('role', 'administration')).strip().lower()
    phone = str(request.data.get('phone', '')).strip()
    department = str(request.data.get('department', '')).strip()

    if secret_key != ADMIN_SECRET_KEY:
        return Response({'success': False, 'message': 'Invalid admin secret key.'}, status=403)

    if not all([name, username, password, confirm_password]):
        return Response({'success': False, 'message': 'All fields are required.'}, status=400)

    if password != confirm_password:
        return Response({'success': False, 'message': 'Passwords do not match.'}, status=400)

    if len(password) < 8:
        return Response({'success': False, 'message': 'Password must be at least 8 characters.'}, status=400)

    if User.objects.filter(username=username).exists():
        return Response({'success': False, 'message': 'Username already taken.'}, status=400)

    if role not in VALID_ROLES:
        return Response({
            'success': False,
            'message': f'Invalid role "{role}". Valid: {", ".join(VALID_ROLES)}.',
        }, status=400)

    parts = name.split(' ', 1)
    first_name = parts[0]
    last_name = parts[1] if len(parts) > 1 else ''

    user = User.objects.create_user(
        username=username,
        password=password,
        first_name=first_name,
        last_name=last_name,
        is_staff=True,
        is_superuser=False,
    )

    AdminProfile.objects.create(
        user=user,
        role=role,
        phone=phone or None,
        department=department or None,
    )

    return Response({
        'success': True,
        'message': 'Admin registered successfully.',
        'admin_id': user.pk,
        'username': user.username,
        'role': role,
    }, status=201)


@api_view(['GET'])
def get_complaints_by_admin_type(request, admin_type):
    search_query = request.GET.get('search', '').strip()
    complaints = Complaint.objects.filter(admin_type=admin_type).select_related('student')

    if search_query:
        complaints = complaints.filter(
            Q(student__name__icontains=search_query) |
            Q(complaint_type__icontains=search_query) |
            Q(title__icontains=search_query)
        )
    complaints = complaints.order_by('-created_at')

    data = [
        {
            'id': c.pk,
            'complainant': c.student.name,
            'student_id': c.student.student_id,
            'title': c.title or c.complaint_type,
            'complaint_type': c.complaint_type,
            'status': c.status,
            'date': c.created_at.strftime('%b %d, %Y'),
            'admin_type': c.admin_type,
        }
        for c in complaints
    ]

    return Response({'success': True, 'count': complaints.count(), 'data': data},
                    status=status.HTTP_200_OK)


@api_view(['POST'])
def mark_complaints_seen(request):
    Complaint.objects.filter(is_seen_by_admin=False, status='pending').update(is_seen_by_admin=True)
    return Response({'message': 'Marked as seen'})


# ─────────────────────────────────────────────
# Student profile endpoints
# ─────────────────────────────────────────────

@api_view(['GET'])
def get_student_profile(request, student_id):
    """Get student profile information."""
    try:
        student = Student.objects.select_related('user').get(student_id=student_id)
        
        # Get complaint counts
        total_complaints = Complaint.objects.filter(student=student).count()
        pending_complaints = Complaint.objects.filter(student=student, status='pending').count()
        resolved_complaints = Complaint.objects.filter(student=student, status='resolved').count()
        rejected_complaints = Complaint.objects.filter(student=student, status='rejected').count()
        
        return Response({
            'success': True,
            'data': {
                'student_id': student.student_id,
                'name': student.name,
                'father_name': student.father_name,
                'department': student.department,
                'session': student.session,
                'email': student.user.email if student.user else '',
                'phone': student.phone or '',
                'address': student.address or '',
                'profile_picture': request.build_absolute_uri(student.profile_picture.url) if student.profile_picture else None,
                'total_complaints': total_complaints,
                'pending_complaints': pending_complaints,
                'resolved_complaints': resolved_complaints,
                'rejected_complaints': rejected_complaints,
                'created_at': student.created_at.strftime('%Y-%m-%d'),
            }
        }, status=status.HTTP_200_OK)
    except Student.DoesNotExist:
        return Response({'success': False, 'message': 'Student not found'}, status=404)


@api_view(['POST'])
def upload_student_profile_pic(request):
    """Upload student profile picture."""
    student_id = request.data.get('student_id')
    profile_pic = request.FILES.get('profile_picture')
    
    if not student_id or not profile_pic:
        return Response({'success': False, 'message': 'Student ID and profile picture are required'}, status=400)
    
    try:
        student = Student.objects.get(student_id=student_id)
        student.profile_picture = profile_pic
        student.save()
        return Response({
            'success': True,
            'message': 'Profile picture uploaded successfully',
            'profile_picture_url': request.build_absolute_uri(student.profile_picture.url)
        }, status=status.HTTP_200_OK)
    except Student.DoesNotExist:
        return Response({'success': False, 'message': 'Student not found'}, status=404)


# ─────────────────────────────────────────────
# Admin profile endpoints
# ─────────────────────────────────────────────

@api_view(['GET'])
def get_admin_profile(request, username):
    """Get admin profile information."""
    try:
        user = User.objects.get(username=username)
        admin_profile = AdminProfile.objects.get(user=user)
        
        return Response({
            'success': True,
            'data': {
                'name': user.get_full_name() or user.username,
                'username': user.username,
                'email': user.email,
                'role': admin_profile.role,
                'phone': admin_profile.phone or '',
                'department': admin_profile.department or '',
                'address': admin_profile.address or '',
                'profile_picture': request.build_absolute_uri(admin_profile.profile_picture.url) if admin_profile.profile_picture else None,
                'created_at': admin_profile.created_at.strftime('%Y-%m-%d'),
            }
        }, status=status.HTTP_200_OK)
    except User.DoesNotExist:
        return Response({'success': False, 'message': 'Admin not found'}, status=404)
    except AdminProfile.DoesNotExist:
        return Response({'success': False, 'message': 'Admin profile not found'}, status=404)


@api_view(['POST'])
def upload_admin_profile_pic(request):
    """Upload admin profile picture."""
    username = request.data.get('username')
    profile_pic = request.FILES.get('profile_picture')
    
    if not username or not profile_pic:
        return Response({'success': False, 'message': 'Username and profile picture are required'}, status=400)
    
    try:
        user = User.objects.get(username=username)
        admin_profile = AdminProfile.objects.get(user=user)
        admin_profile.profile_picture = profile_pic
        admin_profile.save()
        return Response({
            'success': True,
            'message': 'Profile picture uploaded successfully',
            'profile_picture_url': request.build_absolute_uri(admin_profile.profile_picture.url) if admin_profile.profile_picture else None
        }, status=status.HTTP_200_OK)
    except User.DoesNotExist:
        return Response({'success': False, 'message': 'User not found'}, status=404)
    except AdminProfile.DoesNotExist:
        return Response({'success': False, 'message': 'Admin profile not found'}, status=404)
    

# ─────────────────────────────────────────────
# Admin notification endpoints
# ─────────────────────────────────────────────

@api_view(['GET'])
def get_admin_notifications(request):
    """Get all notifications for admin's department."""
    admin_type = request.GET.get('admin_type', '')
    
    # Get complaints with status changes for this admin's department
    notifications_data = []
    
    # Get recently resolved complaints
    resolved_complaints = Complaint.objects.filter(
        admin_type=admin_type,
        status='resolved',
        resolved_at__isnull=False
    ).order_by('-resolved_at')[:20]
    
    for complaint in resolved_complaints:
        notifications_data.append({
            'id': complaint.pk,
            'message': f"Complaint #{complaint.pk} from {complaint.student.name} has been resolved.",
            'student_name': complaint.student.name,
            'created_at': complaint.resolved_at.strftime('%Y-%m-%d %H:%M'),
            'is_read': False,
        })
    
    # Get recently rejected complaints
    rejected_complaints = Complaint.objects.filter(
        admin_type=admin_type,
        status='rejected',
        rejected_at__isnull=False
    ).order_by('-rejected_at')[:20]
    
    for complaint in rejected_complaints:
        notifications_data.append({
            'id': complaint.pk,
            'message': f"Complaint #{complaint.pk} from {complaint.student.name} was rejected.",
            'student_name': complaint.student.name,
            'created_at': complaint.rejected_at.strftime('%Y-%m-%d %H:%M'),
            'is_read': False,
        })
    
    # Sort by date (newest first)
    notifications_data.sort(key=lambda x: x['created_at'], reverse=True)
    
    return Response({
        'success': True,
        'notifications': notifications_data[:50],
        'count': len(notifications_data)
    })


@api_view(['GET'])
def get_notification_count(request):
    """Get count of unread notifications."""
    admin_type = request.GET.get('admin_type', '')
    
    # Count recent activities (last 7 days)
    week_ago = timezone.now() - timezone.timedelta(days=7)
    
    count = Complaint.objects.filter(
        admin_type=admin_type,
        resolved_at__gte=week_ago
    ).count() + Complaint.objects.filter(
        admin_type=admin_type,
        rejected_at__gte=week_ago
    ).count()
    
    return Response({'count': min(count, 99)})


@api_view(['POST'])
def mark_notification_read(request, notification_id):
    """Mark a notification as read."""
    # For simplicity, we'll just return success
    # In a real app, you'd have a Notification model
    return Response({'success': True})