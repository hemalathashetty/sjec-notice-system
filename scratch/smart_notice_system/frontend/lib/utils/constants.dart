class Constants {
  // Your backend URL
  static const String baseUrl = 'http://127.0.0.1:8000';
  
  // API endpoints
  static const String loginUrl = '$baseUrl/auth/login';
  static const String registerUrl = '$baseUrl/auth/register';
  static const String meUrl = '$baseUrl/auth/me';
  static const String dashboardUrl = '$baseUrl/superadmin/dashboard';
  static const String noticesUrl = '$baseUrl/notices';
  static const String myNoticesUrl = '$baseUrl/notices/my-notices';
  static const String postNoticeUrl = '$baseUrl/notices/post';
  static const String usersUrl = '$baseUrl/superadmin/users';
  static const String addUserUrl = '$baseUrl/superadmin/add-user';
  static const String studentsUrl = '$baseUrl/superadmin/students';
  static const String chatbotUrl = '$baseUrl/chatbot/ask';

  // College info
  static const String collegeName = 'SJEC';
  static const String collegeFullName = 'St Joseph Engineering College';
  static const String appName = 'SJEC Notice Board';

  // Roles
  static const String roleSuperAdmin = 'super_admin';
  static const String roleAdmin = 'admin';
  static const String roleHod = 'hod';
  static const String rolePlacement = 'placement_cell';
  static const String roleClub = 'club_coordinator';
  static const String roleSports = 'sports_coordinator';
  static const String roleStudent = 'student';

  // Departments
  static const List<String> departments = [
    'CSE', 'CSBS', 'CSDS', 'AIML',
    'EEE', 'EC', 'ME', 'CIVIL', 'MBA', 'MCA'
  ];

  // Years
  static const List<String> ugYears = ['UG1', 'UG2', 'UG3', 'UG4'];
  static const List<String> pgYears = ['PG1', 'PG2'];

  // Categories
  static const List<Map<String, String>> categories = [
    {'value': 'exam', 'label': 'Exams'},
    {'value': 'event', 'label': 'Events & Fests'},
    {'value': 'placement', 'label': 'Placement'},
    {'value': 'sports', 'label': 'Sports'},
    {'value': 'club', 'label': 'Clubs'},
    {'value': 'class committee meeting', 'label': 'Class Committee'},
    {'value': 'workshop', 'label': 'Workshop'},
    {'value': 'interview', 'label': 'Interview'},
    {'value': 'webinar', 'label': 'Webinar'},
    {'value': 'hackathon', 'label': 'Hackathon'},
    {'value': 'competition', 'label': 'Competition'},
    {'value': 'training program', 'label': 'Training Program'},
    {'value': 'scholarship', 'label': 'Scholarship'},
    {'value': 'general', 'label': 'General'},
  ];
}