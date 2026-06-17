from django.contrib.auth import authenticate
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth.models import User
from django.conf import settings
from django.db.models import Q, Count, Avg
from django.db.models.functions import TruncDate
from django.utils import timezone
from django.shortcuts import get_object_or_404
from datetime import timedelta

from .models import Student, Complaint, Notification, AdminProfile, EscalationLog, AdminRating, SuperAdmin
from .serializers import (
    ComplaintDetailSerializer,
    SolvedComplaintSerializer,
    PendingComplaintSerializer,
    AdminComplaintListSerializer,
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
    email = request.data.get('email', '')
    phone = request.data.get('phone', '')
    address = request.data.get('address', '')
    date_of_birth = request.data.get('date_of_birth', None)

    if not all([name, father_name, roll_number, department, password, confirm_password]):
        return Response({
            'success': False, 
            'message': 'All required fields (Name, Father Name, Roll Number, Department, Password) must be filled'
        }, status=400)

    if password != confirm_password:
        return Response({'success': False, 'message': 'Passwords do not match'}, status=400)

    if User.objects.filter(username=roll_number).exists():
        return Response({'success': False, 'message': 'Student already registered'}, status=400)

    user = User.objects.create_user(
        username=roll_number,
        password=password,
        first_name=name,
        email=email,
    )

    student = Student.objects.create(
        user=user,
        student_id=roll_number,
        father_name=father_name,
        name=name,
        department=department,
        session=session if session else "2024-2028",
        email=email,
        phone=phone,
        address=address,
        date_of_birth=date_of_birth if date_of_birth else None,
    )

    return Response({'success': True, 'message': 'Registration successful'})

# views.py - Update submit_complaint

@api_view(['POST'])
def submit_complaint(request):
    try:
        # Handle file upload properly
        attachment = request.FILES.get('attachment')
        attachment_name = request.POST.get('attachment_name')
        attachment_type = request.POST.get('attachment_type')
        
        # Get data from POST or request.data
        if request.POST:
            data = request.POST.dict()
        else:
            data = request.data
    except Exception as e:
        return Response({
            "success": False,
            "message": f"Invalid request data: {str(e)}"
        }, status=400)

    student_id = data.get('roll_number')
    department = data.get('department')
    session = data.get('session')
    complaint_type = data.get('complaint_type')
    title = data.get('title')
    description = data.get('description')
    admin_type = data.get('admin_type', 'administration')
    
    # ✅ Check if student wants to hide identity
    is_anonymous = data.get('is_anonymous', 'false')
    if isinstance(is_anonymous, str):
        is_anonymous = is_anonymous.lower() in ['true', '1', 'yes']
    else:
        is_anonymous = bool(is_anonymous)

    # Validate required fields
    if not all([student_id, department, session, complaint_type, description]):
        return Response({
            "success": False,
            "message": "All fields are required"
        }, status=400)

    # Find student
    student = Student.objects.filter(student_id__iexact=student_id).first()

    if not student:
        return Response({
            "success": False,
            "message": "Student not found"
        }, status=404)

    # Create complaint
    complaint = Complaint.objects.create(
        student=student,
        roll_number=student_id,
        department=department,
        session=session,
        complaint_type=complaint_type,
        title=title or complaint_type,
        description=description,
        admin_type=admin_type,
        status='pending',
        attachment=attachment,
        attachment_name=attachment_name,
        attachment_type=attachment_type,
        is_anonymous=is_anonymous,
        anonymous_display_id=f"ANON-{Complaint.objects.count() + 1:04d}",  # Generate unique anonymous ID
    )

    return Response({
        "success": True,
        "message": "Complaint submitted successfully" + (" (Anonymous)" if is_anonymous else ""),
        "complaint_id": complaint.pk,
        "is_anonymous": is_anonymous,
    }, status=201)

@api_view(['GET'])
def student_dashboard(request, student_id):
    student = Student.objects.filter(student_id__iexact=student_id).first()

    if not student:
        return Response({'success': False, 'message': 'Student not found'}, status=404)

    total_complaints = Complaint.objects.filter(student=student).count()
    pending_count = Complaint.objects.filter(student=student, status='pending').count()
    resolved_count = Complaint.objects.filter(student=student, status='resolved').count()
    rejected_count = Complaint.objects.filter(student=student, status='rejected').count()

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
            'rejected': rejected_count,
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
            'attachment': complaint.attachment.url if complaint.attachment else None,
            'attachment_name': complaint.attachment_name,
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
            'attachment': c.attachment.url if c.attachment else None,
            'attachment_name': c.attachment_name,
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

    # Use the AdminComplaintListSerializer
    serializer = AdminComplaintListSerializer(complaints, many=True)
    
    return Response({
        'success': True, 
        'count': complaints.count(), 
        'data': serializer.data
    }, status=status.HTTP_200_OK)

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

    Notification.objects.create(
        student=complaint.student,
        message=f"❌ Your complaint '{complaint.title or complaint.complaint_type}' was rejected. Reason: {remarks}",
    )

    return Response({
        'success': True,
        'message': 'Complaint rejected successfully.',
        'complaint_id': complaint.pk,
        'rejection_remarks': remarks,
        'rejected_at': complaint.rejected_at.strftime('%b %d, %Y') if complaint.rejected_at else '',
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
            'attachment': c.attachment.url if c.attachment else None,
            'attachment_name': c.attachment_name,
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

    # Use the ComplaintDetailSerializer
    serializer = ComplaintDetailSerializer(complaint)
    
    return Response({
        'success': True,
        'data': serializer.data
    }, status=status.HTTP_200_OK)

@api_view(['GET'])
def student_resolved_complaints(request, student_id):
    """Get only resolved complaints for a student"""
    try:
        student = Student.objects.filter(student_id__iexact=student_id).first()
        
        if not student:
            return Response({'success': False, 'message': 'Student not found'}, status=404)
        
        resolved_complaints = Complaint.objects.filter(
            student=student, 
            status='resolved'
        ).order_by('-resolved_at')
        
        data = []
        for complaint in resolved_complaints:
            data.append({
                'id': complaint.pk,
                'title': complaint.title or complaint.complaint_type,
                'complaint_type': complaint.complaint_type,
                'status': complaint.status,
                'created_at': complaint.created_at.strftime('%b %d, %Y'),
                'resolved_at': complaint.resolved_at.strftime('%b %d, %Y') if complaint.resolved_at else None,
                'department': complaint.department,
                'description': complaint.description,
                'admin_type': complaint.admin_type,
                'session': complaint.session,
                'roll_number': complaint.roll_number or student.student_id,
            })
        
        return Response({
            'success': True, 
            'count': resolved_complaints.count(), 
            'data': data
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        print(f"Error in student_resolved_complaints: {str(e)}")
        return Response({
            'success': False, 
            'message': f'Error: {str(e)}'
        }, status=500)





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
            'student_id': c.get_display_student_id(),
            'student_name': c.get_display_name(),
            'is_anonymous': c.is_anonymous,
            'rejection_remarks': c.rejection_remarks or 'No reason provided.',
            'created_at': c.created_at.strftime('%b %d, %Y'),
            'rejected_at': c.rejected_at.strftime('%b %d, %Y') if c.rejected_at else None,
            'attachment': c.attachment.url if c.attachment else None,
            'attachment_name': c.attachment_name,
        }
        for c in complaints
    ]

    return Response({'data': data})


@api_view(['GET'])
def solved_complaints(request):
    """Get only resolved complaints for admin panel"""
    admin_type = request.GET.get('admin_type', '')
    search_query = request.GET.get('search', '')

    if admin_type:
        complaints = Complaint.objects.filter(
            status='resolved',
            admin_type=admin_type
        ).select_related('student')
    else:
        complaints = Complaint.objects.filter(status='resolved').select_related('student')

    if search_query:
        complaints = complaints.filter(
            Q(complaint_type__icontains=search_query) |
            Q(title__icontains=search_query) |
            Q(student__name__icontains=search_query) |
            Q(department__icontains=search_query) |
            Q(pk__icontains=search_query)
        )

    complaints = complaints.order_by('-resolved_at')

    data = []
    for c in complaints:
        data.append({
            'id': c.pk,
            'complaint_type': c.complaint_type,
            'title': c.title or c.complaint_type,
            'department': c.department,
            'resolved_at': c.resolved_at.strftime('%b %d, %Y') if c.resolved_at else 'N/A',
            'student_id': c.get_display_student_id(),
            'student_name': c.get_display_name(),
            'is_anonymous': c.is_anonymous,
            'admin_type': c.admin_type,
            'description': c.description,
            'attachment': c.attachment.url if c.attachment else None,
            'attachment_name': c.attachment_name,
        })

    return Response({
        'success': True,
        'data': data,
        'count': len(data)
    })


@api_view(['GET'])
def pending_complaints(request):
    """Get only pending complaints for admin panel"""
    admin_type = request.GET.get('admin_type', '')
    search_query = request.GET.get('search', '')

    if admin_type:
        complaints = Complaint.objects.filter(
            status='pending',
            admin_type=admin_type
        ).select_related('student')
    else:
        complaints = Complaint.objects.filter(status='pending').select_related('student')

    if search_query:
        complaints = complaints.filter(
            Q(complaint_type__icontains=search_query) |
            Q(title__icontains=search_query) |
            Q(student__name__icontains=search_query) |
            Q(status__icontains=search_query) |
            Q(pk__icontains=search_query)
        )

    complaints = complaints.order_by('-created_at')

    data = []
    for c in complaints:
        data.append({
            'id': c.pk,
            'student_name': c.get_display_name(),
            'student_id': c.get_display_student_id(),
            'is_anonymous': c.is_anonymous,
            'complaint_type': c.complaint_type,
            'title': c.title or c.complaint_type,
            'status': c.status,
            'admin_type': c.admin_type,
            'created_at': c.created_at.strftime('%b %d, %Y'),
            'description': c.description,
            'attachment': c.attachment.url if c.attachment else None,
            'attachment_name': c.attachment_name,
        })

    return Response({
        'success': True,
        'data': data,
        'count': len(data)
    })




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
    email = str(request.data.get('email', '')).strip()
    address = str(request.data.get('address', '')).strip()

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
        email=email,
        is_staff=True,
        is_superuser=False,
    )

    AdminProfile.objects.create(
        user=user,
        role=role,
        phone=phone or None,
        department=department or None,
        email=email or None,
        address=address or None,
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

    # Use the AdminComplaintListSerializer
    serializer = AdminComplaintListSerializer(complaints, many=True)
    
    return Response({
        'success': True, 
        'count': complaints.count(), 
        'data': serializer.data
    }, status=status.HTTP_200_OK)

@api_view(['POST'])
def mark_complaints_seen(request):
    complaint_id = request.data.get('complaint_id') or request.POST.get('complaint_id')
    admin_type = request.data.get('admin_type') or request.POST.get('admin_type')

    qs = Complaint.objects.filter(is_seen_by_admin=False)

    if complaint_id:
        # Mark only the specific complaint as seen
        qs = qs.filter(pk=complaint_id)
    elif admin_type:
        # Mark all unseen complaints for this admin's department (when admin opens notifications)
        qs = qs.filter(admin_type=admin_type)
    else:
        return Response({'message': 'No complaint_id or admin_type provided'}, status=400)

    updated = qs.update(is_seen_by_admin=True)
    return Response({'message': f'Marked {updated} complaint(s) as seen'})


# ─────────────────────────────────────────────
# Student profile endpoints
# ─────────────────────────────────────────────

@api_view(['GET'])
def get_student_profile(request, student_id):
    """Get student profile information."""
    try:
        student = Student.objects.filter(student_id__iexact=student_id).first()
        
        if not student:
            return Response({'success': False, 'message': 'Student not found'}, status=404)
        
        total_complaints = Complaint.objects.filter(student=student).count()
        pending_complaints = Complaint.objects.filter(student=student, status='pending').count()
        resolved_complaints = Complaint.objects.filter(student=student, status='resolved').count()
        rejected_complaints = Complaint.objects.filter(student=student, status='rejected').count()
        
        profile_pic_url = None
        if student.profile_picture and student.profile_picture.name:
            try:
                profile_pic_url = request.build_absolute_uri(student.profile_picture.url)
            except:
                profile_pic_url = None
        
        return Response({
            'success': True,
            'data': {
                'student_id': student.student_id,
                'name': student.name,
                'father_name': student.father_name if student.father_name else 'Not provided',
                'department': student.department if student.department else 'Not assigned',
                'session': student.session if student.session else 'Not set',
                'email': student.email if student.email else 'Not provided',
                'phone': student.phone if student.phone else 'Not provided',
                'address': student.address if student.address else 'Not provided',
                'date_of_birth': student.date_of_birth.strftime('%Y-%m-%d') if student.date_of_birth else None,
                'profile_picture': profile_pic_url,
                'total_complaints': total_complaints,
                'pending_complaints': pending_complaints,
                'resolved_complaints': resolved_complaints,
                'rejected_complaints': rejected_complaints,
                'created_at': student.created_at.strftime('%Y-%m-%d'),
            }
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        print(f"Error in get_student_profile: {str(e)}")
        return Response({'success': False, 'message': f'Error: {str(e)}'}, status=500)


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
                'email': admin_profile.email or user.email,
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
    """Get all notifications for admin's department - includes new complaints"""
    admin_type = request.GET.get('admin_type', '')
    
    if not admin_type:
        return Response({'success': False, 'message': 'admin_type required'}, status=400)
    
    notifications_data = []
    
    new_complaints = Complaint.objects.filter(
        admin_type=admin_type,
        is_seen_by_admin=False,
        status='pending'
    ).select_related('student').order_by('-created_at')
    
    for complaint in new_complaints:
        display_name = complaint.get_display_name()
        display_id = complaint.get_display_student_id()
        anon_label = " 🕵️ (Anonymous)" if complaint.is_anonymous else ""
        notifications_data.append({
            'id': complaint.pk,
            'type': 'new_complaint',
            'message': f"📢 New complaint #{complaint.pk}: '{complaint.title or complaint.complaint_type}' from {display_name}{anon_label}",
            'student_name': display_name,
            'student_id': display_id,
            'is_anonymous': complaint.is_anonymous,
            'complaint_id': complaint.pk,
            'created_at': complaint.created_at.strftime('%Y-%m-%d %H:%M'),
            'is_read': False,
        })
    
    week_ago = timezone.now() - timezone.timedelta(days=7)
    resolved_complaints = Complaint.objects.filter(
        admin_type=admin_type,
        status='resolved',
        resolved_at__gte=week_ago
    ).select_related('student').order_by('-resolved_at')
    
    for complaint in resolved_complaints:
        display_name = complaint.get_display_name()
        display_id = complaint.get_display_student_id()
        anon_label = " 🕵️ (Anonymous)" if complaint.is_anonymous else ""
        notifications_data.append({
            'id': f"resolved_{complaint.pk}",
            'type': 'resolved',
            'message': f"✅ Complaint #{complaint.pk} from {display_name} has been resolved.{anon_label}",
            'student_name': display_name,
            'student_id': display_id,
            'is_anonymous': complaint.is_anonymous,
            'complaint_id': complaint.pk,
            'created_at': complaint.resolved_at.strftime('%Y-%m-%d %H:%M'),
            'is_read': False,
        })
    
    rejected_complaints = Complaint.objects.filter(
        admin_type=admin_type,
        status='rejected',
        rejected_at__gte=week_ago
    ).select_related('student').order_by('-rejected_at')
    
    for complaint in rejected_complaints:
        display_name = complaint.get_display_name()
        display_id = complaint.get_display_student_id()
        anon_label = " 🕵️ (Anonymous)" if complaint.is_anonymous else ""
        notifications_data.append({
            'id': f"rejected_{complaint.pk}",
            'type': 'rejected',
            'message': f"❌ Complaint #{complaint.pk} from {display_name} was rejected.{anon_label}",
            'student_name': display_name,
            'student_id': display_id,
            'is_anonymous': complaint.is_anonymous,
            'complaint_id': complaint.pk,
            'created_at': complaint.rejected_at.strftime('%Y-%m-%d %H:%M'),
            'is_read': False,
        })
    
    notifications_data.sort(key=lambda x: x['created_at'], reverse=True)
    
    return Response({
        'success': True,
        'notifications': notifications_data[:50],
        'count': len(notifications_data),
        'new_complaints_count': new_complaints.count()
    })


@api_view(['GET'])
def get_notification_count(request):
    """Get count of unread notifications (new complaints)"""
    admin_type = request.GET.get('admin_type', '')
    
    if not admin_type:
        return Response({'count': 0})
    
    count = Complaint.objects.filter(
        admin_type=admin_type,
        is_seen_by_admin=False,
        status='pending'
    ).count()
    
    return Response({'count': count})


@api_view(['POST'])
def mark_notification_read(request, notification_id):
    """Mark a notification as read."""
    return Response({'success': True})


@api_view(['GET'])
def get_available_departments(request):
    """Get list of departments that have admin accounts created."""
    admin_profiles = AdminProfile.objects.select_related('user').all()
    
    role_display_names = {
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
    
    departments = []
    for profile in admin_profiles:
        if profile.user and profile.user.is_active:
            departments.append({
                'value': profile.role,
                'label': role_display_names.get(profile.role, profile.role.capitalize()),
                'admin_name': profile.user.get_full_name() or profile.user.username,
            })
    
    seen = set()
    unique_departments = []
    for dept in departments:
        if dept['value'] not in seen:
            seen.add(dept['value'])
            unique_departments.append(dept)
    
    return Response({
        'success': True,
        'departments': unique_departments,
        'count': len(unique_departments)
    }, status=status.HTTP_200_OK)


# ─────────────────────────────────────────────
# Student notification endpoints
# ─────────────────────────────────────────────

@api_view(['GET'])
def get_student_notifications(request, student_id):
    """Return all notifications for a student, newest first."""
    try:
        student = Student.objects.get(student_id=student_id)
    except Student.DoesNotExist:
        return Response({'success': False, 'message': 'Student not found'}, status=404)

    notifications = Notification.objects.filter(
        student=student
    ).order_by('-created_at')[:50]

    data = [
        {
            'id': n.pk,
            'message': n.message,
            'is_read': n.is_read,
            'created_at': n.created_at.strftime('%b %d, %Y  %H:%M'),
        }
        for n in notifications
    ]

    unread_count = sum(1 for n in data if not n['is_read'])

    return Response({
        'success': True,
        'notifications': data,
        'count': len(data),
        'unread_count': unread_count,
    })


@api_view(['POST'])
def mark_student_notification_read(request, notification_id):
    """Mark a single student notification as read."""
    try:
        notification = Notification.objects.get(pk=notification_id)
        notification.is_read = True
        notification.save(update_fields=['is_read'])
        return Response({'success': True})
    except Notification.DoesNotExist:
        return Response({'success': False, 'message': 'Notification not found'}, status=404)


@api_view(['POST'])
def mark_all_student_notifications_read(request, student_id):
    """Mark all notifications for a student as read."""
    try:
        student = Student.objects.get(student_id=student_id)
    except Student.DoesNotExist:
        return Response({'success': False, 'message': 'Student not found'}, status=404)

    updated = Notification.objects.filter(student=student, is_read=False).update(is_read=True)
    return Response({'success': True, 'updated': updated})


# ─────────────────────────────────────────────
# Student resolved/rejected count endpoints
# ─────────────────────────────────────────────

@api_view(['GET'])
def get_student_resolved_count(request, student_id):
    """Get count of newly resolved complaints for a student (last 7 days)"""
    try:
        student = Student.objects.get(student_id=student_id)
    except Student.DoesNotExist:
        return Response({'count': 0})
    
    week_ago = timezone.now() - timezone.timedelta(days=7)
    count = Complaint.objects.filter(
        student=student,
        status='resolved',
        resolved_at__gte=week_ago
    ).count()
    
    return Response({'count': count})


@api_view(['GET'])
def get_student_rejected_count(request, student_id):
    """Get count of newly rejected complaints for a student (last 7 days)"""
    try:
        student = Student.objects.get(student_id=student_id)
    except Student.DoesNotExist:
        return Response({'count': 0})
    
    week_ago = timezone.now() - timezone.timedelta(days=7)
    count = Complaint.objects.filter(
        student=student,
        status='rejected',
        rejected_at__gte=week_ago
    ).count()
    
    return Response({'count': count})


@api_view(['GET'])
def mark_student_resolved_seen(request, student_id):
    """Mark resolved complaints as seen for a student"""
    try:
        student = Student.objects.get(student_id=student_id)
        return Response({'success': True})
    except Student.DoesNotExist:
        return Response({'success': False}, status=404)


# ─────────────────────────────────────────────
# Super Admin Views
# ─────────────────────────────────────────────

@api_view(['POST'])
def super_admin_login(request):
    """Super Admin login endpoint"""
    username = request.data.get('username')
    password = request.data.get('password')
    
    user = authenticate(username=username, password=password)
    
    if user is not None:
        if hasattr(user, 'super_admin') or user.is_superuser:
            return Response({
                'success': True,
                'message': 'Super Admin login successful',
                'username': user.username,
                'is_super_admin': True
            })
        return Response({'success': False, 'message': 'Not a Super Admin account'}, status=403)
    
    return Response({'success': False, 'message': 'Invalid credentials'}, status=401)


@api_view(['GET'])
def super_admin_dashboard_stats(request):
    """Get comprehensive statistics for Super Admin dashboard"""
    total = Complaint.objects.count()
    pending = Complaint.objects.filter(status='pending').count()
    resolved = Complaint.objects.filter(status='resolved').count()
    rejected = Complaint.objects.filter(status='rejected').count()
    
    department_stats = list(
        Complaint.objects.values('admin_type')
        .annotate(
            total=Count('id'),
            pending=Count('id', filter=Q(status='pending')),
            resolved=Count('id', filter=Q(status='resolved')),
            rejected=Count('id', filter=Q(status='rejected')),
            avg_rating=Avg('rating__rating')
        )
        .order_by('-total')
    )
    
    # Add type_breakdown for each department
    for dept in department_stats:
        dept['type_breakdown'] = list(
            Complaint.objects.filter(admin_type=dept['admin_type'])
            .values('complaint_type')
            .annotate(count=Count('id'))
            .order_by('-count')
        )
    
    complaint_type_stats = list(
        Complaint.objects.values('complaint_type')
        .annotate(count=Count('id'))
        .order_by('-count')
    )
    
    escalated_count = EscalationLog.objects.count()
    pending_escalated = EscalationLog.objects.filter(
        is_resolved_by_super_admin=False,
        complaint__status='pending'
    ).count()
    
    thirty_days_ago = timezone.now() - timedelta(days=30)
    daily_trend = list(
        Complaint.objects.filter(created_at__gte=thirty_days_ago)
        .annotate(date=TruncDate('created_at'))
        .values('date')
        .annotate(
            total=Count('id'),
            pending=Count('id', filter=Q(status='pending')),
            resolved=Count('id', filter=Q(status='resolved')),
            rejected=Count('id', filter=Q(status='rejected')),
        )
        .order_by('date')
    )
    for row in daily_trend:
        row['date'] = row['date'].strftime('%Y-%m-%d')
    
    # Admin rating summary
    admin_rating_summary = list(
        AdminRating.objects.values('admin__user__username', 'admin__role')
        .annotate(
            avg_rating=Avg('rating'),
            total_ratings=Count('id')
        )
        .order_by('-avg_rating')
    )
    # Rename keys for frontend compatibility
    admin_rating_summary = [
        {
            'admin__user__username': r['admin__user__username'],
            'admin__role': r['admin__role'],
            'avg_rating': r['avg_rating'],
            'total_ratings': r['total_ratings'],
        }
        for r in admin_rating_summary
    ]
    
    return Response({
        'success': True,
        'overall': {
            'total': total,
            'pending': pending,
            'resolved': resolved,
            'rejected': rejected,
        },
        'department_stats': department_stats,
        'complaint_type_stats': complaint_type_stats,
        'daily_trend': daily_trend,
        'escalated_stats': {
            'total_escalated': escalated_count,
            'pending_escalated': pending_escalated,
        },
        'admin_rating_summary': admin_rating_summary,
    })

    
@api_view(['GET'])
def get_escalated_complaints(request):
    """All unresolved escalated complaints for Super Admin review."""
    escalated_ids = EscalationLog.objects.values_list('complaint_id', flat=True)
    complaints = Complaint.objects.filter(
        id__in=escalated_ids, 
        status='pending'
    ).select_related('student').order_by('-created_at')
    
    data = []
    for c in complaints:
        log = EscalationLog.objects.filter(complaint=c).first()
        data.append({
            'id': c.id,
            'title': c.title or c.complaint_type,
            'complaint_type': c.complaint_type,
            'description': c.description,
            'student_name': c.student.name,
            'student_id': c.student.student_id,
            'admin_type': c.admin_type,
            'created_at': c.created_at.strftime('%Y-%m-%d %H:%M'),
            'escalated_at': log.escalated_at.strftime('%Y-%m-%d %H:%M') if log else None,
            'days_pending': (timezone.now() - c.created_at).days,
        })
    
    return Response({'success': True, 'complaints': data})


@api_view(['POST'])
def reassign_escalated_complaint(request, complaint_id):
    """Super Admin reassigns complaint to a different department."""
    try:
        complaint = Complaint.objects.get(id=complaint_id)
    except Complaint.DoesNotExist:
        return Response({'error': 'Complaint not found'}, status=404)
    
    new_admin_type = request.data.get('new_admin_type', '').strip()
    valid_types = [c[0] for c in Complaint.ADMIN_TYPE_CHOICES]
    if new_admin_type not in valid_types:
        return Response({'error': f'Invalid admin type'}, status=400)
    
    complaint.admin_type = new_admin_type
    complaint.save(update_fields=['admin_type'])
    
    Notification.objects.create(
        student=complaint.student,
        message=f"🔄 Your complaint #{complaint.id} has been reassigned to {new_admin_type} department."
    )
    
    return Response({'success': True, 'message': 'Complaint reassigned successfully'})


@api_view(['POST'])
def resolve_escalated_complaint(request, complaint_id):
    """Super Admin directly resolves an escalated complaint."""
    try:
        complaint = Complaint.objects.get(id=complaint_id)
    except Complaint.DoesNotExist:
        return Response({'error': 'Complaint not found'}, status=404)
    
    complaint.status = 'resolved'
    complaint.resolved_at = timezone.now()
    complaint.save(update_fields=['status', 'resolved_at'])
    
    EscalationLog.objects.filter(complaint=complaint).update(is_resolved_by_super_admin=True)
    
    Notification.objects.create(
        student=complaint.student,
        message=f"✅ Your complaint '{complaint.title or complaint.complaint_type}' has been resolved by Super Admin."
    )
    
    return Response({'success': True, 'message': 'Complaint resolved successfully'})


@api_view(['GET'])
def get_all_admin_ratings(request):
    """Get all admin ratings for Super Admin with optional department filter"""
    admin_type = request.GET.get('admin_type', '')
    
    ratings = AdminRating.objects.select_related(
        'admin__user', 'student', 'complaint'
    ).all().order_by('-created_at')
    
    # Apply filter if admin_type is provided
    if admin_type:
        ratings = ratings.filter(admin__role=admin_type)
    
    data = [
        {
            'id': r.id,
            'complaint_id': r.complaint_id,
            'complaint_type': r.complaint.complaint_type,
            'admin_username': r.admin.user.username,
            'admin_role': r.admin.role,
            'student_id': r.student.student_id,
            'student_name': r.student.name,
            'rating': r.rating,
            'comment': r.comment or '',
            'created_at': r.created_at.strftime('%Y-%m-%d'),
        }
        for r in ratings
    ]
    
    return Response({'success': True, 'data': data})


@api_view(['GET'])
def get_complaint_rating(request, complaint_id):
    """Check if a complaint has been rated"""
    try:
        rating = AdminRating.objects.get(complaint_id=complaint_id)
        return Response({
            'success': True,
            'has_rated': True,
            'rating': rating.rating,
            'comment': rating.comment or '',
            'created_at': rating.created_at.strftime('%Y-%m-%d'),
        })
    except AdminRating.DoesNotExist:
        return Response({'success': True, 'has_rated': False})


@api_view(['POST'])
def submit_admin_rating(request, complaint_id):
    """Student rates the admin after complaint is resolved"""
    try:
        complaint = Complaint.objects.get(id=complaint_id, status='resolved')
    except Complaint.DoesNotExist:
        return Response({'error': 'Complaint not found or not resolved'}, status=404)
    
    if AdminRating.objects.filter(complaint=complaint).exists():
        return Response({'error': 'You have already rated this complaint'}, status=400)
    
    rating = request.data.get('rating')
    comment = request.data.get('comment', '')
    
    if not rating or not (1 <= int(rating) <= 5):
        return Response({'error': 'Rating must be between 1 and 5'}, status=400)
    
    admin_profile = AdminProfile.objects.filter(role=complaint.admin_type).first()
    
    if not admin_profile:
        return Response({'error': 'Admin not found'}, status=404)
    
    AdminRating.objects.create(
        complaint=complaint,
        admin=admin_profile,
        student=complaint.student,
        rating=int(rating),
        comment=comment
    )
    
    return Response({'success': True, 'message': 'Thank you for your feedback!'})


@api_view(['POST'])
def super_admin_register(request):
    """Super Admin registration endpoint"""
    SUPER_ADMIN_SECRET_KEY = getattr(settings, 'SUPER_ADMIN_SECRET_KEY', 'SUPER_ADMIN_SECRET_2026')
    
    name = str(request.data.get('name', '')).strip()
    username = str(request.data.get('username', '')).strip()
    password = str(request.data.get('password', ''))
    confirm_password = str(request.data.get('confirm_password', ''))
    secret_key = str(request.data.get('super_admin_secret_key', '')).strip()
    phone = str(request.data.get('phone', '')).strip()
    department = str(request.data.get('department', '')).strip()
    email = str(request.data.get('email', '')).strip()
    address = str(request.data.get('address', '')).strip()

    if secret_key != SUPER_ADMIN_SECRET_KEY:
        return Response({'success': False, 'message': 'Invalid super admin secret key.'}, status=403)

    if not all([name, username, password, confirm_password]):
        return Response({'success': False, 'message': 'All fields are required.'}, status=400)

    if password != confirm_password:
        return Response({'success': False, 'message': 'Passwords do not match.'}, status=400)

    if len(password) < 8:
        return Response({'success': False, 'message': 'Password must be at least 8 characters.'}, status=400)

    if User.objects.filter(username=username).exists():
        return Response({'success': False, 'message': 'Username already taken.'}, status=400)

    parts = name.split(' ', 1)
    first_name = parts[0]
    last_name = parts[1] if len(parts) > 1 else ''

    user = User.objects.create_user(
        username=username,
        password=password,
        first_name=first_name,
        last_name=last_name,
        email=email,
        is_staff=True,
        is_superuser=True,
    )

    # Create SuperAdmin record
    SuperAdmin.objects.create(user=user)

    # Also create admin profile for consistency
    AdminProfile.objects.create(
        user=user,
        role='administration',
        phone=phone or None,
        department=department or None,
        email=email or None,
        address=address or None,
    )

    return Response({
        'success': True,
        'message': 'Super Admin registered successfully.',
        'admin_id': user.pk,
        'username': user.username,
    }, status=201)




@api_view(['GET'])
def get_anonymous_complaints_by_admin_type(request, admin_type):
    """
    Get complaints for admin with identity properly hidden for anonymous complaints.
    This view ensures anonymous complaints show as "Anonymous #ANON-XXXX"
    """
    search_query = request.GET.get('search', '').strip()
    complaints = Complaint.objects.filter(admin_type=admin_type).select_related('student')

    if search_query:
        complaints = complaints.filter(
            Q(student__name__icontains=search_query) |
            Q(complaint_type__icontains=search_query) |
            Q(title__icontains=search_query) |
            Q(anonymous_display_id__icontains=search_query) |
            Q(pk__icontains=search_query)
        )
    complaints = complaints.order_by('-created_at')

    # Use the AdminComplaintListSerializer which handles anonymous display
    serializer = AdminComplaintListSerializer(complaints, many=True)
    
    return Response({
        'success': True, 
        'count': complaints.count(), 
        'data': serializer.data
    }, status=status.HTTP_200_OK)