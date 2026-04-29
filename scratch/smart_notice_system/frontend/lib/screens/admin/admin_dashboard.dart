import 'dart:html' as html;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../../utils/colors.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/notice_model.dart';
import '../../utils/constants.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  List<NoticeModel> _notices = [];
  bool _isLoading = true;
  String _adminName = '';
  String _adminRole = '';
  int _currentUserId = 0;

  // Analytics
  Map<String, dynamic> _analytics = {};
  bool _analyticsLoading = false;
  bool _analyticsLoaded = false;
  String? _analyticsError;

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
       _adminName = userInfo['full_name'] ?? 'Admin';
       _adminRole = userInfo['role'] ?? 'admin';
       _currentUserId = int.tryParse(userId ?? '0') ?? 0;
  });
    final noticeResult = await ApiService.getMyNotices();
    if (noticeResult['success']) {
      setState(() {
        _notices = (noticeResult['data'] as List)
            .map((n) => NoticeModel.fromJson(n))
            .toList();
      });
    }
    setState(() => _isLoading = false);
    // Also refresh analytics if on that tab
    if (_selectedIndex == 3) _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _analyticsLoading = true;
      _analyticsError = null;
    });
    final result = await ApiService.getAnalytics();
    if (result['success']) {
      setState(() {
        _analytics = Map<String, dynamic>.from(result['data'] as Map);
        _analyticsLoaded = true;
      });
    } else {
      setState(() {
        _analyticsError = result['message'] ?? 'Failed to load analytics';
        _analyticsLoaded = true;
      });
    }
    setState(() => _analyticsLoading = false);
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  String _getRoleDisplay() {
    switch (_adminRole) {
      case 'admin': return 'Admin';
      case 'hod': return 'HOD';
      case 'placement_cell': return 'Placement Cell';
      case 'club_coordinator': return 'Club Coordinator';
      case 'sports_coordinator': return 'Sports Coordinator';
      default: return 'Admin';
    }
  }

  Color _getRoleColor() {
    switch (_adminRole) {
      case 'hod': return AppColors.hodColor;
      case 'placement_cell': return AppColors.placementColor;
      case 'club_coordinator': return AppColors.clubColor;
      case 'sports_coordinator': return AppColors.sportsColor;
      default: return AppColors.adminColor;
    }
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
                    child: _selectedIndex == 0
                        ? _buildAllNoticesTab()
                        : _selectedIndex == 1
                            ? _buildMyNoticesTab()
                            : _selectedIndex == 2
                                ? _buildPostNoticeTab()
                                : _buildAnalyticsTab(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_getRoleColor().withOpacity(0.9), _getRoleColor()],
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
                  Icons.manage_accounts_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getRoleDisplay(),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
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
      {'icon': Icons.list_alt_rounded, 'label': 'All Notices'},
      {'icon': Icons.person_rounded, 'label': 'My Notices'},
      {'icon': Icons.add_circle_rounded, 'label': 'Post Notice'},
      {'icon': Icons.bar_chart_rounded, 'label': 'Analytics'},
    ];
    return Container(
      color: _getRoleColor(),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = _selectedIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedIndex = index);
                if (index == 3 && _analytics.isEmpty) _loadAnalytics();
              },
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

  Widget _buildAllNoticesTab() {
    if (_notices.isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.dashboard_rounded,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No notices found',
                    style: GoogleFonts.poppins(
                        fontSize: 16, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Icon(Icons.list_alt_rounded, size: 16, color: _getRoleColor()),
                const SizedBox(width: 6),
                Text(
                  'All Notices',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _getRoleColor(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRoleColor().withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_notices.length} notice${_notices.length != 1 ? 's' : ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getRoleColor(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildNoticeCard(_notices[index]),
              childCount: _notices.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyNoticesTab() {
    // Only show notices posted BY this admin
    final myNotices = _notices
        .where((n) => n.postedById == _currentUserId)
        .toList();

    if (myNotices.isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No notices posted yet',
                    style: GoogleFonts.poppins(
                        fontSize: 16, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Switch to "Post Notice" tab to create one!',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Row(
              children: [
                Icon(Icons.person_rounded, size: 16, color: _getRoleColor()),
                const SizedBox(width: 6),
                Text(
                  'My Posted Notices',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _getRoleColor(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRoleColor().withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${myNotices.length} notice${myNotices.length != 1 ? 's' : ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getRoleColor(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  _buildNoticeCard(myNotices[index], showDelete: true),
              childCount: myNotices.length,
            ),
          ),
        ),
      ],
    );
  }

  // ─── DELETE CONFIRM DIALOG ────────────────────────────────
  void _confirmDelete(NoticeModel notice) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Notice',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this notice?',
              style: GoogleFonts.poppins(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: AppColors.error.withOpacity(0.25)),
              ),
              child: Text(
                notice.title,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This will permanently remove the notice for all students.',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary),
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
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await ApiService.deleteNotice(notice.id);
              if (mounted) {
                if (result['success']) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Notice deleted successfully!',
                          style: GoogleFonts.poppins()),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                  _loadData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          result['message'] ?? 'Failed to delete notice',
                          style: GoogleFonts.poppins()),
                      backgroundColor: AppColors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              }
            },
            child: Text('Delete',
                style: GoogleFonts.poppins(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }


  Widget _buildNoticeCard(NoticeModel notice, {bool showDelete = false}) {
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getRoleColor().withOpacity(0.05),
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
          if (notice.summary != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 14,
                        color: _getRoleColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'AI Summary',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getRoleColor(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notice.summary!,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (notice.department != null)
                      _buildTag(notice.department!, AppColors.primary),
                    if (notice.year != null) ...[
                      const SizedBox(width: 6),
                      _buildTag(notice.year!, AppColors.info),
                    ],
                    if (notice.fileType != null) ...[
                      const SizedBox(width: 6),
                      _buildTag(
                        notice.fileType!.contains('pdf')
                            ? 'PDF'
                            : notice.fileType!.contains('image')
                                ? 'Image'
                                : 'File',
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
                const SizedBox(height: 8),
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
                    if (showDelete)
                      GestureDetector(
                        onTap: () => _confirmDelete(notice),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.error.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.error.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.delete_outline_rounded,
                                  size: 14, color: AppColors.error),
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
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getRoleColor().withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notice.title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                // Posted by me label
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_rounded,
                        size: 12,
                        color: _getRoleColor(),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        notice.postedById == _currentUserId
                        ? 'Posted by: Me'
                        : notice.postedByRole == 'super_admin'
                        ? 'Posted by: Super Admin'
                        : 'Posted by: ${notice.postedByName ?? "Unknown"} (${_getRoleDisplay()})',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _getRoleColor(),
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
                              const Icon(
                                Icons.auto_awesome_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'AI Summary',
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
                        color: AppColors.warning.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.warning.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.alarm_rounded,
                            color: AppColors.warning,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Due Date',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warning,
                                ),
                              ),
                              Text(
                                notice.dueDate!.substring(0, 10),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.warning,
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
                                child: Text(
                                  notice.filePath!.split('/').last,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                              icon: const Icon(
                                Icons.download_rounded,
                                color: Colors.white,
                              ),
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

  // ─── ANALYTICS TAB ──────────────────────────────────────────────────────────
  Widget _buildAnalyticsTab() {
    if (_analyticsLoading && !_analyticsLoaded) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const CircularProgressIndicator(color: AppColors.primary),
        const SizedBox(height: 16),
        Text('Loading analytics...', style: GoogleFonts.poppins(color: AppColors.textSecondary)),
      ]));
    }
    if (_analyticsError != null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline_rounded, size: 64, color: Colors.red.shade300),
        const SizedBox(height: 16),
        Text('Could not load analytics', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text(_analyticsError!, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _loadAnalytics,
          icon: const Icon(Icons.refresh_rounded),
          label: Text('Retry', style: GoogleFonts.poppins()),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
        ),
      ]));
    }

    final totalNotices = _analytics['total_notices'] ?? 0;
    final totalViews = _analytics['total_views'] ?? 0;
    final uniqueReaders = _analytics['unique_readers'] ?? 0;
    final totalStudents = _analytics['total_students'] ?? 0;
    final overallRate = (_analytics['overall_view_rate'] ?? 0.0).toDouble();
    final recent7 = _analytics['recent_7_days'] ?? 0;
    final noticeList = (_analytics['notices'] as List? ?? []);
    final byCategory = _analytics['by_category'] as Map? ?? {};

    final List<Color> chartColors = [
      const Color(0xFF1565C0), const Color(0xFF00897B), const Color(0xFF7B1FA2),
      const Color(0xFFE65100), const Color(0xFFD32F2F), const Color(0xFF00838F),
      const Color(0xFF558B2F), const Color(0xFF4527A0),
    ];
    final catEntries = byCategory.entries.toList();
    final totalCatCount = catEntries.fold<int>(0, (s, e) => s + ((e.value as Map)['count'] as int? ?? 0));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Compact stat row ─────────────────────────────────────
        Row(children: [
          _miniStatCard('Notices', '$totalNotices', Icons.article_rounded, const Color(0xFF1565C0)),
          const SizedBox(width: 8),
          _miniStatCard('Views', '$totalViews', Icons.visibility_rounded, const Color(0xFF00897B)),
          const SizedBox(width: 8),
          _miniStatCard('Readers', '$uniqueReaders', Icons.people_rounded, const Color(0xFF7B1FA2)),
          const SizedBox(width: 8),
          _miniStatCard('Week', '$recent7', Icons.calendar_today_rounded, const Color(0xFFE65100)),
        ]),
        const SizedBox(height: 14),

        // ── Reading Rate card ────────────────────────────────────
        _sectionCard(
          title: '📊 Overall Reading Rate',
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: Text('$uniqueReaders of $totalStudents students engaged',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary))),
              Text('${overallRate.toStringAsFixed(1)}%',
                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: _rateColor(overallRate))),
            ]),
            const SizedBox(height: 8),
            _progressBar(overallRate / 100, _rateColor(overallRate)),
          ]),
        ),
        const SizedBox(height: 14),

        // ── Pie chart ────────────────────────────────────────────
        if (catEntries.isNotEmpty) _sectionCard(
          title: '🥧 Notices by Category',
          child: SizedBox(height: 200, child: Row(children: [
            Expanded(flex: 5, child: PieChart(PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 42,
              sections: catEntries.asMap().entries.map((e) {
                final c = chartColors[e.key % chartColors.length];
                final cnt = (e.value.value as Map)['count'] as int? ?? 0;
                final pct = totalCatCount > 0 ? cnt / totalCatCount * 100 : 0.0;
                return PieChartSectionData(
                  color: c, value: cnt.toDouble(),
                  title: '${pct.toStringAsFixed(0)}%', radius: 52,
                  titleStyle: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                );
              }).toList(),
            ))),
            const SizedBox(width: 12),
            Expanded(flex: 4, child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: catEntries.asMap().entries.map((e) {
                final c = chartColors[e.key % chartColors.length];
                final cat = e.value.key as String;
                final cnt = (e.value.value as Map)['count'] as int? ?? 0;
                return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 6),
                  Expanded(child: Text('${cat[0].toUpperCase()}${cat.substring(1)} ($cnt)',
                      style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis)),
                ]));
              }).toList(),
            )),
          ])),
        ),
        const SizedBox(height: 14),

        // ── Bar chart: top notices by views ─────────────────────
        if (noticeList.isNotEmpty) _sectionCard(
          title: '📈 Top Notices by Views',
          child: SizedBox(height: 220, child: BarChart(BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: noticeList.take(6).map((n) => (n['views'] ?? 0).toDouble()).fold(0.0, (a, b) => a > b ? a : b) + 2,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, gi, rod, ri) {
                  final n = noticeList[gi];
                  return BarTooltipItem('${n['title']}\n${rod.toY.toInt()} views',
                      GoogleFonts.poppins(fontSize: 10, color: Colors.white));
                },
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 28,
                getTitlesWidget: (v, m) => Text(v.toInt().toString(),
                    style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary)),
              )),
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, m) {
                  final idx = v.toInt();
                  final top6 = noticeList.take(6).toList();
                  if (idx < 0 || idx >= top6.length) return const SizedBox();
                  final t = (top6[idx]['title'] as String? ?? '');
                  final label = t.length > 7 ? '${t.substring(0, 7)}..' : t;
                  return Padding(padding: const EdgeInsets.only(top: 4),
                      child: Text(label, style: GoogleFonts.poppins(fontSize: 9, color: AppColors.textSecondary),
                          textAlign: TextAlign.center));
                },
              )),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true, drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            barGroups: noticeList.take(6).toList().asMap().entries.map((e) {
              final views = (e.value['views'] ?? 0).toDouble();
              return BarChartGroupData(x: e.key, barRods: [
                BarChartRodData(
                  toY: views, color: chartColors[e.key % chartColors.length],
                  width: 22, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ]);
            }).toList(),
          ))),
        ),
        const SizedBox(height: 14),

        // ── Per-notice view rates list ───────────────────────────
        _sectionCard(
          title: '📋 Notice View Rates',
          child: noticeList.isEmpty
              ? Text('No data yet.', style: GoogleFonts.poppins(color: AppColors.textSecondary))
              : Column(children: noticeList.take(10).map<Widget>((n) {
                  final rate = (n['view_rate'] ?? 0.0).toDouble();
                  final views = n['views'] ?? 0;
                  final eligible = n['eligible_students'] ?? 0;
                  return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(n['title'] ?? '',
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: _rateColor(rate).withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                          child: Text('${rate.toStringAsFixed(1)}%',
                              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: _rateColor(rate))),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        Expanded(child: _progressBar(rate / 100, _rateColor(rate))),
                        const SizedBox(width: 6),
                        Text('$views/$eligible', style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary)),
                      ]),
                    ],
                  ));
                }).toList()),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }








  Widget _miniStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 6),
            Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _progressBar(double fraction, Color color) {
    final clamped = fraction.clamp(0.0, 1.0);
    return LayoutBuilder(builder: (ctx, constraints) {
      return Stack(
        children: [
          Container(
            height: 8,
            width: constraints.maxWidth,
            decoration: BoxDecoration(
                color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOut,
            height: 8,
            width: constraints.maxWidth * clamped,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(4)),
          ),
        ],
      );
    });
  }

  Color _rateColor(double rate) {
    if (rate >= 70) return const Color(0xFF00897B);
    if (rate >= 40) return const Color(0xFFF57C00);
    return const Color(0xFFD32F2F);
  }

  Widget _buildPostNoticeTab() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    List<String> selectedYears = [];
    List<String> selectedDepts = [];
    bool isGeneral = false;
    PlatformFile? selectedFile;
    bool isPosting = false;
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
                  'Fill in the details below',
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
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
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
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Notice Category',
                    prefixIcon: const Icon(Icons.category_rounded, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  items: Constants.categories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat['value'],
                      child: Text(cat['label']!),
                    );
                  }).toList(),
                  onChanged: (val) => setTabState(() => selectedCategory = val),
                ),
                const SizedBox(height: 12),

                // Multi-select Departments
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
                        children: Constants.departments.map((dept) {
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
                          ...Constants.ugYears,
                          ...Constants.pgYears
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
                      backgroundColor: _getRoleColor(),
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

    // 8-class token classifier from backend classified_tokens
    final classifiedRaw = List<dynamic>.from(atcd['classified_tokens'] ?? []);
    final Map<String, String> tokenClassMap = {};
    final Map<String, String> tokenColorHex = {};
    for (final ct in classifiedRaw) {
      tokenClassMap[ct['token'] as String] = ct['class'] as String;
      tokenColorHex[ct['token'] as String] = ct['color'] as String;
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
    const kDateColor    = Color(0xFFD32F2F);
    const kDeptColor    = Color(0xFF1565C0);
    const kYearColor    = Color(0xFF7B1FA2);


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
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
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
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        Text('Adaptive Token Classification & Detection',
                            style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white38)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _selectedIndex = 1); // go to My Notices
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white54, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '✅  "$title" posted successfully',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF69F0AE),
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 24),

              // ── Stats row ──
              Row(
                children: [
                  _atcdStat('Tokens\nFound',    '${tokens.length}',   const Color(0xFF00E5FF)),
                  const SizedBox(width: 10),
                  _atcdStat('Dates\nDetected',  '${dates.length}',    kDateColor),
                  const SizedBox(width: 10),
                  _atcdStat('Word\nCount',       '$wordCount',          const Color(0xFF69F0AE)),
                  const SizedBox(width: 10),
                  _atcdStat('Event\nType',       eventType.toUpperCase(), const Color(0xFFFFD740)),
                ],
              ),
              const SizedBox(height: 20),

              // ── Deadline / Due Date ──
              if (hasDeadline)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: kDateColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kDateColor.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.alarm_rounded,
                          color: kDateColor, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Deadline detected: ${dueDate ?? dates.join(', ')}',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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
                          'Auto-Detected: ${autoCategory.toUpperCase()}  (ATCD DFA Classifier)',
                          style: GoogleFonts.poppins(fontSize: 12,
                              fontWeight: FontWeight.w600, color: const Color(0xFF00E676)),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Legend (8 classes) ──
              Wrap(
                spacing: 10,
                runSpacing: 6,
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

              // ── Token chips ──
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
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    tokens.isEmpty
                        ? Text('No tokens extracted.',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.white38))
                        : Wrap(
                            spacing: 8,
                            runSpacing: 10,
                            children: tokens.map((t) {
                              final c = chipColor(t);
                              final cls = chipClass(t);
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
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

              // ── Departments detected ──
              if (depts.isNotEmpty) ...[
                _atcdDetailRow(
                  icon: Icons.business_rounded,
                  color: kDeptColor,
                  label: 'Departments Detected',
                  items: depts,
                ),
                const SizedBox(height: 12),
              ],

              // ── Years detected ──
              if (years.isNotEmpty) ...[
                _atcdDetailRow(
                  icon: Icons.school_rounded,
                  color: kYearColor,
                  label: 'Academic Years Detected',
                  items: years,
                ),
                const SizedBox(height: 12),
              ],

              // ── Dates list ──
              if (dates.isNotEmpty) ...[
                _atcdDetailRow(
                  icon: Icons.calendar_today_rounded,
                  color: kDateColor,
                  label: 'Dates Found',
                  items: dates,
                ),
                const SizedBox(height: 12),
              ],

              // ── AI Summary ──
              if (summary.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.3),
                        AppColors.primary.withOpacity(0.1),
                      ],
                    ),
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
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
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
                    setState(() => _selectedIndex = 1); // My Notices
                  },
                  icon: const Icon(Icons.notifications_rounded,
                      color: Colors.white),
                  label: Text('View My Notices',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getRoleColor(),
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
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: Colors.white54,
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
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.white54,
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
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items
                .map((i) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(i,
                          style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}