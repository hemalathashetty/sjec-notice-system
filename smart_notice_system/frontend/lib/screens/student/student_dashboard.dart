import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/colors.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/notice_model.dart';
import '../../utils/constants.dart';
import '../../widgets/chatbot_widget.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  List<NoticeModel> _allNotices = [];
  List<NoticeModel> _filteredNotices = [];
  bool _isLoading = true;
  String _studentName = '';
  Map<String, dynamic> _userProfile = {};
  Map<String, dynamic> _urgencyMap = {};

  // Sidebar selection
  String _selectedNav = 'all';

  // Sidebar sub-expand states
  bool _categoriesExpanded = false;

  // Search & Filter
  final _searchController = TextEditingController();
  DateTime? _filterFromDate;
  DateTime? _filterToDate;
  bool _showDatePicker = false;

  // Pagination
  int _currentPage = 1;
  static const int _perPage = 10;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final userInfo = await ApiService.getUserInfo();
    final profileRes = await ApiService.getMe();
    setState(() {
      _studentName = userInfo['full_name'] ?? 'Student';
      if (profileRes['success']) {
        _userProfile = profileRes['data'];
      }
    });

    final noticeResult = await ApiService.getMyNotices();
    if (noticeResult['success']) {
      final all = (noticeResult['data'] as List)
          .map((n) => NoticeModel.fromJson(n))
          .toList();
      setState(() {
        _allNotices = all;
      });
      _applyFilters();
    }

    // Load Deadline Urgency Map (ATCD: Timed DFA)
    final urgencyResult = await ApiService.getUrgencyMap();
    if (urgencyResult['success']) {
      setState(() {
        _urgencyMap = Map<String, dynamic>.from(urgencyResult['data'] as Map);
      });
    }

    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    List<NoticeModel> result = List.from(_allNotices);

    // Nav filter
    if (_selectedNav == 'important') {
      result = result.where((n) => n.isUrgent).toList();
    } else if (_selectedNav == 'expired') {
      result = result.where((n) => n.isDeadlinePassed).toList();
    } else if (_selectedNav == 'bookmarks') {
      // NOTE: Bookmarks logic could be added here
    } else if (_selectedNav != 'all') {
      result = result.where((n) {
        if (n.category == null) return false;
        return n.category!.toLowerCase().trim() == _selectedNav.toLowerCase().trim();
      }).toList();
    }

    // Date filter
    if (_filterFromDate != null) {
      result = result.where((n) {
        try {
          final created = DateTime.parse(n.createdAt);
          return !created.isBefore(_filterFromDate!);
        } catch (_) {
          return true;
        }
      }).toList();
    }
    if (_filterToDate != null) {
      result = result.where((n) {
        try {
          final created = DateTime.parse(n.createdAt);
          return !created.isAfter(_filterToDate!.add(const Duration(days: 1)));
        } catch (_) {
          return true;
        }
      }).toList();
    }

    // Search filter
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((n) {
        return n.title.toLowerCase().contains(query) ||
            (n.postedByName?.toLowerCase().contains(query) ?? false) ||
            (n.department?.toLowerCase().contains(query) ?? false) ||
            (n.category?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    setState(() {
      _filteredNotices = result;
      _currentPage = 1;
    });
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  List<NoticeModel> get _pagedNotices {
    final start = (_currentPage - 1) * _perPage;
    final end = (start + _perPage).clamp(0, _filteredNotices.length);
    if (start >= _filteredNotices.length) return [];
    return _filteredNotices.sublist(start, end);
  }

  int get _totalPages => (_filteredNotices.length / _perPage).ceil().clamp(1, 9999);

  List<NoticeModel> get _urgentNotices =>
      _allNotices.where((n) => n.isUrgent).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSidebar(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            )
                          : SingleChildScrollView(
                              child: _buildMainContent(),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Floating Chatbot
          Positioned(
            bottom: 24,
            right: 24,
            child: const NoticesChatbot(),
          ),
        ],
      ),
    );
  }

  // ─── SIDEBAR ────────────────────────────────────────────────────────────────
  Widget _buildSidebar() {
    return Container(
      width: 200,
      color: const Color(0xFF1565C0),
      child: Column(
        children: [
          // Logo area
          Container(
            height: 64,
            color: const Color(0xFF0D47A1),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.campaign_rounded,
                    color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SJEC Notices',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _navItem(
                  icon: Icons.home_rounded,
                  label: 'All Notices',
                  value: 'all',
                ),
                _navItem(
                  icon: Icons.priority_high_rounded,
                  label: 'Important Notices',
                  value: 'important',
                ),


                _navExpandable(
                  icon: Icons.category_rounded,
                  label: 'Categories',
                  expanded: _categoriesExpanded,
                  onTap: () => setState(() => _categoriesExpanded = !_categoriesExpanded),
                ),
                if (_categoriesExpanded) ...[
                  ...Constants.categories.map((cat) => _navItem(
                    icon: _getCategoryIcon(cat['value']!),
                    label: cat['label']!,
                    value: cat['value']!,
                    isSubItem: true,
                  )),
                ],
                const Divider(color: Colors.white24, height: 24),
                _navItem(
                  icon: Icons.bookmark_rounded,
                  label: 'Bookmarks',
                  value: 'bookmarks',
                ),
                _navItem(
                  icon: Icons.history_rounded,
                  label: 'Expired',
                  value: 'expired',
                ),
              ],
            ),
          ),

          // Logout at bottom
          InkWell(
            onTap: _logout,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.logout_rounded,
                      color: Colors.white70, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'Logout',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required String value,
    bool isSubItem = false,
  }) {
    final isSelected = _selectedNav == value;
    return InkWell(
      onTap: () {
        setState(() => _selectedNav = value);
        _applyFilters();
      },
      child: Container(
        color: isSelected
            ? Colors.white.withOpacity(0.18)
            : Colors.transparent,
        padding: EdgeInsets.symmetric(
          horizontal: isSubItem ? 32 : 16,
          vertical: isSubItem ? 10 : 12,
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? Colors.white : Colors.white70, size: isSubItem ? 16 : 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: isSubItem ? 12 : 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navExpandable({
    required IconData icon,
    required String label,
    required bool expanded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Icon(
              expanded ? Icons.expand_less : Icons.expand_more,
              color: Colors.white70,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String value) {
    switch (value) {
      case 'exam': return Icons.assignment_rounded;
      case 'event': return Icons.celebration_rounded;
      case 'placement': return Icons.work_rounded;
      case 'sports': return Icons.sports_basketball_rounded;
      case 'club': return Icons.groups_rounded;
      case 'class committee meeting': return Icons.groups_2_rounded;
      case 'workshop': return Icons.build_rounded;
      case 'interview': return Icons.mic_rounded;
      case 'webinar': return Icons.video_camera_front_rounded;
      case 'hackathon': return Icons.code_rounded;
      case 'competition': return Icons.emoji_events_rounded;
      case 'training program': return Icons.model_training_rounded;
      case 'scholarship': return Icons.school_rounded;
      case 'general': return Icons.info_outline_rounded;
      default: return Icons.category_rounded;
    }
  }

  // ─── TOP BAR ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Container(
      height: 64,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(child: Container()),
          Text(
            _studentName,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _showProfilePopup,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                _studentName.isNotEmpty ? _studentName[0].toUpperCase() : 'S',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: _logout,
            child: const Icon(Icons.logout_rounded,
                color: AppColors.error, size: 22),
          ),
        ],
      ),
    );
  }

  void _showProfilePopup() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    (_userProfile['full_name']?.isNotEmpty == true)
                        ? _userProfile['full_name'][0].toUpperCase()
                        : (_studentName.isNotEmpty ? _studentName[0].toUpperCase() : 'S'),
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _userProfile['full_name'] ?? _studentName,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  _userProfile['email'] ?? 'student@sjec.ac.in',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                _buildProfileDetailRow(Icons.badge_rounded, 'Role', (_userProfile['role'] ?? 'Student').toString().toUpperCase()),
                const SizedBox(height: 16),
                _buildProfileDetailRow(Icons.school_rounded, 'Department', (_userProfile['department'] ?? 'N/A').toString().toUpperCase()),
                const SizedBox(height: 16),
                _buildProfileDetailRow(Icons.calendar_today_rounded, 'Academic Year', (_userProfile['year'] ?? 'N/A').toString()),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── MAIN CONTENT ───────────────────────────────────────────────────────────
  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Row
          _buildStatsRow(),
          const SizedBox(height: 24),

          // Important Notices Banner
          if (_urgentNotices.isNotEmpty) _buildImportantBanner(),
          if (_urgentNotices.isNotEmpty) const SizedBox(height: 16),

          // ── ATCD Deadline Tracker Panel ──────────────────────────
          if (_urgencyMap.isNotEmpty) _buildDeadlineTracker(),
          if (_urgencyMap.isNotEmpty) const SizedBox(height: 20),

          // Filter Row
          _buildFilterRow(),
          const SizedBox(height: 20),

          // Notice Table
          _buildNoticeTable(),
          const SizedBox(height: 16),

          // Pagination
          _buildPagination(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── ATCD DEADLINE TRACKER ───────────────────────────────────────────────────
  Widget _buildDeadlineTracker() {
    final dueToday   = List<dynamic>.from(_urgencyMap['due_today']   ?? []);
    final urgent     = List<dynamic>.from(_urgencyMap['urgent']      ?? []);
    final approaching= List<dynamic>.from(_urgencyMap['approaching'] ?? []);
    final overdue    = List<dynamic>.from(_urgencyMap['overdue']     ?? []);

    final hasAnything = dueToday.isNotEmpty || urgent.isNotEmpty ||
                        approaching.isNotEmpty || overdue.isNotEmpty;
    if (!hasAnything) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.alarm_rounded,
                    color: AppColors.error, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Deadline Tracker',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'ATCD · Timed DFA',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1565C0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Due Today
          if (dueToday.isNotEmpty)
            ...dueToday.map((n) => _urgencyRow(
              n['title'] ?? '',
              '🔴 DUE TODAY',
              const Color(0xFFD32F2F),
              Icons.warning_rounded,
            )),

          // Urgent (1–3 days)
          if (urgent.isNotEmpty)
            ...urgent.map((n) => _urgencyRow(
              n['title'] ?? '',
              '🟠 ${n["days_left"]} day${n["days_left"] == 1 ? "" : "s"} left',
              const Color(0xFFE65100),
              Icons.timer_rounded,
            )),

          // Approaching (4–7 days)
          if (approaching.isNotEmpty)
            ...approaching.map((n) => _urgencyRow(
              n['title'] ?? '',
              '🟡 ${n["days_left"]} days left',
              const Color(0xFFF9A825),
              Icons.schedule_rounded,
            )),

          // Overdue
          if (overdue.isNotEmpty)
            ...overdue.map((n) => _urgencyRow(
              n['title'] ?? '',
              '⚫ Overdue by ${n["overdue_by"]} day${(n["overdue_by"] ?? 1) == 1 ? "" : "s"}',
              Colors.grey.shade500,
              Icons.timer_off_rounded,
            )),
        ],
      ),
    );
  }

  Widget _urgencyRow(String title, String label, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── STATS ROW ───────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final urgentCount = _urgentNotices.length;
    final totalCount = _allNotices.length;
    final passedCount = _allNotices.where((n) => n.isDeadlinePassed).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Notices',
            value: totalCount.toString(),
            icon: Icons.article_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Urgent / Important',
            value: urgentCount.toString(),
            icon: Icons.priority_high_rounded,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Deadlines Passed',
            value: passedCount.toString(),
            icon: Icons.timer_off_rounded,
            color: AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── IMPORTANT NOTICES BANNER ────────────────────────────────────────────────
  Widget _buildImportantBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Important Notices',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${_urgentNotices.length} Important',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'From director, deans, DOSW and more.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          OutlinedButton(
            onPressed: () {
              setState(() => _selectedNav = 'important');
              _applyFilters();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child: Text(
              'Show all',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── FILTER ROW ─────────────────────────────────────────────────────────────
  Widget _buildFilterRow() {
    final hasDateFilter = _filterFromDate != null || _filterToDate != null;
    return Row(
      children: [
        // Date Filter Button
        GestureDetector(
          onTap: _showDateFilterDialog,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: hasDateFilter
                    ? AppColors.primary
                    : Colors.grey.shade300,
                width: hasDateFilter ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 15,
                  color: hasDateFilter
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  hasDateFilter ? _dateFilterLabel() : 'Date filter',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: hasDateFilter
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: hasDateFilter
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: hasDateFilter
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                if (hasDateFilter) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _filterFromDate = null;
                        _filterToDate = null;
                      });
                      _applyFilters();
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      size: 15,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Search Field
        Expanded(
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search notices',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        onPressed: () {
                          _searchController.clear();
                        },
                        color: AppColors.textSecondary,
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _dateFilterLabel() {
    if (_filterFromDate != null && _filterToDate != null) {
      return '${_fmt(_filterFromDate!)} – ${_fmt(_filterToDate!)}';
    } else if (_filterFromDate != null) {
      return 'From ${_fmt(_filterFromDate!)}';
    } else {
      return 'Until ${_fmt(_filterToDate!)}';
    }
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void _showDateFilterDialog() async {
    DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: (_filterFromDate != null && _filterToDate != null)
          ? DateTimeRange(start: _filterFromDate!, end: _filterToDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (range != null) {
      setState(() {
        _filterFromDate = range.start;
        _filterToDate = range.end;
      });
      _applyFilters();
    }
  }

  // ─── NOTICE TABLE ────────────────────────────────────────────────────────────
  Widget _buildNoticeTable() {
    String label = 'All Notices';
    if (_selectedNav == 'important') label = 'Important Notices';
    else if (_selectedNav == 'expired') label = 'Expired Notices';
    else if (_selectedNav == 'bookmarks') label = 'Bookmarked Notices';
    else if (_selectedNav != 'all') {
      label = '${_selectedNav[0].toUpperCase()}${_selectedNav.substring(1)} Notices';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // Column headers
          _buildTableHeader(),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // Rows
          if (_filteredNotices.isEmpty)
            _buildEmptyState()
          else
            ..._pagedNotices
                .map((n) => _buildNoticeRow(n))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: const Color(0xFFF9FAFB),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          const SizedBox(width: 32), // checkbox space
          const SizedBox(width: 8),
          SizedBox(
            width: 140,
            child: Text(
              'FROM',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              'SUBJECT',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(
            width: 140,
            child: Text(
              'DUE DATE',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              'DATE',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 72,
            child: Text(
              'TIME',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeRow(NoticeModel notice) {
    final createdAt = _parseDate(notice.createdAt);
    final dateLabel = _relativeDate(createdAt);
    final timeLabel = _timeLabel(createdAt);
    final isNew = createdAt != null &&
        DateTime.now().difference(createdAt).inDays <= 1;

    // Determine deadline info
    Color deadlineColor = Colors.grey;
    Color deadlineBg = Colors.grey.shade100;
    String deadlineText = '';
    if (notice.hasAnyDate) {
      if (notice.hasDueDate) {
        if (notice.isDeadlinePassed) {
          deadlineColor = Colors.grey.shade600;
          deadlineBg = Colors.grey.shade100;
          deadlineText = 'Expired';
        } else if (notice.isUrgent) {
          deadlineColor = AppColors.error;
          deadlineBg = AppColors.error.withOpacity(0.1);
          deadlineText = notice.daysUntilDeadline == 0
              ? '⚠ Due Today!'
              : notice.daysUntilDeadline == 1
                  ? '⚠ Due Tomorrow!'
                  : '⚠ Due in ${notice.daysUntilDeadline}d';
        } else {
          deadlineColor = AppColors.warning;
          deadlineBg = AppColors.warning.withOpacity(0.1);
          deadlineText = notice.dueDate!.substring(0, 10);
        }
      } else {
        deadlineColor = AppColors.info;
        deadlineBg = AppColors.info.withOpacity(0.1);
        deadlineText = notice.aiInferredDateString ?? 'Date';
      }
    }

    return InkWell(
      onTap: () {
        ApiService.trackNoticeView(notice.id); // track silently
        _showNoticeDetail(notice);
      },
      hoverColor: const Color(0xFFF0F4FF),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: notice.isUrgent
              ? AppColors.error.withOpacity(0.03)
              : Colors.transparent,
          border: const Border(
            bottom: BorderSide(color: Color(0xFFE5E7EB)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Checkbox
            SizedBox(
              width: 32,
              child: Checkbox(
                value: false,
                onChanged: (_) {},
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3)),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                activeColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),

            // Bookmark icon
            Icon(
              Icons.bookmark_border_rounded,
              size: 16,
              color: notice.isUrgent
                  ? AppColors.error
                  : Colors.grey.shade400,
            ),
            const SizedBox(width: 8),

            // From
            SizedBox(
              width: 120,
              child: Text(
                notice.postedByName ?? notice.department ?? 'Admin',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),

            // Indicator dot (new or urgent)
            if (isNew || notice.isUrgent)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: notice.isUrgent
                      ? AppColors.error
                      : AppColors.primary,
                ),
              )
            else
              const SizedBox(width: 14),

            // Subject/Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    notice.title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight:
                          isNew ? FontWeight.w600 : FontWeight.w400,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (notice.category != null && notice.category!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIcon(notice.category!),
                            size: 10,
                            color: notice.categoryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            notice.category!.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: notice.categoryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // ── Due Date Badge + Calendar button ──
            if (notice.hasAnyDate)
              SizedBox(
                width: 140,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: deadlineBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: deadlineColor.withOpacity(0.35)),
                        ),
                        child: Text(
                          deadlineText,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: deadlineColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    if (!notice.isDeadlinePassed) ...[
                      const SizedBox(width: 6),
                      Tooltip(
                        message: 'Add to Google Calendar',
                        child: GestureDetector(
                          onTap: () {
                            _addToCalendar(notice);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              )
            else
              const SizedBox(width: 140),

            // Posted Date
            SizedBox(
              width: 90,
              child: Text(
                dateLabel,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(width: 12),

            // Time
            SizedBox(
              width: 72,
              child: Text(
                timeLabel,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.notifications_none_rounded,
                size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No notices found',
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── PAGINATION ──────────────────────────────────────────────────────────────
  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    final pages = _buildPageNumbers();

    return Center(
      child: Wrap(
        spacing: 4,
        children: [
          _pageBtn('«', _currentPage > 1
              ? () => setState(() => _currentPage = 1)
              : null),
          _pageBtn('‹', _currentPage > 1
              ? () => setState(() => _currentPage--)
              : null),
          ...pages.map(
            (p) => p == -1
                ? _ellipsis()
                : _pageBtn(
                    '$p',
                    p != _currentPage
                        ? () => setState(() => _currentPage = p)
                        : null,
                    isActive: p == _currentPage,
                  ),
          ),
          _pageBtn('›', _currentPage < _totalPages
              ? () => setState(() => _currentPage++)
              : null),
          _pageBtn('»', _currentPage < _totalPages
              ? () => setState(() => _currentPage = _totalPages)
              : null),
        ],
      ),
    );
  }

  List<int> _buildPageNumbers() {
    final List<int> pages = [];
    if (_totalPages <= 7) {
      for (int i = 1; i <= _totalPages; i++) pages.add(i);
    } else {
      pages.add(1);
      if (_currentPage > 3) pages.add(-1); // ellipsis
      for (int i = (_currentPage - 1).clamp(2, _totalPages - 1);
          i <= (_currentPage + 1).clamp(2, _totalPages - 1);
          i++) {
        pages.add(i);
      }
      if (_currentPage < _totalPages - 2) pages.add(-1);
      pages.add(_totalPages);
    }
    return pages;
  }

  Widget _pageBtn(String label, VoidCallback? onTap,
      {bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _ellipsis() {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      child: Text(
        '…',
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  // ─── NOTICE DETAIL MODAL ─────────────────────────────────────────────────────
  void _showNoticeDetail(NoticeModel notice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
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
                gradient: notice.isUrgent
                    ? LinearGradient(colors: [
                        AppColors.error.withOpacity(0.1),
                        AppColors.warning.withOpacity(0.1),
                      ])
                    : const LinearGradient(colors: [
                        Color(0xFFE8F5E9),
                        Color(0xFFE3F2FD),
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
                              horizontal: 10, vertical: 5),
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (notice.postedByName != null)
                        _buildTag(notice.postedByName!, AppColors.primary),
                      if (notice.department != null) ...[
                        const SizedBox(width: 6),
                        _buildTag(notice.department!, AppColors.info),
                      ],
                      if (notice.category != null) ...[
                        const SizedBox(width: 6),
                        _buildTag(notice.category!, notice.categoryColor),
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
                    // AI Summary
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
                                const Icon(Icons.auto_awesome_rounded,
                                    color: Colors.white, size: 16),
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
                              final isDeadline =
                                  point.toLowerCase().startsWith('deadline');
                              final isDate =
                                  point.toLowerCase().startsWith('date');
                              final isVenue =
                                  point.toLowerCase().startsWith('venue');
                              final isTime =
                                  point.toLowerCase().startsWith('time');
                              IconData icon = Icons.circle;
                              if (isDeadline) icon = Icons.alarm_rounded;
                              else if (isDate) icon = Icons.calendar_today_rounded;
                              else if (isVenue) icon = Icons.location_on_rounded;
                              else if (isTime) icon = Icons.access_time_rounded;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Icon(icon,
                                        color: Colors.white, size: 14),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        point.trim(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.white
                                              .withOpacity(0.95),
                                          height: 1.5,
                                          fontWeight: isDeadline || isDate
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    if (isDeadline || isDate)
                                      GestureDetector(
                                        onTap: () => _addToCalendar(notice),
                                        child: const Icon(
                                          Icons.calendar_month_rounded,
                                          color: Colors.white70,
                                          size: 16,
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

                    // Due date or AI inferred date
                    if (notice.hasAnyDate) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: notice.isDeadlinePassed
                              ? Colors.grey.shade100
                              : notice.isUrgent
                                  ? AppColors.error.withOpacity(0.08)
                                  : notice.hasDueDate
                                      ? AppColors.warning.withOpacity(0.08)
                                      : AppColors.info.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: notice.isDeadlinePassed
                                ? Colors.grey.shade400
                                : notice.isUrgent
                                    ? AppColors.error.withOpacity(0.3)
                                    : notice.hasDueDate
                                        ? AppColors.warning.withOpacity(0.3)
                                        : AppColors.info.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.alarm_rounded,
                              color: notice.isDeadlinePassed
                                  ? Colors.grey.shade600
                                  : notice.isUrgent
                                      ? AppColors.error
                                      : notice.hasDueDate
                                          ? AppColors.warning
                                          : AppColors.info,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notice.deadlineStatus,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: notice.isDeadlinePassed
                                          ? Colors.grey.shade600
                                          : notice.isUrgent
                                              ? AppColors.error
                                              : notice.hasDueDate
                                                  ? AppColors.warning
                                                  : AppColors.info,
                                    ),
                                  ),
                                  if (notice.hasDueDate)
                                    Text(
                                      notice.dueDate!.substring(0, 10),
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: notice.isDeadlinePassed
                                            ? Colors.grey.shade600
                                            : notice.isUrgent
                                                ? AppColors.error
                                                : AppColors.warning,
                                      ),
                                    )
                                  else if (notice.hasAIInferredDate)
                                    Text(
                                      notice.aiInferredDateString ?? 'Date',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.info,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (!notice.isDeadlinePassed)
                              GestureDetector(
                              onTap: () => _addToCalendar(notice),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: notice.isDeadlinePassed
                                      ? Colors.grey.shade500
                                      : AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                        Icons.calendar_month_rounded,
                                        color: Colors.white,
                                        size: 18),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Add to\nCalendar',
                                      style: GoogleFonts.poppins(
                                        fontSize: 9,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                  errorBuilder:
                                      (context, error, stack) =>
                                          const SizedBox.shrink(),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  html.window.open(notice.fileUrl, '_blank');
                                },
                                icon: const Icon(Icons.download_rounded,
                                    color: Colors.white),
                                label: Text(
                                  notice.isPdf
                                      ? 'View / Download PDF'
                                      : 'Download File',
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
                    if (notice.content != null) ...[
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

  // ─── HELPERS ─────────────────────────────────────────────────────────────────
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

  DateTime? _parseDate(String? s) {
    if (s == null) return null;
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {
      return null;
    }
  }

  String _relativeDate(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month]} ${dt.day}';
  }

  String _timeLabel(DateTime? dt) {
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }

  void _addToCalendar(NoticeModel notice) {
    try {
      final title = Uri.encodeComponent(notice.title);
      final details =
          Uri.encodeComponent(notice.summary ?? notice.title);
      
      String datesParam = '';
      if (notice.hasDueDate) {
        final dateStr = notice.dueDate!.substring(0, 10);
        final parts = dateStr.split('-');
        if (parts.length >= 3) {
          datesParam = '&dates=${parts[0]}${parts[1]}${parts[2]}T090000/${parts[0]}${parts[1]}${parts[2]}T100000';
        }
      }
      
      final url =
          'https://calendar.google.com/calendar/render?action=TEMPLATE&text=$title$datesParam&details=$details&sf=true&output=xml';
      html.window.open(url, '_blank');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open calendar'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}