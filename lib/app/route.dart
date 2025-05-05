import 'package:go_router/go_router.dart';
import '../features/auth/login/login_screen.dart';
import '../features/auth/signup/signup_screen.dart';
import '../features/auth/welcome_screen.dart';
import '../features/student/student_page.dart';
import '../features/teacher/teacher_page.dart';
import '../features/admin/admin_page.dart';
import '../features/admin/students/students_list_page.dart';
import '../features/admin/students/add_student_page.dart';
import '../features/admin/students/edit_student_page.dart';
import '../features/admin/teachers/teachers_list_page.dart';
import '../features/admin/teachers/add_teacher_page.dart';
import '../features/admin/teachers/edit_teacher_page.dart';
import '../features/admin/classes/classes_list_page.dart';
import '../features/admin/classes/add_class_page.dart';
import '../features/admin/classes/edit_class_page.dart';
import '../features/admin/assignments/assignments_list_page.dart';
import '../features/admin/assignments/add_assignment_page.dart';
import '../features/admin/assignments/edit_assignment_page.dart';
import '../features/admin/reports/reports_page.dart';
import '../features/auth/login/forgot_password_view.dart';
import '../features/auth/login/reset_password_screen.dart';
import '../app/app_config.dart';
import '../features/auth/signup/teacher_signup_screen.dart';
import '../features/auth/signup/admin_signup_screen.dart';
import '../features/admin/subjects/add_subject_page.dart';
import '../features/admin/subjects/edit_subject_page.dart';
import '../features/admin/subjects/subjects_list_page.dart';
import '../features/admin/subjects/assign_subject_page.dart';
import '../features/admin/schedule/schedule_list_page.dart';
import '../features/admin/schedule/add_schedule_page.dart';
import '../features/admin/schedule/edit_schedule_page.dart';
import '../features/teacher/subjects/subjects_page.dart';
import '../features/teacher/students/students_page.dart';
import '../features/teacher/assignments/assignments_page.dart';
import '../features/teacher/attendance/attendance_page.dart';
import '../features/teacher/grades/grades_page.dart';
import '../features/teacher/schedule/schedule_page.dart';
import '../features/teacher/assignments/add_assignment_page.dart';

// Export the router so it can be imported in main.dart
export 'app_config.dart' show navigatorKey;

final GoRouter appRouter = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const WelcomeView()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
    GoRoute(
      path: '/teacher-signup',
      builder: (context, state) => const TeacherSignUpPage(),
    ),
    GoRoute(
      path: '/admin-signup',
      builder: (context, state) => const AdminSignupScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordView(),
    ),
    GoRoute(
      path: '/reset-password',
      builder: (context, state) {
        final token = state.uri.queryParameters['refresh_token'];
        return ResetPasswordPage(refreshToken: token!);
      },
    ),
    GoRoute(path: '/admin', builder: (context, state) => const AdminPage()),
    GoRoute(
      path: '/admin/classes',
      builder: (context, state) => const ClassesListPage(),
    ),
    GoRoute(
      path: '/admin/classes/add',
      builder: (context, state) => const AddClassPage(),
    ),
    GoRoute(
      path: '/admin/classes/edit/:className',
      builder:
          (context, state) =>
              EditClassPage(className: state.pathParameters['className']!),
    ),
    GoRoute(
      path: '/admin/students',
      builder: (context, state) => const StudentsListPage(),
    ),
    GoRoute(
      path: '/admin/students/add',
      builder: (context, state) => const AddStudentPage(),
    ),
    GoRoute(
      path: '/admin/students/edit/:id',
      builder:
          (context, state) =>
              EditStudentPage(studentId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/admin/teachers',
      builder: (context, state) => const TeachersListPage(),
    ),
    GoRoute(
      path: '/admin/teachers/add',
      builder: (context, state) => const AddTeacherPage(),
    ),
    GoRoute(
      path: '/admin/teachers/edit/:id',
      builder:
          (context, state) =>
              EditTeacherPage(teacherId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/admin/assignments',
      builder: (context, state) => const AssignmentsListPage(),
    ),
    GoRoute(
      path: '/admin/assignments/add',
      builder: (context, state) => const AddAssignmentPage(),
    ),
    GoRoute(
      path: '/admin/assignments/edit/:id',
      builder:
          (context, state) =>
              EditAssignmentPage(assignmentId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/admin/reports',
      builder: (context, state) => const ReportsPage(),
    ),
    GoRoute(
      path: '/admin/subjects',
      builder: (context, state) => const SubjectsListPage(),
    ),
    GoRoute(
      path: '/admin/subjects/add',
      builder: (context, state) => const AddSubjectPage(),
    ),
    GoRoute(
      path: '/admin/subjects/edit/:id',
      builder:
          (context, state) =>
              EditSubjectPage(subjectId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/admin/subjects/assign/:id',
      builder:
          (context, state) =>
              AssignSubjectPage(subjectId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/student', builder: (context, state) => const StudentPage()),
    GoRoute(path: '/teacher', builder: (context, state) => const TeacherPage()),
    GoRoute(
      path: '/admin/schedule',
      builder: (context, state) => const ScheduleListPage(),
    ),
    GoRoute(
      path: '/admin/schedule/add',
      builder: (context, state) => const AddSchedulePage(),
    ),
    GoRoute(
      path: '/admin/schedule/edit/:id',
      builder:
          (context, state) =>
              EditSchedulePage(scheduleId: state.pathParameters['id']!),
    ),
    // Teacher section routes
    GoRoute(
      path: '/teacher/subject-year',
      builder: (context, state) => const SubjectsPage(),
    ),
    GoRoute(
      path: '/teacher/students/:classId',
      builder: (context, state) => const StudentsPage(),
    ),
    GoRoute(
      path: '/teacher/assignments',
      builder: (context, state) => const AssignmentsPage(),
    ),
    GoRoute(
      path: '/teacher/assignments/add',
      builder: (context, state) => const AddAssignmentTeachersPage(),
    ),
    GoRoute(
      path: '/teacher/attendance/:classId',
      builder: (context, state) => const AttendancePage(),
    ),
    GoRoute(
      path: '/teacher/grades',
      builder: (context, state) => const GradesPage(),
    ),
    GoRoute(
      path: '/teacher/schedule/:classId',
      builder: (context, state) => const SchedulePage(),
    ),
  ],
);
