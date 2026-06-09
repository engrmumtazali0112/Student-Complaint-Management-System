from django.urls import path
from .views import (
    student_login,
    student_register,
    student_dashboard,
    submit_complaint,
    complaint_detail,
    complaint_detail_by_id,
    track_complaints,
    student_resolved_complaints,
    complaint_list,
    get_available_departments,
    solved_complaints,
    update_complaint_status,
    pending_complaints,
    new_complaint_count,
    mark_complaints_seen,
    reject_complaint,
    rejected_complaints,
    admin_login,
    admin_register,
    get_complaints_by_admin_type,
    get_student_profile,
    upload_student_profile_pic,
    get_admin_profile,
    upload_admin_profile_pic,
    get_admin_notifications,
    get_notification_count,
    mark_notification_read,
    # ── student notifications ──
    get_student_notifications,
    mark_student_notification_read,
    mark_all_student_notifications_read,
    # ── student resolved/rejected counts (NEW) ──
    get_student_resolved_count,
    get_student_rejected_count,
    mark_student_resolved_seen,
)

urlpatterns = [
    # ── Student auth / dashboard ──────────────────────────────
    path('student/login/',                        student_login,               name='student_login'),
    path('student/register/',                     student_register,            name='student_register'),
    path('student/dashboard/<path:student_id>/',  student_dashboard,           name='student_dashboard'),

    # ── Student complaints ────────────────────────────────────
    path('student/complaint/submit/',                                         submit_complaint,           name='submit_complaint'),
    path('student/complaint/<path:student_id>/<int:complaint_id>/',           complaint_detail,           name='complaint_detail'),
    path('student/complaint/track/<path:student_id>/',                        track_complaints,           name='track_complaints'),
    path('student/complaint/resolved/<path:student_id>/',                     student_resolved_complaints,name='student_resolved_complaints'),

    # ── Student profile ───────────────────────────────────────
    path('student/profile/<path:student_id>/',    get_student_profile,         name='get_student_profile'),
    path('student/upload-profile-pic/',           upload_student_profile_pic,  name='upload_student_profile_pic'),

    # ── Student notifications ─────────────────────────────────
    path('student/notifications/<path:student_id>/',
         get_student_notifications,
         name='get_student_notifications'),
    path('student/notifications/mark-read/<int:notification_id>/',
         mark_student_notification_read,
         name='mark_student_notification_read'),
    path('student/notifications/mark-all-read/<path:student_id>/',
         mark_all_student_notifications_read,
         name='mark_all_student_notifications_read'),

    # ── Student resolved/rejected counts (NEW) ────────────────
    path('student/resolved-count/<path:student_id>/',
         get_student_resolved_count,
         name='get_student_resolved_count'),
    path('student/rejected-count/<path:student_id>/',
         get_student_rejected_count,
         name='get_student_rejected_count'),
    path('student/mark-resolved-seen/<path:student_id>/',
         mark_student_resolved_seen,
         name='mark_student_resolved_seen'),

    # ── Admin auth ────────────────────────────────────────────
    path('admin/login/',                          admin_login,                 name='admin_login'),
    path('admin/register/',                       admin_register,              name='admin_register'),
    path('admin/profile/<str:username>/',         get_admin_profile,           name='get_admin_profile'),
    path('admin/upload-profile-pic/',             upload_admin_profile_pic,    name='upload_admin_profile_pic'),

    # ── Admin complaints ──────────────────────────────────────
    path('admin/complaint/',                                    complaint_list,           name='complaint_list'),
    path('admin/complaint/update-status/<int:pk>/',             update_complaint_status,  name='update_complaint_status'),
    path('admin/complaint/solved/',                             solved_complaints,         name='solved_complaints'),
    path('admin/complaint/pending/',                            pending_complaints,        name='pending_complaints'),
    path('admin/complaint/rejected/',                           rejected_complaints,       name='rejected_complaints'),
    path('admin/complaint/reject/<int:pk>/',                    reject_complaint,          name='reject_complaint'),
    path('admin/new-count/',                                    new_complaint_count,       name='new_complaint_count'),
    path('admin/mark-seen/',                                    mark_complaints_seen,      name='mark_complaints_seen'),
    path('admin/complaints/<str:admin_type>/',                  get_complaints_by_admin_type, name='get_complaints_by_admin_type'),

    # ── Admin notifications ───────────────────────────────────
    path('admin/notifications/',                                get_admin_notifications,   name='get_admin_notifications'),
    path('admin/notifications/count/',                          get_notification_count,    name='get_notification_count'),
    path('admin/notifications/mark-read/<int:notification_id>/',mark_notification_read,   name='mark_notification_read'),

    # ── Direct complaint access ───────────────────────────────
    path('complaint/<int:complaint_id>/',         complaint_detail_by_id,      name='complaint_detail_by_id'),
    path('departments/available/',                get_available_departments,   name='get_available_departments'),
]