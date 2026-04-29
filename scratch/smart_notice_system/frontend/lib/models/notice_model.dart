import 'package:flutter/material.dart';

class NoticeModel {
  final int id;
  final String title;
  final String? content;
  final String? summary;
  final String? department;
  final String? year;
  final String? targetYears;
  final String? targetDepartments;
  final String? category;
  final bool isGeneral;
  final String? dueDate;
  final String? fileType;
  final String? filePath;
  final String createdAt;
  final int? postedById;
  final String? postedByName;
  final String? postedByRole;

  NoticeModel({
    required this.id,
    required this.title,
    this.content,
    this.summary,
    this.department,
    this.year,
    this.targetYears,
    this.targetDepartments,
    this.category,
    required this.isGeneral,
    this.dueDate,
    this.fileType,
    this.filePath,
    required this.createdAt,
    this.postedById,
    this.postedByName,
    this.postedByRole,
  });

  factory NoticeModel.fromJson(Map<String, dynamic> json) {
    return NoticeModel(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      summary: json['summary'],
      department: json['department'],
      year: json['year'],
      targetYears: json['target_years'],
      targetDepartments: json['target_departments'],
      category: json['category'],
      isGeneral: json['is_general'] ?? false,
      dueDate: json['due_date'],
      fileType: json['file_type'],
      filePath: json['file_path'],
      createdAt: json['created_at'],
      postedById: json['posted_by_id'],
      postedByName: json['posted_by_name'],
      postedByRole: json['posted_by_role'],
    );
  }

  bool get hasDueDate => dueDate != null && dueDate!.isNotEmpty;
  bool get hasFile => filePath != null && filePath!.isNotEmpty;
  bool get isPdf => fileType != null && fileType!.contains('pdf');
  bool get isImage => fileType != null && fileType!.contains('image');
  String get fileUrl => 'http://127.0.0.1:8000/$filePath';

  List<String> get targetYearsList {
    if (targetYears == null || targetYears!.isEmpty) return [];
    return targetYears!.split(',').map((e) => e.trim()).toList();
  }

  List<String> get targetDepartmentsList {
    if (targetDepartments == null || targetDepartments!.isEmpty) return [];
    return targetDepartments!.split(',').map((e) => e.trim()).toList();
  }

  bool get isPostedBySuperAdmin => postedByRole == 'super_admin';

  Color get categoryColor {
    switch (category?.toLowerCase()) {
      case 'exam': return const Color(0xFFE24B4A);
      case 'event': return const Color(0xFF7C3AED);
      case 'placement': return const Color(0xFFD97706);
      case 'sports': return const Color(0xFF0369A1);
      case 'club': return const Color(0xFF059669);
      case 'general': return const Color(0xFF3B82F6);
      default: return const Color(0xFF888780);
    }
  }

  DateTime? get _parsedDate {
    if (hasDueDate) return DateTime.parse(dueDate!);
    if (hasAIInferredDate) {
      final text = aiInferredDateString!;
      
      // Try YYYY-MM-DD or standard parse first
      try {
        return DateTime.parse(text);
      } catch (_) {}

      // Try DD-MM-YYYY or DD/MM/YYYY or DD.MM.YYYY
      final dmy = RegExp(r'(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{4})');
      final match1 = dmy.firstMatch(text);
      if (match1 != null) {
        return DateTime(
          int.parse(match1.group(3)!),
          int.parse(match1.group(2)!),
          int.parse(match1.group(1)!),
        );
      }

      // Very simple textual month parsing
      final months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
      for (int i = 0; i < months.length; i++) {
        if (text.toLowerCase().contains(months[i])) {
          final yearMatch = RegExp(r'(\d{4})').firstMatch(text);
          final dayMatch = RegExp(r'(?<!\d)(\d{1,2})(?!\d{3})').firstMatch(text);
          if (yearMatch != null && dayMatch != null) {
            return DateTime(
              int.parse(yearMatch.group(1)!),
              i + 1,
              int.parse(dayMatch.group(1)!),
            );
          }
        }
      }
    }
    return null;
  }

  bool get isDeadlinePassed {
    try {
      final due = _parsedDate;
      if (due == null) return false;
      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      return due.isBefore(today);
    } catch (e) {
      return false;
    }
  }

  bool get isUrgent {
    try {
      final due = _parsedDate;
      if (due == null) return false;
      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final dueDay = DateTime(due.year, due.month, due.day);
      final diff = dueDay.difference(today).inDays;
      return diff >= 0 && diff <= 3;
    } catch (e) {
      return false;
    }
  }

  int get daysUntilDeadline {
    try {
      final due = _parsedDate;
      if (due == null) return -1;
      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final dueDay = DateTime(due.year, due.month, due.day);
      return dueDay.difference(today).inDays;
    } catch (e) {
      return -1;
    }
  }

  bool get hasAIInferredDate => aiInferredDateString != null;

  String? get aiInferredDateString {
    if (summary == null) return null;
    final parts = summary!.split(' | ');
    for (var p in parts) {
      final lp = p.toLowerCase().trim();
      if (lp.startsWith('date:') || lp.startsWith('deadline:')) {
        final splitPoint = p.indexOf(':');
        if (splitPoint != -1 && splitPoint < p.length - 1) {
          return p.substring(splitPoint + 1).trim();
        }
      }
    }
    return null;
  }

  bool get hasAnyDate => hasDueDate || hasAIInferredDate;

  String get deadlineStatus {
    if (_parsedDate != null) {
      final days = daysUntilDeadline;
      if (days < 0) return 'Deadline Passed!';
      if (days == 0) return 'Due Today!';
      if (days == 1) return 'Due Tomorrow!';
      if (days <= 3) return 'Due in $days days!';
      
      if (hasDueDate) {
        return 'Due on ${dueDate!.substring(0, 10)}';
      } else {
        return aiInferredDateString!;
      }
    } else if (hasAIInferredDate) {
      // If we couldn't parse the fuzzy date, just return the raw text
      return aiInferredDateString!;
    }
    return '';
  }
}