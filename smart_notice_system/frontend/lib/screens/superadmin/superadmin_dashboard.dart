import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../utils/colors.dart';
import '../../utils/constants.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/notice_model.dart';
import '../../models/user_model.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _selectedIndex = 0;
  Map<String, dynamic> _dashboardData = {};
  List<NoticeModel> _notices = [];
  List<UserModel> _users = [];
  bool _isLoading = true;
  String _adminName = '';
  int _currentUserId = 0;

  // ── Hierarchical student browser state ──────────────────
  String? _selectedYear;       // e.g. 'UG1'
  String? _selectedDept;       // e.g. 'CSE'

  // ── Notices sub-tab ───────────────────────────────────────
  int _noticesSubTab = 0; // 0 = All Notices, 1 = My Notices
  List<UserModel> _classStudents = [];
  bool _studentsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final userInfo = await ApiService.getUserInfo();
    final userId = await ApiService.getUserId();
    setState(() {
      _adminName = userInfo['full_name'] ?? 'Super Admin';
      _currentUserId = int.tryParse(userId ?? '0') ?? 0;
});

    final dashResult = await ApiService.getDashboard();
    if (dashResult['success']) {
      setState(() => _dashboardData = dashResult['data']);
    }

    final noticeResult = await ApiService.getAllNotices();
    if (noticeResult['success']) {
      setState(() {
        _notices = (noticeResult['data'] as List)
            .map((n) => NoticeModel.fromJson(n))
            .toList();
      });
    }

    final userResult = await ApiService.getAllUsers();
    if (userResult['success']) {
      setState(() {
        _users = (userResult['data'] as List)
            .map((u) => UserModel.fromJson(u))
            .toList();
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          _buildNavBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: _buildBody(),
                  ),
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => _showAddUserDialog(),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: Text(
                'Add User',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D1642), Color(0xFF1A237E), Color(0xFF3949AB)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                    Text(
                      _adminName,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBar() {
    final tabs = [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard'},
      {'icon': Icons.people_rounded, 'label': 'Users'},
      {'icon': Icons.notifications_rounded, 'label': 'Notices'},
      {'icon': Icons.add_circle_rounded, 'label': 'Post Notice'},
    ];

    return Container(
      color: AppColors.primary,
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = _selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      tab['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.white38,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tab['label'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isSelected ? Colors.white : Colors.white38,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0: return _buildDashboardTab();
      case 1: return _buildUsersTab();
      case 2: return _buildNoticesTab();
      case 3: return _buildPostNoticeTab();
      default: return _buildDashboardTab();
    }
  }

  Widget _buildDashboardTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _buildStatCard('Total Users',
                '${_dashboardData['total_users'] ?? 0}',
                Icons.people_rounded, AppColors.primary),
            const SizedBox(width: 12),
            _buildStatCard('Students',
                '${_dashboardData['total_students'] ?? 0}',
                Icons.school_rounded, AppColors.studentColor),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard('Admins',
                '${_dashboardData['total_admins'] ?? 0}',
                Icons.manage_accounts_rounded, AppColors.adminColor),
            const SizedBox(width: 12),
            _buildStatCard('Notices',
                '${_dashboardData['total_notices'] ?? 0}',
                Icons.notifications_rounded, AppColors.warning),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'Students per Department',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...(_dashboardData['students_per_department'] as List? ?? [])
            .map((dept) => _buildDeptCard(dept))
            .toList(),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeptCard(Map<String, dynamic> dept) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              dept['department'] ?? '',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: LinearProgressIndicator(
              value: (dept['students'] ?? 0) /
                  ((_dashboardData['total_students'] ?? 1) == 0
                      ? 1
                      : _dashboardData['total_students']),
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${dept['students']}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Load students for selected year + dept ──────────────
  Future<void> _loadClassStudents(String year, String dept) async {
    setState(() {
      _selectedYear = year;
      _selectedDept = dept;
      _studentsLoading = true;
      _classStudents = [];
    });
    final result = await ApiService.getStudents(year: year, department: dept);
    if (result['success']) {
      setState(() {
        _classStudents = (result['data'] as List)
            .map((u) => UserModel.fromJson(u))
            .toList();
      });
    }
    setState(() => _studentsLoading = false);
  }

  // ── Delete one student ───────────────────────────────────
  void _confirmDeleteStudent(UserModel student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Student',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Remove this student from the system?',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(student.fullName,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppColors.error)),
                  Text(student.email,
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await ApiService.deleteUser(student.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      result['success']
                          ? 'Student deleted successfully'
                          : result['message'] ?? 'Error',
                      style: GoogleFonts.poppins()),
                  backgroundColor: result['success']
                      ? AppColors.success
                      : AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ));
                if (result['success'] && _selectedYear != null &&
                    _selectedDept != null) {
                  _loadClassStudents(_selectedYear!, _selectedDept!);
                  _loadData();
                }
              }
            },
            child: Text('Delete',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Delete ALL students in a class ───────────────────────
  void _confirmDeleteAll(String year, String dept) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete All Students',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: AppColors.error)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 48),
            const SizedBox(height: 12),
            Text(
              'Delete ALL ${_classStudents.length} students from $year — $dept?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text('This cannot be undone.',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.error,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final result =
                  await ApiService.deleteStudentsBatch(year, dept);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      result['success']
                          ? 'All students deleted'
                          : result['message'] ?? 'Error',
                      style: GoogleFonts.poppins()),
                  backgroundColor: result['success']
                      ? AppColors.success
                      : AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ));
                if (result['success']) {
                  setState(() {
                    _classStudents = [];
                    _selectedDept = null;
                  });
                  _loadData();
                }
              }
            },
            child: Text('Delete All',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Promote ALL students in a class ─────────────────────
  void _confirmPromote(String year, String dept) {
    final nextYearMap = {
      'UG1': 'UG2', 'UG2': 'UG3', 'UG3': 'UG4',
      'UG4': 'Graduate', 'PG1': 'PG2', 'PG2': 'Graduate',
    };
    final nextYear = nextYearMap[year] ?? 'next year';
    final isGraduating = nextYear == 'Graduate';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isGraduating
                  ? Icons.school_rounded
                  : Icons.arrow_upward_rounded,
              color: isGraduating ? Colors.amber : AppColors.success,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              isGraduating ? 'Graduate Class' : 'Promote Class',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: isGraduating ? Colors.amber.shade800 : AppColors.success),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isGraduating)
              const Icon(Icons.emoji_events_rounded,
                  color: Colors.amber, size: 48),
            const SizedBox(height: 8),
            Text(
              isGraduating
                  ? 'All ${_classStudents.length} students in $year — $dept will be marked as Graduated and their accounts will be deactivated.'
                  : 'Promote all ${_classStudents.length} students\n$year → $nextYear  ($dept)?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: AppColors.textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isGraduating ? Colors.amber.shade700 : AppColors.success,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final result =
                  await ApiService.promoteStudents(year, dept);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      result['success']
                          ? (result['data']?['message'] ??
                              'Promotion successful')
                          : result['message'] ?? 'Error',
                      style: GoogleFonts.poppins()),
                  backgroundColor: result['success']
                      ? AppColors.success
                      : AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ));
                if (result['success']) {
                  // Reload current class (now empty or next year)
                  _loadClassStudents(year, dept);
                  _loadData();
                }
              }
            },
            child: Text(
              isGraduating ? 'Graduate' : 'Promote',
              style: GoogleFonts.poppins(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── MAIN USERS TAB ───────────────────────────────────────
  Widget _buildUsersTab() {
    // Show non-student staff first (admins, hods, etc.)
    final staffUsers =
        _users.where((u) => u.role != 'student').toList();

    final allYears = [
      ...Constants.ugYears.map((y) =>
          {'label': y.replaceAll('UG', '') + (y.startsWith('UG') ? ' (UG)' : ' (PG)'), 'value': y}),
      ...Constants.pgYears.map((y) =>
          {'label': y.replaceAll('PG', 'PG '), 'value': y}),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Staff / Admin section ──────────────────────────
        if (staffUsers.isNotEmpty) ...[
          _sectionHeader('Staff & Admin Users',
              Icons.manage_accounts_rounded, AppColors.primary),
          const SizedBox(height: 8),
          ...staffUsers.map(_buildUserCard).toList(),
          const SizedBox(height: 20),
        ],

        // ── Student browser ────────────────────────────────
        _sectionHeader(
            'Student Browser', Icons.school_rounded, AppColors.studentColor),
        const SizedBox(height: 12),

        // Year chips
        Text('Select Year:',
            style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ...Constants.ugYears.map((yr) => _yearChip(yr, 'UG')),
            ...Constants.pgYears.map((yr) => _yearChip(yr, 'PG')),
          ],
        ),

        // Branch chips — appear after year selected
        if (_selectedYear != null) ...[
          const SizedBox(height: 16),
          Text('Select Branch:',
              style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Constants.departments
                .map((dept) => _deptChip(dept))
                .toList(),
          ),
        ],

        // Students list — appears after branch selected
        if (_selectedYear != null && _selectedDept != null) ...[
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.studentColor.withOpacity(0.12),
                  AppColors.studentColor.withOpacity(0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.studentColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.group_rounded,
                    color: AppColors.studentColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  '$_selectedYear  •  $_selectedDept  — ${_classStudents.length} student${_classStudents.length != 1 ? 's' : ''}',
                  style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.studentColor),
                ),
                const Spacer(),
                if (_classStudents.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () => _confirmPromote(
                        _selectedYear!, _selectedDept!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.success.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_upward_rounded,
                              size: 14, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text('Promote All',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _confirmDeleteAll(
                        _selectedYear!, _selectedDept!),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.error.withOpacity(0.35)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep_rounded,
                              size: 14, color: AppColors.error),
                          const SizedBox(width: 4),
                          Text('Delete All',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (_studentsLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary)),
            )
          else if (_classStudents.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No students in this class',
                  style: GoogleFonts.poppins(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
            )
          else
            ..._classStudents
                .map((s) => _buildStudentCard(s))
                .toList(),
        ],

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color)),
      ],
    );
  }

  Widget _yearChip(String year, String type) {
    final isSelected = _selectedYear == year;
    final label = type == 'UG'
        ? year.replaceAll('UG', '') + {'UG1': 'st', 'UG2': 'nd', 'UG3': 'rd', 'UG4': 'th'}[year]! + ' Year'
        : year.replaceAll('PG', 'PG ') + ' Year';
    return GestureDetector(
      onTap: () => setState(() {
        _selectedYear = year;
        _selectedDept = null;
        _classStudents = [];
      }),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.primary.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _deptChip(String dept) {
    final isSelected = _selectedDept == dept;
    return GestureDetector(
      onTap: () => _loadClassStudents(_selectedYear!, dept),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.studentColor
              : AppColors.studentColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isSelected
                  ? AppColors.studentColor
                  : AppColors.studentColor.withOpacity(0.3)),
        ),
        child: Text(
          dept,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : AppColors.studentColor,
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(UserModel student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.studentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                student.fullName[0].toUpperCase(),
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.studentColor),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.fullName,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text(student.email,
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: student.isActive
                  ? AppColors.success
                  : Colors.grey.shade300,
            ),
          ),
          GestureDetector(
            onTap: () => _confirmDeleteStudent(student),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Icon(Icons.delete_outline_rounded,
                  size: 16, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    Color roleColor = _getRoleColor(user.role);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(user.fullName[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: roleColor)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.fullName,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                Text(user.email,
                    style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(user.roleDisplay,
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: roleColor)),
                    ),
                    if (user.department != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(user.department!,
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.info)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Switch(
            value: user.isActive,
            onChanged: (val) async {
              await ApiService.toggleUserStatus(user.id);
              _loadData();
            },
            activeColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildNoticesTab() {
    final myNotices = _notices
        .where((n) => n.postedById == _currentUserId)
        .toList();
    final allNotices = _notices
        .where((n) => !n.isPostedBySuperAdmin)
        .toList();

    final displayList =
        _noticesSubTab == 0 ? allNotices : myNotices;

    return Column(
      children: [
        // ── Sub-tab bar ───────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              _noticeSubTabBtn(
                label: 'All Notices',
                icon: Icons.list_alt_rounded,
                index: 0,
                count: allNotices.length,
              ),
              _noticeSubTabBtn(
                label: 'My Notices',
                icon: Icons.admin_panel_settings_rounded,
                index: 1,
                count: myNotices.length,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // ── Notice list ───────────────────────────────────
        Expanded(
          child: displayList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none_rounded,
                          size: 70, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        _noticesSubTab == 0
                            ? 'No notices posted yet'
                            : 'You have not posted any notices yet',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  itemCount: displayList.length,
                  itemBuilder: (ctx, i) =>
                      _buildNoticeCard(displayList[i]),
                ),
        ),
      ],
    );
  }

  Widget _noticeSubTabBtn({
    required String label,
    required IconData icon,
    required int index,
    required int count,
  }) {
    final isSelected = _noticesSubTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _noticesSubTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              bottom: BorderSide(
                color:
                    isSelected ? AppColors.primary : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isSelected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color:
                        isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeCard(NoticeModel notice) {
  return GestureDetector(
    onTap: () => _showNoticeDetail(notice),
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: notice.isUrgent
                  ? LinearGradient(colors: [
                      AppColors.error.withOpacity(0.1),
                      AppColors.warning.withOpacity(0.1),
                    ])
                  : LinearGradient(colors: [
                      AppColors.primary.withOpacity(0.05),
                      AppColors.primaryLight.withOpacity(0.05),
                    ]),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    notice.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (notice.isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'URGENT',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Summary
          if (notice.summary != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Text(
                notice.summary!,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Posted by
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: notice.isPostedBySuperAdmin
                        ? AppColors.superAdminColor.withOpacity(0.1)
                        : AppColors.adminColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        notice.isPostedBySuperAdmin
                            ? Icons.admin_panel_settings_rounded
                            : Icons.manage_accounts_rounded,
                        size: 12,
                        color: notice.isPostedBySuperAdmin
                            ? AppColors.superAdminColor
                            : AppColors.adminColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
  notice.postedById == _currentUserId
      ? 'Posted by: Me'
      : 'Posted by: ${notice.postedByName ?? "Unknown"} (${_getPostedByLabel(notice.postedByRole ?? "")})',
  style: GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: notice.isPostedBySuperAdmin
        ? AppColors.superAdminColor
        : AppColors.adminColor,
  ),
),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (notice.department != null)
                      _buildTag(notice.department!, AppColors.primary),
                    if (notice.year != null) ...[
                      const SizedBox(width: 6),
                      _buildTag(notice.year!, AppColors.info),
                    ],
                    if (notice.isGeneral) ...[
                      const SizedBox(width: 6),
                      _buildTag('General', AppColors.success),
                    ],
                    if (notice.fileType != null) ...[
                      const SizedBox(width: 6),
                      _buildTag(
                        notice.fileType!.contains('pdf') ? 'PDF' : 'File',
                        AppColors.warning,
                      ),
                    ],
                    const Spacer(),
                    if (notice.hasDueDate)
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            notice.dueDate!.substring(0, 10),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.warning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                const SizedBox(height: 4),
Row(
  children: [
    Text(
      'Tap to view full notice',
      style: GoogleFonts.poppins(
        fontSize: 10,
        color: Colors.grey.shade400,
      ),
    ),
    const Spacer(),
    GestureDetector(
      onTap: () => _confirmDelete(notice),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.delete_outline_rounded,
              size: 14,
              color: AppColors.error,
            ),
            const SizedBox(width: 4),
            Text(
              'Delete',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    ),
  ],
),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPostNoticeTab() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    List<String> selectedYears = [];
    List<String> selectedDepts = [];
    bool isGeneral = false;
    bool isPosting = false;
    PlatformFile? selectedFile;
    String? selectedCategory;

    return StatefulBuilder(
      builder: (context, setTabState) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Post New Notice',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'As Super Admin you can post to any department',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                TextField(
                  controller: titleController,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Notice Title',
                    prefixIcon: const Icon(Icons.title_rounded,
                        color: AppColors.primary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Content
                TextField(
                  controller: contentController,
                  maxLines: 5,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Notice Content',
                    alignLabelWithHint: true,
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 80),
                      child: Icon(Icons.description_outlined,
                          color: AppColors.primary),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  style: GoogleFonts.poppins(
                      fontSize: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Notice Category',
                    prefixIcon: const Icon(Icons.category_rounded,
                        color: AppColors.primary),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 2),
                    ),
                  ),
                  items: [
                    {'value': 'exam',      'label': '📝 Exam'},
                    {'value': 'event',     'label': '🎉 Event'},
                    {'value': 'placement', 'label': '💼 Placement'},
                    {'value': 'sports',    'label': '🏅 Sports'},
                    {'value': 'club',      'label': '🎭 Club'},
                    {'value': 'general',   'label': '📢 General'},
                  ].map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat['value'],
                      child: Text(cat['label']!),
                    );
                  }).toList(),
                  onChanged: (val) =>
                      setTabState(() => selectedCategory = val),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.business_rounded,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Target Departments',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'CSE', 'CSBS', 'CSDS', 'AIML',
                          'EEE', 'EC', 'ME', 'CIVIL', 'MBA', 'MCA'
                        ].map((dept) {
                          final isSelected = selectedDepts.contains(dept);
                          return GestureDetector(
                            onTap: () => setTabState(() {
                              if (isSelected) {
                                selectedDepts.remove(dept);
                              } else {
                                selectedDepts.add(dept);
                              }
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                dept,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Multi-select Years
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.school_rounded,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Target Years',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'UG1', 'UG2', 'UG3', 'UG4', 'PG1', 'PG2'
                        ].map((year) {
                          final isSelected = selectedYears.contains(year);
                          return GestureDetector(
                            onTap: () => setTabState(() {
                              if (isSelected) {
                                selectedYears.remove(year);
                              } else {
                                selectedYears.add(year);
                              }
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Text(
                                year,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // General toggle
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.public_rounded,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'General Notice',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Visible to all students',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isGeneral,
                        onChanged: (val) =>
                            setTabState(() => isGeneral = val),
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // File upload
                GestureDetector(
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: [
                        'pdf', 'jpg', 'jpeg', 'png',
                        'ppt', 'pptx', 'doc', 'docx'
                      ],
                      withData: true,
                    );
                    if (result != null) {
                      setTabState(() => selectedFile = result.files.first);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedFile != null
                            ? AppColors.success
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: selectedFile != null
                          ? AppColors.success.withOpacity(0.05)
                          : Colors.grey.shade50,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedFile != null
                              ? Icons.check_circle_rounded
                              : Icons.upload_file_rounded,
                          color: selectedFile != null
                              ? AppColors.success
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedFile != null
                                    ? selectedFile!.name
                                    : 'Upload File (optional)',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: selectedFile != null
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                  fontWeight: selectedFile != null
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'PDF, Image, PPT, Word supported',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (selectedFile != null)
                          GestureDetector(
                            onTap: () =>
                                setTabState(() => selectedFile = null),
                            child: const Icon(Icons.close_rounded,
                                color: AppColors.error, size: 20),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Post button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isPosting
                        ? null
                        : () async {
                            if (titleController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a title'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                              return;
                            }
                            setTabState(() => isPosting = true);

                            final formData = FormData.fromMap({
                              'title': titleController.text,
                              'content': contentController.text,
                              'department': selectedDepts.isNotEmpty
                                  ? selectedDepts.first
                                  : null,
                              'year': selectedYears.isNotEmpty
                                  ? selectedYears.first
                                  : null,
                              'target_years': selectedYears.join(','),
                              'target_departments': selectedDepts.join(','),
                              'category': selectedCategory,
                              'is_general': isGeneral.toString(),
                              if (selectedFile != null &&
                                  selectedFile!.bytes != null)
                                'file': MultipartFile.fromBytes(
                                  selectedFile!.bytes!,
                                  filename: selectedFile!.name,
                                ),
                            });

                            final result =
                                await ApiService.postNotice(formData);
                            setTabState(() => isPosting = false);

                            if (mounted) {
                              if (result['success']) {
                                titleController.clear();
                                contentController.clear();
                                setTabState(() {
                                  selectedYears = [];
                                  selectedDepts = [];
                                  isGeneral = false;
                                  selectedFile = null;
                                });
                                _loadData();
                                // Show ATCD analysis screen
                                _showAtcdAnalysis(result['data'] ?? {});
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message']),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                    child: isPosting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            'Post Notice',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  void _showNoticeDetail(NoticeModel notice) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: notice.isPostedBySuperAdmin
                  ? LinearGradient(colors: [
                      AppColors.superAdminColor.withOpacity(0.1),
                      AppColors.primary.withOpacity(0.1),
                    ])
                  : LinearGradient(colors: [
                      AppColors.adminColor.withOpacity(0.1),
                      AppColors.info.withOpacity(0.1),
                    ]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notice.title,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (notice.isUrgent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'URGENT',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                // Posted by badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: notice.isPostedBySuperAdmin
                        ? AppColors.superAdminColor.withOpacity(0.15)
                        : AppColors.adminColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        notice.isPostedBySuperAdmin
                            ? Icons.admin_panel_settings_rounded
                            : Icons.manage_accounts_rounded,
                        size: 14,
                        color: notice.isPostedBySuperAdmin
                            ? AppColors.superAdminColor
                            : AppColors.adminColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        notice.postedById == _currentUserId
                        ? 'Posted by: Me'
                        : 'Posted by: ${notice.postedByName ?? "Unknown"} (${_getPostedByLabel(notice.postedByRole ?? "")})',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: notice.isPostedBySuperAdmin
                              ? AppColors.superAdminColor
                              : AppColors.adminColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (notice.department != null)
                      _buildTag(notice.department!, AppColors.primary),
                    if (notice.year != null) ...[
                      const SizedBox(width: 6),
                      _buildTag(notice.year!, AppColors.info),
                    ],
                    if (notice.isGeneral) ...[
                      const SizedBox(width: 6),
                      _buildTag('General', AppColors.success),
                    ],
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // AI Summary pointwise
                  if (notice.summary != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'AI Generated Summary',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...notice.summary!.split(' | ').map((point) {
                            final isDeadline = point.toLowerCase().startsWith('deadline');
                            final isDate = point.toLowerCase().startsWith('date');
                            final isEvent = point.toLowerCase().startsWith('event');
                            final isVenue = point.toLowerCase().startsWith('venue');
                            final isTime = point.toLowerCase().startsWith('time');

                            IconData icon = Icons.circle;
                            if (isDeadline) icon = Icons.alarm_rounded;
                            else if (isDate) icon = Icons.calendar_today_rounded;
                            else if (isEvent) icon = Icons.event_rounded;
                            else if (isVenue) icon = Icons.location_on_rounded;
                            else if (isTime) icon = Icons.access_time_rounded;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(icon, color: Colors.white, size: 14),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      point.trim(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.95),
                                        height: 1.5,
                                        fontWeight: isDeadline || isDate
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Due date
                  if (notice.hasDueDate) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: notice.isUrgent
                            ? AppColors.error.withOpacity(0.08)
                            : AppColors.warning.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: notice.isUrgent
                              ? AppColors.error.withOpacity(0.3)
                              : AppColors.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.alarm_rounded,
                            color: notice.isUrgent
                                ? AppColors.error
                                : AppColors.warning,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notice.isUrgent ? 'Deadline is near!' : 'Due Date',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: notice.isUrgent
                                      ? AppColors.error
                                      : AppColors.warning,
                                ),
                              ),
                              Text(
                                notice.dueDate!.substring(0, 10),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: notice.isUrgent
                                      ? AppColors.error
                                      : AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // File attachment
                  if (notice.hasFile) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                notice.isPdf
                                    ? Icons.picture_as_pdf_rounded
                                    : notice.isImage
                                        ? Icons.image_rounded
                                        : Icons.attach_file_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      notice.isPdf
                                          ? 'PDF Attachment'
                                          : notice.isImage
                                              ? 'Image Attachment'
                                              : 'File Attachment',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                    Text(
                                      notice.filePath!.split('/').last,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (notice.isImage) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                notice.fileUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) =>
                                    const Text('Image could not be loaded'),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {
                                html.window.open(notice.fileUrl, '_blank');
                              },
                              icon: const Icon(Icons.download_rounded, color: Colors.white),
                              label: Text(
                                notice.isPdf ? 'View / Download PDF' : 'Download File',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Full content
                  if (notice.content != null && notice.content!.isNotEmpty) ...[
                    Text(
                      'Full Notice',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        notice.content!,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.7,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
} 
  void _confirmDelete(NoticeModel notice) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Delete Notice',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to delete this notice?',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.error.withOpacity(0.2),
              ),
            ),
            child: Text(
              notice.title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This will remove the notice for all students and admins.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () async {
            Navigator.pop(context);
            final result = await ApiService.deleteNotice(notice.id);
            if (mounted) {
              if (result['success']) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Notice deleted successfully!',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
                _loadData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result['message'] ?? 'Failed to delete',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            }
          },
          child: Text(
            'Delete',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
  String _getPostedByLabel(String role) {
  switch (role) {
    case 'super_admin': return 'Super Admin';
    case 'admin': return 'Admin';
    case 'hod': return 'HOD';
    case 'placement_cell': return 'Placement Cell';
    case 'club_coordinator': return 'Club Coordinator';
    case 'sports_coordinator': return 'Sports Coordinator';
    default: return role;
  }
}
  Color _getRoleColor(String role) {
    switch (role) {
      case 'super_admin': return AppColors.superAdminColor;
      case 'admin': return AppColors.adminColor;
      case 'hod': return AppColors.hodColor;
      case 'placement_cell': return AppColors.placementColor;
      case 'club_coordinator': return AppColors.clubColor;
      case 'sports_coordinator': return AppColors.sportsColor;
      case 'student': return AppColors.studentColor;
      default: return AppColors.primary;
    }
  }

  void _showAddUserDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'admin';
    String? selectedDept;
    String? selectedYear;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Add New User',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'name@sjec.ac.in',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: GoogleFonts.poppins(fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [
                    'admin', 'hod', 'placement_cell',
                    'club_coordinator', 'sports_coordinator', 'student'
                  ].map((role) => DropdownMenuItem(
                    value: role,
                    child: Text(role,
                        style: GoogleFonts.poppins(fontSize: 14)),
                  )).toList(),
                  onChanged: (val) =>
                      setModalState(() => selectedRole = val!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedDept,
                  decoration: InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: [
                    'CSE', 'CSBS', 'CSDS', 'AIML',
                    'EEE', 'EC', 'ME', 'CIVIL', 'MBA', 'MCA'
                  ].map((dept) => DropdownMenuItem(
                    value: dept,
                    child: Text(dept,
                        style: GoogleFonts.poppins(fontSize: 14)),
                  )).toList(),
                  onChanged: (val) =>
                      setModalState(() => selectedDept = val),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedYear,
                  decoration: InputDecoration(
                    labelText: 'Year (for students)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ['UG1', 'UG2', 'UG3', 'UG4', 'PG1', 'PG2']
                      .map((year) => DropdownMenuItem(
                    value: year,
                    child: Text(year,
                        style: GoogleFonts.poppins(fontSize: 14)),
                  )).toList(),
                  onChanged: (val) =>
                      setModalState(() => selectedYear = val),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final result = await ApiService.addUser({
                        'full_name': nameController.text,
                        'email': emailController.text,
                        'password': passwordController.text,
                        'role': selectedRole,
                        'department': selectedDept,
                        'year': selectedYear,
                      });
                      if (mounted) {
                        Navigator.pop(context);
                        if (result['success']) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('User added successfully!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                          _loadData();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message']),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                    child: Text(
                      'Add User',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── ATCD ANALYSIS BOTTOM SHEET ────────────────────────────────────────────
  void _showAtcdAnalysis(Map<String, dynamic> data) {
    final atcd = Map<String, dynamic>.from(data['atcd_analysis'] ?? {});
    final summary = (data['summary'] ?? '') as String;
    final title  = (data['title'] ?? 'Notice') as String;
    final autoCategory    = (data['auto_category'] ?? 'general') as String;
    final categoryWasAuto = (data['category_was_auto'] ?? false) as bool;

    final tokens      = List<String>.from(atcd['tokens'] ?? []);
    final dates       = List<String>.from(atcd['dates_found'] ?? []);
    final depts       = List<String>.from(atcd['mentioned_departments'] ?? []);
    final years       = List<String>.from(atcd['mentioned_years'] ?? []);
    final wordCount   = (atcd['word_count'] ?? 0) as int;
    final eventType   = (atcd['event_type'] ?? 'general') as String;
    final hasDeadline = (atcd['has_deadline'] ?? false) as bool;
    final dueDate     = atcd['due_date'] as String?;

    final classifiedRaw = List<dynamic>.from(atcd['classified_tokens'] ?? []);
    final Map<String, String> tokenClassMap = {};
    for (final ct in classifiedRaw) {
      tokenClassMap[ct['token'] as String] = ct['class'] as String;
    }
    final classColorMap = <String, Color>{
      'DATE':     const Color(0xFF2196F3),
      'TIME':     const Color(0xFF9C27B0),
      'EVENT':    const Color(0xFFFF9800),
      'DEADLINE': const Color(0xFFF44336),
      'VENUE':    const Color(0xFF4CAF50),
      'DEPT':     const Color(0xFF795548),
      'PERSON':   const Color(0xFF00BCD4),
      'LINK':     const Color(0xFF607D8B),
      'KEYWORD':  const Color(0xFF9E9E9E),
      'YEAR':     const Color(0xFF7B1FA2),
    };
    Color chipColor(String t) =>
        classColorMap[tokenClassMap[t] ?? 'KEYWORD'] ?? const Color(0xFF9E9E9E);
    String chipClass(String t) => tokenClassMap[t] ?? 'KEYWORD';

    // Legacy color refs used by deadline banner + detail rows
    const kDateColor = Color(0xFFD32F2F);
    const kDeptColor = Color(0xFF1565C0);
    const kYearColor = Color(0xFF7B1FA2);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0D1B2A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00E5FF), Color(0xFF1565C0)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_graph_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ATCD Analysis',
                            style: GoogleFonts.poppins(
                                fontSize: 18, fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        Text('Adaptive Token Classification & Detection',
                            style: GoogleFonts.poppins(
                                fontSize: 10, color: Colors.white38)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _selectedIndex = 2);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white54, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('✅  "$title" posted successfully',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: const Color(0xFF69F0AE),
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),

              // Stats row
              Row(
                children: [
                  _atcdStat('Tokens\nFound',   '${tokens.length}',  const Color(0xFF00E5FF)),
                  const SizedBox(width: 10),
                  _atcdStat('Dates\nDetected', '${dates.length}',   kDateColor),
                  const SizedBox(width: 10),
                  _atcdStat('Word\nCount',      '$wordCount',         const Color(0xFF69F0AE)),
                  const SizedBox(width: 10),
                  _atcdStat('Event\nType',      eventType.toUpperCase(), const Color(0xFFFFD740)),
                ],
              ),
              const SizedBox(height: 20),

              // Deadline
              if (hasDeadline)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: kDateColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kDateColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.alarm_rounded, color: kDateColor, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Deadline detected: ${dueDate ?? dates.join(', ')}',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: kDateColor),
                      ),
                    ],
                  ),
                ),

              // ── Auto-Category Banner ──
              if (categoryWasAuto)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF00E676).withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_fix_high_rounded, color: Color(0xFF00E676), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Auto-Detected: ${autoCategory.toUpperCase()}  (ATCD DFA)',
                          style: GoogleFonts.poppins(fontSize: 12,
                              fontWeight: FontWeight.w600, color: const Color(0xFF00E676)),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Legend (8 classes) ──
              Wrap(
                spacing: 10, runSpacing: 6,
                children: [
                  _legendChip('DATE',     const Color(0xFF2196F3)),
                  _legendChip('TIME',     const Color(0xFF9C27B0)),
                  _legendChip('EVENT',    const Color(0xFFFF9800)),
                  _legendChip('DEADLINE', const Color(0xFFF44336)),
                  _legendChip('VENUE',    const Color(0xFF4CAF50)),
                  _legendChip('DEPT',     const Color(0xFF795548)),
                  _legendChip('PERSON',   const Color(0xFF00BCD4)),
                  _legendChip('KEYWORD',  const Color(0xFF9E9E9E)),
                ],
              ),
              const SizedBox(height: 16),

              // Token chips
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.token_rounded,
                            color: Color(0xFF00E5FF), size: 16),
                        const SizedBox(width: 6),
                        Text('Extracted Tokens',
                            style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    tokens.isEmpty
                        ? Text('No tokens extracted.',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.white38))
                        : Wrap(
                            spacing: 8, runSpacing: 10,
                            children: tokens.map((t) {
                              final c = chipColor(t);
                              final cls = chipClass(t);
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: c.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: c.withOpacity(0.6), width: 1.2),
                                    ),
                                    child: Text(t,
                                        style: GoogleFonts.robotoMono(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: c)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(cls,
                                      style: GoogleFonts.poppins(
                                          fontSize: 8,
                                          color: c.withOpacity(0.8),
                                          fontWeight: FontWeight.w700)),
                                ],
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (depts.isNotEmpty) ...[
                _atcdDetailRow(icon: Icons.business_rounded, color: kDeptColor,
                    label: 'Departments Detected', items: depts),
                const SizedBox(height: 12),
              ],
              if (years.isNotEmpty) ...[
                _atcdDetailRow(icon: Icons.school_rounded, color: kYearColor,
                    label: 'Academic Years Detected', items: years),
                const SizedBox(height: 12),
              ],
              if (dates.isNotEmpty) ...[
                _atcdDetailRow(icon: Icons.calendar_today_rounded,
                    color: kDateColor, label: 'Dates Found', items: dates),
                const SizedBox(height: 12),
              ],

              // AI Summary
              if (summary.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.primary.withOpacity(0.3),
                      AppColors.primary.withOpacity(0.1),
                    ]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome_rounded,
                              color: Color(0xFF00E5FF), size: 16),
                          const SizedBox(width: 6),
                          Text('AI Summary',
                              style: GoogleFonts.poppins(
                                  fontSize: 13, fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...summary.split(' | ').map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('•  ',
                                    style: TextStyle(
                                        color: Colors.white54, fontSize: 12)),
                                Expanded(
                                  child: Text(p.trim(),
                                      style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.white70,
                                          height: 1.5)),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() => _selectedIndex = 2);
                  },
                  icon: const Icon(Icons.notifications_rounded,
                      color: Colors.white),
                  label: Text('View All Notices',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _atcdStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 9, color: Colors.white54,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _legendChip(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 10, color: Colors.white54,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _atcdDetailRow({
    required IconData icon,
    required Color color,
    required String label,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 15),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 11, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: items.map((i) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(i,
                      style: GoogleFonts.poppins(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: color)),
                )).toList(),
          ),
        ],
      ),
    );
  }
}