# 🎓 Student Complaint Management System

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-3.27.0-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Django](https://img.shields.io/badge/Django-6.0.5-092E20?style=for-the-badge&logo=django&logoColor=white)](https://www.djangoproject.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-18.4-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![DRF](https://img.shields.io/badge/Django_REST-3.17.1-ff1709?style=for-the-badge&logo=django&logoColor=white)](https://www.django-rest-framework.org/)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-Welcome-brightgreen?style=for-the-badge)](CONTRIBUTING.md)

<br/>

> A full-stack complaint management platform built for universities — empowering students to raise concerns and enabling department admins to resolve them efficiently.

<br/>

[📱 Features](#-features) · [🖼️ Demo](#%EF%B8%8F-demo) · [🏗️ Architecture](#%EF%B8%8F-architecture) · [🚀 Quick Start](#-quick-start) · [📋 API Docs](#-api-endpoints) · [🤝 Contributing](#-contributing)

</div>

---

## 📊 Portal Status

| Portal | Status | Description |
|--------|--------|-------------|
| 🎓 Student Portal | ✅ Live | Submit, track, and manage complaints |
| 🛡️ Admin Portal | ✅ Live | Role-based complaint management |
| 🏠 Warden Portal | ✅ Live | Hostel & infrastructure complaints |
| 📝 Examination Portal | ✅ Live | Exam-related issues |
| 💰 Treasury Portal | ✅ Live | Fee & financial complaints |
| 🔒 Security Portal | ✅ Live | Campus security issues |
| 🚌 Transport Portal | ✅ Live | Transport complaints |
| 📚 Library Portal | ✅ Live | Library-related issues |
| 🏋️ Sports Portal | ✅ Live | Sports facility complaints |
| 💻 IT Portal | ✅ Live | Lab & IT support issues |

---

## 🌟 Features

### 👨‍🎓 Student Portal

| Feature | Details |
|---------|---------|
| 🔐 **Secure Auth** | Register & login using university roll number |
| 📝 **Submit Complaints** | Title, description, department selection, and file attachments |
| 🏢 **10 Departments** | Route complaints to the right authority automatically |
| 📍 **Real-Time Tracking** | Live status updates — Pending / Resolved / Rejected |
| 📎 **File Attachments** | Upload images, PDFs, or documents as supporting evidence |
| 🔔 **Notifications** | Instant in-app alerts on complaint status changes |
| 📜 **Complaint History** | Full history with timestamps and resolution details |
| 🖼️ **Profile Picture** | Upload and update profile picture during registration or from profile |

### 👨‍💼 Admin Portal

| Feature | Details |
|---------|---------|
| 🗂️ **Role-Based Access** | Each department has its own isolated complaint queue |
| ✅ **Resolve / ❌ Reject** | One-click resolution or rejection with mandatory remarks |
| 📊 **Live Dashboard** | Real-time counters — Total / Pending / Resolved / Rejected |
| 🔍 **Search & Filter** | Find complaints by ID, title, student name, or type |
| 🔔 **Auto-Notifications** | Students are automatically notified on any status change |
| 👤 **Profile Management** | View, manage, and update department admin profile picture |

---

## 🖼️ Demo

### Welcome & Role Selection

| Welcome Screen | Role Selection |
|:--------------:|:--------------:|
| ![Welcome Screen](demo/1.PNG) | ![Role Selection](demo/2.PNG) |

> **Welcome Screen** — Highlights platform features: Easy Complaint Submission, Real-time Status Tracking, and Secure & Confidential access. **Role Selection** — Users choose between the Student Portal and Admin Portal.

---

### Student Portal

| Student Login | Student Profile & Dashboard |
|:-------------:|:---------------------------:|
| ![Student Login](demo/3.PNG) | ![Student Profile](demo/4.PNG) |

| Profile Details & Notifications | Track Complaints |
|:--------------------------------:|:----------------:|
| ![Profile Details](demo/5.PNG) | ![Track Complaints](demo/6.PNG) |

> **Student Login** — Secure authentication using university roll number (e.g. `CS-06F/22-26`).  
> **Profile & Dashboard** — Sidebar with complaint stats (Total / Pending / Resolved / Rejected), profile picture upload, and full personal details.  
> **Notifications** — Real-time alerts when a complaint status changes (e.g. resolved, rejected).  
> **Track Complaints** — Search and filter complaints by title, status, or ID with live counters.

---

### Admin Portal

| Admin Login | Admin Profile & Dashboard | Pending Complaints |
|:-----------:|:-------------------------:|:------------------:|
| ![Admin Login](demo/7.PNG) | ![Admin Dashboard](demo/8.PNG) | ![Pending Complaints](demo/9.PNG) |

> **Admin Login** — Dark-themed secure portal for authorized personnel only.  
> **Admin Dashboard** — Role-based profile (e.g. Hostel Manager), complaint stats, and sidebar navigation across All / Pending / Resolved / Rejected views.  
> **Pending Complaints** — Searchable list with status badges (RESOLVED / REJECTED), student name, roll number, and date — with one-click detail view.

---

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                     Flutter Frontend                         │
│         Student Portal  ·  10× Admin Portals                 │
└─────────────────────────┬────────────────────────────────────┘
                          │  HTTP / REST
                          ▼
┌──────────────────────────────────────────────────────────────┐
│                   Django REST API                            │
│      Authentication  ·  CRUD  ·  Signals  ·  File Uploads   │
└─────────────────────────┬────────────────────────────────────┘
                          │  psycopg2
                          ▼
┌──────────────────────────────────────────────────────────────┐
│                   PostgreSQL Database                        │
│          Students  ·  Complaints  ·  AdminProfiles           │
└──────────────────────────────────────────────────────────────┘
```

---

## 🔐 Multi-Role Admin System

| Role | Department | Handles |
|------|------------|---------|
| `administration` | Administration | General university complaints |
| `warden` | Warden | Hostel & infrastructure |
| `examination` | Examination | Exam-related issues |
| `treasury` | Treasury | Fee & financial matters |
| `security` | Security | Campus security concerns |
| `transport` | Transport | Bus & transport issues |
| `library` | Library | Library access & resources |
| `hostel` | Hostel | Hostel facilities |
| `sports` | Sports | Sports facilities |
| `it` | IT Department | Lab & IT support |

> Each admin account only sees complaints directed to their department — full role isolation.

---

## 🛠️ Tech Stack

### Frontend

| Technology | Version | Purpose |
|------------|---------|---------|
| Flutter | 3.27.0 | Cross-platform UI framework |
| Dart | 3.9.2 | Programming language |
| `http` | 1.1.0 | REST API communication |
| `file_picker` | 8.0.0 | File upload support |
| `image_picker` | Latest | Profile picture selection |

### Backend

| Technology | Version | Purpose |
|------------|---------|---------|
| Python | 3.14+ | Server-side language |
| Django | 6.0.5 | Web framework |
| Django REST Framework | 3.17.1 | API layer |
| PostgreSQL | 18.4 | Primary database |
| `psycopg2-binary` | Latest | PostgreSQL adapter |

---

## 📋 API Endpoints

### 🎓 Student Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/student/login/` | Student authentication |
| `POST` | `/api/student/register/` | New student registration |
| `GET` | `/api/student/dashboard/<student_id>/` | Dashboard data + stats + notifications |
| `POST` | `/api/student/complaint/submit/` | Submit a complaint (supports file upload) |
| `GET` | `/api/student/complaint/track/<student_id>/` | Track all complaints |
| `GET` | `/api/student/complaint/<student_id>/<complaint_id>/` | Complaint detail view |
| `GET` | `/api/student/profile/<student_id>/` | Get student profile with stats |
| `POST` | `/api/student/profile/upload-pic/<student_id>/` | Upload student profile picture |

### 🛡️ Admin Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/admin/login/` | Admin authentication |
| `POST` | `/api/admin/register/` | Admin account creation |
| `GET` | `/api/admin/complaints/<admin_type>/` | Role-specific complaint queue |
| `GET` | `/api/admin/complaint/pending/` | All pending complaints |
| `GET` | `/api/admin/complaint/solved/` | All resolved complaints |
| `GET` | `/api/admin/complaint/rejected/` | All rejected complaints |
| `PATCH` | `/api/admin/complaint/update-status/<id>/` | Update complaint status |
| `POST` | `/api/admin/complaint/reject/<id>/` | Reject with remarks |
| `GET` | `/api/admin/new-count/` | Unseen complaint count |
| `POST` | `/api/admin/mark-seen/` | Mark complaints as seen |
| `GET` | `/api/admin/profile/<admin_id>/` | Get admin profile |
| `POST` | `/api/admin/profile/upload-pic/<admin_id>/` | Upload admin profile picture |

### 🔗 Shared Endpoint

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/api/complaint/<complaint_id>/` | Direct complaint lookup by ID |

---

## 🚀 Quick Start

### Prerequisites

- **Flutter SDK** 3.27.0+
- **Python** 3.14+
- **PostgreSQL** 18.4+
- **Git**

---

### ⚙️ Backend Setup

```bash
# 1. Clone the repository
git clone https://github.com/engrmumtazali0112/Student-Complaint-Management-System.git
cd Student-Complaint-Management-System/backend

# 2. Create & activate virtual environment
python -m venv venv

# Windows
.\venv\Scripts\Activate.ps1

# macOS / Linux
source venv/bin/activate

# 3. Install dependencies
pip install -r requirements.txt
```

**4. Configure PostgreSQL** — create a database and update `config/settings.py`:

```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'fyp_db',
        'USER': 'postgres',
        'PASSWORD': 'your_password',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}
```

```bash
# 5. Apply migrations
python manage.py makemigrations
python manage.py migrate

# 6. Create Django superuser
python manage.py createsuperuser

# 7. Start backend server
python manage.py runserver
```

---

### 📱 Frontend Setup

```bash
# Navigate to the Flutter project
cd ../frontend

# Install dependencies
flutter pub get

# Run in browser
flutter run -d chrome

# Run on connected device
flutter run
```

---

### 👤 Seed Admin Accounts

Run once to create all department admin users:

```bash
python manage.py shell
```

```python
from django.contrib.auth.models import User
from api.models import AdminProfile

admins = [
    ('admin',    'admin123',    'Administration', 'administration'),
    ('warden',   'warden123',   'Warden',         'warden'),
    ('exam',     'exam123',     'Examination',    'examination'),
    ('treasury', 'treasury123', 'Treasury',       'treasury'),
    ('security', 'security123', 'Security',       'security'),
    ('transport','transport123','Transport',      'transport'),
    ('library',  'library123',  'Library',        'library'),
    ('hostel',   'hostel123',   'Hostel',         'hostel'),
    ('sports',   'sports123',   'Sports',         'sports'),
    ('it',       'it123',       'IT Department',  'it'),
]

for username, password, name, role in admins:
    user = User.objects.create_user(username=username, password=password, first_name=name)
    AdminProfile.objects.create(user=user, role=role)
    print(f"✅ Created {role}: {username}")
```

---

## 📁 Project Structure

```
Student-Complaint-Management-System/
│
├── backend/
│   ├── config/
│   │   ├── settings.py          # Django configuration
│   │   ├── urls.py              # Root URL routing
│   │   └── asgi.py              # ASGI entry point
│   │
│   └── api/
│       ├── models.py            # Student, Complaint, AdminProfile, Notification
│       ├── views.py             # All API view logic
│       ├── serializers.py       # DRF serializers
│       ├── urls.py              # API URL patterns
│       ├── admin.py             # Django admin config
│       ├── apps.py              # App config + signal registration
│       └── signals.py           # Auto-notification on complaint updates
│
├── frontend/
│   ├── pubspec.yaml
│   └── lib/
│       └── screens/
│           ├── welcome.dart                       # Landing page
│           ├── role_selection_screen.dart         # Student or Admin entry
│           ├── student_login.dart
│           ├── student_register.dart              # Registration with profile picture
│           ├── student_sidebar_dashboard.dart     # Sidebar + stats + profile
│           ├── student_profile_screen.dart        # Profile picture upload
│           ├── submit_complaint.dart
│           ├── track_complains.dart
│           ├── view_complains.dart                # Complaint detail with remarks
│           ├── solved_complaints.dart
│           ├── admin_portal.dart                  # Admin login
│           ├── admin_register.dart                # Registration with profile picture
│           ├── admin_sidebar_dashboard.dart       # Sidebar + notifications tab
│           ├── pending_complaints.dart
│           ├── admin_role_rejected_complaints.dart
│           └── confirmation.dart
│
└── demo/
    ├── 1.PNG    # Welcome screen
    ├── 2.PNG    # Role selection
    ├── 3.PNG    # Student login
    ├── 4.PNG    # Student profile & dashboard
    ├── 5.PNG    # Profile details & notifications
    ├── 6.PNG    # Track complaints
    ├── 7.PNG    # Admin login
    ├── 8.PNG    # Admin profile & dashboard
    └── 9.PNG    # Pending complaints management
```

---

## 🗄️ Database Schema

### Student

| Field | Type | Notes |
|-------|------|-------|
| `student_id` | `CharField(20)` | Unique; format `CS-06F/22-26` |
| `name` | `CharField(100)` | Full name |
| `father_name` | `CharField(100)` | Father's name |
| `department` | `CharField(100)` | Academic department |
| `session` | `CharField(50)` | Academic session |
| `profile_picture` | `ImageField` | Optional profile photo |
| `user` | `OneToOneField(User)` | Linked Django auth user |

### Complaint

| Field | Type | Notes |
|-------|------|-------|
| `student` | `ForeignKey(Student)` | Complaint owner |
| `title` | `CharField(200)` | Short title |
| `complaint_type` | `CharField(100)` | Category |
| `admin_type` | `CharField(20)` | Target department (10 choices) |
| `description` | `TextField` | Full complaint body |
| `status` | `CharField(20)` | `pending` / `resolved` / `rejected` |
| `attachment` | `FileField` | Optional supporting file |
| `rejection_remarks` | `TextField` | Required when rejecting |
| `created_at` | `DateTimeField` | Auto-set on creation |
| `resolved_at` | `DateTimeField` | Set on resolution |

### AdminProfile

| Field | Type | Notes |
|-------|------|-------|
| `user` | `OneToOneField(User)` | Linked Django auth user |
| `role` | `CharField(20)` | One of 10 `AdminRole` choices |
| `phone` | `CharField(15)` | Optional contact number |
| `department` | `CharField(100)` | Department label |
| `profile_picture` | `ImageField` | Optional profile photo |

---

## 🤝 Contributing

Contributions are very welcome! Here's how to get started:

```bash
# 1. Fork the repo and clone your fork
git clone https://github.com/YOUR_USERNAME/Student-Complaint-Management-System.git

# 2. Create a feature branch
git checkout -b feature/your-feature-name

# 3. Make your changes and commit
git commit -m "feat: add your feature description"

# 4. Push and open a Pull Request
git push origin feature/your-feature-name
```

Please follow [Conventional Commits](https://www.conventionalcommits.org/) for commit messages and ensure your code passes all existing tests before submitting.

---

## 📄 License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for full details.

---

## 👨‍💻 Author

<div align="center">

**Mumtaz Ali**

[![GitHub](https://img.shields.io/badge/GitHub-engrmumtazali0112-181717?style=for-the-badge&logo=github)](https://github.com/engrmumtazali0112)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Mumtaz_Ali-0A66C2?style=for-the-badge&logo=linkedin)](https://linkedin.com/in/mumtazali)
[![Email](https://img.shields.io/badge/Email-engrmumtazali0112@gmail.com-EA4335?style=for-the-badge&logo=gmail)](mailto:engrmumtazali0112@gmail.com)

</div>

---

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev) — for the beautiful cross-platform UI framework
- [Django](https://www.djangoproject.com/) — for the robust and scalable backend
- [Django REST Framework](https://www.django-rest-framework.org/) — for the clean API layer
- [PostgreSQL](https://www.postgresql.org/) — for reliable and performant data storage

---

<div align="center">

### ⭐ If this project helped you, please give it a star on GitHub!

**Made with ❤️ by [Mumtaz Ali](https://github.com/engrmumtazali0112)**

</div>