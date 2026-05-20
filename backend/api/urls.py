from django.urls import path
from .views import student_login , student_register , student_dashboard , submit_complaint , complaint_detail , track_complaints ,complaint_list , solved_complaints, update_complaint_status, pending_complaints,new_complaint_count,mark_complaints_seen


urlpatterns = [
    path('student/login/', student_login),
    path('student/register/', student_register),
    path('student/dashboard/<path:student_id>/', student_dashboard),
    path('student/complaint/submit/', submit_complaint),
    path('student/complaint/<path:student_id>/<int:complaint_id>/', complaint_detail),
    path('student/complaint/track/<path:student_id>/', track_complaints),
    path('admin/complaint/update-status/<int:pk>/', update_complaint_status),
    path('admin/complaint/', complaint_list),
    path('admin/complaint/solved/', solved_complaints),
    path('admin/complaint/pending/', pending_complaints),
    path('admin/new-count/', new_complaint_count),
    path('admin/mark-seen/', mark_complaints_seen),


]
