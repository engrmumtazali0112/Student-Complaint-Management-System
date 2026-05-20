from django.contrib.auth import authenticate
from rest_framework.decorators import api_view
from rest_framework.views import APIView
from django.views.decorators.csrf import csrf_exempt
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth.models import User
from .models import Student, Complaint, Notification 
from .serializers import ComplaintDetailSerializer , SolvedComplaintSerializer, PendingComplaintSerializer
from django.db.models import Q
from django.utils import timezone
from django.shortcuts import get_object_or_404


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
                'user_id': user.id,
                'student_id': user.username
            })
        else:
            return Response({
                'success': False,
                'message': 'Not a student account'
            }, status=403)

    return Response({
        'success': False,
        'message': 'Invalid Student ID or Password'
    }, status=401)


@api_view(['POST'])
def student_register(request):
    name = request.data.get('name')
    father_name = request.data.get('father_name')
    roll_number = request.data.get('roll_no')                                     #roll_no = request.data.get('roll_no')
    department = request.data.get('department')
    session = request.data.get('session')
    password = request.data.get('password')
    confirm_password = request.data.get('confirm_password')

    # 1️⃣ Validate passwords
    if password != confirm_password:
        return Response({
            'success': False,
            'message': 'Passwords do not match'
        }, status=400)

    # 2️⃣ Check existing user
    if User.objects.filter(username=roll_number).exists():
        return Response({
            'success': False,
            'message': 'Student already registered'
        }, status=400)

    # 3️⃣ Create user
    user = User.objects.create_user(
        username=roll_number,
        password=password,
        first_name=name
    )

    # 4️⃣ Create student profile
    #StudentProfile.objects.create(
        #user=user,
        #father_name=father_name,
        #department=department)

    # 4️⃣ Create student 
    Student.objects.create(
        user=user,
        student_id=roll_number,
        father_name= father_name,
        name=name,
        department=department,
        session=session
    )

    return Response({
        'success': True,
        'message': 'Registration successful'
    })

# submit complain 


 # @csrf_exempt
@api_view(['POST'])
def submit_complaint(request):

    try:
        data = request.data
    except:
        return Response({
            "success": False,
            "message": "Invalid request data"
        }, status=400)

    student_id = data.get('roll_number')
    department = data.get('department')
    session = data.get('session')
    complaint_type = data.get('complaint_type')
    description = data.get('description')

    # ---- DEBUG PRINT (important) ----
    print("DATA RECEIVED:", data)

    if not all([student_id, department, session, complaint_type, description]):
        return Response({
            "success": False,
            "message": "All fields are required"
        }, status=400)

   # try:
        user = User.objects.get(username=student_id)
        student = user.student                                                #student = Student.objects.get(student_id=roll_number)
    #except (User.DoesNotExist, Student.DoesNotExist):                 #Student.DoesNotExist:
        return Response({
            "success": False,
            "message": "Student not found"
        }, status=404)
    student = Student.objects.filter(
        student_id__iexact= student_id
    ).first()

    if not student:
        return Response({
            "success": False,
            "message": "Student not found"
        }, status=404)

    complaint = Complaint.objects.create(
        student=student,
        #student_id = student_id,
        #roll_number=roll_number,
        department=department,
        session=session,
        complaint_type=complaint_type,
        description=description,
        status='pending'
    )

    print("COMPLAINT SAVED ID:", complaint.id)

    return Response({
        "success": True,
        "message": "Complaint submitted successfully",
        "complaint_id": complaint.id
    }, status=201)

@api_view(['GET'])
def student_dashboard(request, student_id):
    try:
        student = Student.objects.filter(student_id__iexact=student_id).first()
    except Student.DoesNotExist:
        return Response({
            "success": False,
            "message": "Student not found"
        }, status=404)

    # ---- Complaint stats ----
    total_complaints = Complaint.objects.filter(student=student).count()
    pending_complaints = Complaint.objects.filter(student=student, status='pending').count()
    resolved_complaints = Complaint.objects.filter(student=student, status='Resolved').count()

    # ---- Notifications ----
    notifications_qs = Notification.objects.filter(student=student).order_by('-created_at')[:5]
    notifications = [
        {
            "message": n.message,
            "date": n.created_at.strftime("%Y-%m-%d %H:%M")
        }
        for n in notifications_qs
    ]

    data = {
        "success": True,
        "student": {
            "name": student.name,
            "student_id": student.student_id,
            "department": student.department
        },
        "notifications": notifications,
        "stats": {
            "total": total_complaints,
            "pending": pending_complaints,
            "resolved": resolved_complaints
        }
    }

    return Response(data)

# view complain model
@api_view(['GET'])
def complaint_detail(request, student_id, complaint_id):
    student = get_object_or_404(Student, student_id=student_id)
    try:
        complaint = Complaint.objects.get(id=complaint_id, 
                                          student=student)
    except Complaint.DoesNotExist:
        return Response(
            {"success": False, "message": "Complaint not found"},
            status=status.HTTP_404_NOT_FOUND
        )

    serializer = ComplaintDetailSerializer(complaint)

    return Response({
        "success": True,
        "data": serializer.data
    }, status=status.HTTP_200_OK)

    # Track Complains

@api_view(['GET'])
def track_complaints(request, student_id):
    """
    Track all complaints for a specific student
    Supports search
    """

    # Get student safely
    student = get_object_or_404(Student, student_id=student_id)

    search_query = request.GET.get('search', '').strip()

    complaints = Complaint.objects.filter(student=student)

    # Search support
    if search_query:
        complaints = complaints.filter(
            Q(complaint_type__icontains=search_query) |
            Q(status__icontains=search_query) |
            Q(id__icontains=search_query)
        )

    complaints = complaints.order_by('-created_at')

    data = [
        {
            "id": complaint.id,
            "subject": complaint.complaint_type,
            "status": complaint.status,
            "created_at": complaint.created_at.strftime("%b %d, %Y")
        }
        for complaint in complaints
    ]

    return Response({
        "success": True,
        "count": complaints.count(),
        "data": data
    }, status=status.HTTP_200_OK)

@api_view(['GET'])
def complaint_list(request):
    """
    Get all complaints (Admin View)
    Supports search
    """

    search_query = request.GET.get('search', '').strip()

    complaints = Complaint.objects.select_related('student').all()

    if search_query:
        complaints = complaints.filter(
            Q(student__name__icontains=search_query) |
            Q(complaint_type__icontains=search_query)
        )

    complaints = complaints.order_by('-created_at')

    data = [
        {
            "id": complaint.id,
            "complainant": complaint.student.name,
            "student_id": complaint.student.student_id,
            "subject": complaint.complaint_type,
            "status": complaint.status,
            "date": complaint.created_at.strftime("%b %d, %Y")
        }
        for complaint in complaints
    ]

    return Response({
        "success": True,
        "count": complaints.count(),
        "data": data
    }, status=status.HTTP_200_OK)

@api_view(['PATCH'])
def update_complaint_status(request, pk):
    try:
        complaint = Complaint.objects.get(id=pk)

        new_status = request.data.get('status')

        if new_status not in ['Pending', 'Resolved']:
            return Response({"error": "Invalid status"}, status=400)
        
        # ✅ Check if status is changing to Resolved
        if new_status == "Resolved":
            print("🔥 Creating notification...")
            Notification.objects.create(
                student=complaint.student,
                message=f"Your complaint '{complaint.complaint_type}' has been resolved 😊."
            )

        complaint.status = new_status

        if new_status == "Resolved":
            complaint.resolved_at = timezone.now()
        else:
            complaint.resolved_at = None

        complaint.save()

        return Response({"message": "Status updated successfully"})

    except Complaint.DoesNotExist:
        return Response({"error": "Complaint not found"}, status=404)
    


@api_view(['GET'])
def solved_complaints(request):
    query = request.GET.get('search', '')

    complaints = Complaint.objects.filter(status="Resolved")

    # 🔍 SEARCH SUPPORT
    if query:
        complaints = complaints.filter(
            Q(complaint_type__icontains=query) |
            Q(department__icontains=query) |
            Q(id__icontains=query)
        )

    complaints = complaints.order_by('-created_at')

    serializer = SolvedComplaintSerializer(complaints, many=True)

    return Response({
        "data": serializer.data
    })


@api_view(['GET'])
def pending_complaints(request):
    query = request.GET.get('search', '')

    complaints = Complaint.objects.filter(status="Pending")

    if query:
        complaints = complaints.filter(
            Q(complaint_type__icontains=query) |
            Q(student_name__icontains=query) |
            Q(status__icontains=query) |
            Q(id__icontains=query)
        )

    complaints = complaints.order_by('-created_at')

    serializer = PendingComplaintSerializer(complaints, many=True)

    return Response({"data": serializer.data})


@api_view(['GET'])
def new_complaint_count(request):
    count = Complaint.objects.filter(
        is_seen_by_admin=False,
        status='pending'
    ).count()

    return Response({"new_count": count})

@api_view(['POST'])
def mark_complaints_seen(request):
    Complaint.objects.filter(
        is_seen_by_admin=False,
        status='Resolved || Pending'
    ).update(is_seen_by_admin=True)

    return Response({"message": "Marked as seen"})