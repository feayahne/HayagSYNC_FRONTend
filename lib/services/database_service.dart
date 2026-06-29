import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/report_model.dart';
import '../models/meeting_model.dart';
import '../models/chat_model.dart';
import '../models/timeline_model.dart';

class DatabaseService extends ChangeNotifier {
  // Singleton Pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Laravel Backend URL (use local IP for physical phone connectivity, localhost for Web)
  static const String baseUrl = kIsWeb ? 'http://127.0.0.1:8000/api' : 'https://1eda77c80b1b9bbb-112-210-227-252.serveousercontent.com/api';

  String? _token;
  String? get token => _token;
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  // Local Memory Cache for UI synchronizations
  final Map<String, UserModel> _users = {};
  final List<ReportModel> _reports = [];
  final List<MeetingModel> _meetings = [];
  final List<ChatMessage> _messages = [];
  final List<TimelineEvent> _timelines = [];

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // --- REFRESH CACHE FROM API ---

  Future<void> syncData() async {
    if (_token == null) return;
    try {
      // 1. Fetch Reports
      final reportsRes = await http.get(Uri.parse('$baseUrl/reports'), headers: _headers);
      if (reportsRes.statusCode == 200) {
        final List data = json.decode(reportsRes.body);
        _reports.clear();
        for (var item in data) {
          _reports.add(ReportModel(
            id: item['id'].toString(),
            parentId: item['parent_id'].toString(),
            parentName: item['parent_name'] ?? 'Parent',
            studentName: item['student_name'] ?? 'Student',
            studentSection: item['student_section'] ?? '',
            studentGrade: item['student_grade'] ?? '',
            title: item['title'] ?? '',
            description: item['description'] ?? '',
            category: item['category'] ?? '',
            incidentDate: DateTime.parse(item['incident_date']),
            incidentLocation: item['incident_location'] ?? '',
            evidenceUrl: item['evidence_url'],
            evidenceVerificationState: item['evidence_verification_state'] ?? 'Unverified',
            evidenceVerificationDetails: item['evidence_verification_details'],
            aiSummary: item['ai_summary'],
            status: item['status'] ?? 'Pending',
            disciplineAction: item['discipline_action'],
            disciplineNotes: item['discipline_notes'],
            appealedReason: item['appealed_reason'],
            appealCount: item['appeal_count'] ?? 0,
            createdAt: DateTime.parse(item['created_at']),
            bullyName: item['bully_name'],
            bullyGradeSection: item['bully_grade_section'],
            witnesses: item['witnesses'] != null ? List<String>.from(item['witnesses']) : null,
          ));
        }
      }

      // 2. Fetch Directory if Staff
      if (_currentUser != null && _currentUser!.role != UserRole.parent) {
        final dirRes = await http.get(Uri.parse('$baseUrl/directory/parents'), headers: _headers);
        if (dirRes.statusCode == 200) {
          final List data = json.decode(dirRes.body);
          _users.clear();
          for (var item in data) {
            final u = UserModel(
              id: item['id'].toString(),
              email: item['email'],
              name: item['name'],
              role: UserRole.parent,
              studentName: item['student_name'],
              studentGrade: item['student_grade'],
              studentSection: item['student_section'],
              academicYear: item['academic_year'],
              avatarUrl: item['avatar_url'],
            );
            _users[u.id] = u;
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Sync failed: $e');
    }
  }

  // --- AUTH ENDPOINTS ---

  Future<UserModel> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: json.encode({
        'email': email.trim(),
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data;
      try {
        data = json.decode(response.body);
      } catch (e) {
        throw Exception('Server returned an invalid response format.');
      }
      
      _token = data['token'];
      
      final uJson = data['user'];
      _currentUser = UserModel(
        id: uJson['id'].toString(),
        email: uJson['email'],
        name: uJson['name'],
        role: UserRole.values.firstWhere(
          (e) => e.toString().split('.').last == uJson['role'],
          orElse: () => UserRole.parent,
        ),
        avatarUrl: uJson['avatar_url'],
        assignedSection: uJson['assigned_section'],
        studentName: uJson['student_name'],
        studentGrade: uJson['student_grade'],
        studentSection: uJson['student_section'],
        academicYear: uJson['academic_year'],
      );

      // Perform initial cache load
      await syncData();
      return _currentUser!;
    } else {
      try {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Authentication failed.');
      } catch (_) {
        throw Exception('Authentication failed. Server returned an unexpected response (Status ${response.statusCode}).');
      }
    }
  }

  Future<UserModel> registerParent({
    required String name,
    required String email,
    required String password,
    required String studentName,
    required String sectionName,
    required String gradeLevel,
    required String academicYear,
    required String certificateFilename,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register-parent'),
      headers: _headers,
      body: json.encode({
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'student_name': studentName,
        'certificate_filename': certificateFilename,
        // Send simulated scan text if testing invalid/outdated certificates
        'certificate_content_mock': 'STATUS: ENROLLED. STUDENT: $studentName. PARENT: ${name.toUpperCase()}. SECTION: $sectionName. AY: $academicYear.',
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _token = data['token'];

      final uJson = data['user'];
      _currentUser = UserModel(
        id: uJson['id'].toString(),
        email: uJson['email'],
        name: uJson['name'],
        role: UserRole.parent,
        studentName: uJson['student_name'],
        studentGrade: uJson['student_grade'],
        studentSection: uJson['student_section'],
        academicYear: uJson['academic_year'],
        avatarUrl: uJson['avatar_url'],
      );

      await syncData();
      return _currentUser!;
    } else {
      final error = json.decode(response.body);
      String msg = 'Registration failed.';
      if (error['message'] != null) {
        msg = error['message'];
      } else if (error['errors'] != null) {
        final errors = error['errors'] as Map;
        if (errors.isNotEmpty) {
          final firstVal = errors.values.first;
          if (firstVal is List && firstVal.isNotEmpty) {
            msg = firstVal.first.toString();
          } else {
            msg = firstVal.toString();
          }
        }
      }
      throw Exception(msg);
    }
  }

  void logout() {
    _token = null;
    _currentUser = null;
    _reports.clear();
    _meetings.clear();
    _messages.clear();
    _timelines.clear();
    _users.clear();
    notifyListeners();
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: _headers,
      body: json.encode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['message'] ?? 'Password update failed.');
    }
  }

  Future<void> updateProfilePicture(String avatarUrl) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/update-avatar'),
      headers: _headers,
      body: json.encode({
        'avatar_url': avatarUrl,
      }),
    );

    if (response.statusCode == 200) {
      _currentUser = _currentUser!.copyWith(avatarUrl: avatarUrl);
      notifyListeners();
    } else {
      throw Exception('Failed to update avatar.');
    }
  }

  // --- REPORTING LIFECYCLE ---

  List<ReportModel> getReports() {
    return _reports;
  }

  ReportModel? getReportById(String id) {
    return _reports.firstWhere((r) => r.id == id);
  }

  Future<ReportModel> submitReport({
    required String title,
    required String description,
    required String category,
    required DateTime incidentDate,
    required String incidentLocation,
    String? evidenceUrl,
    required String evidenceVerificationState,
    String? evidenceVerificationDetails,
    String? aiSummary,
    String? bullyName,
    String? bullyGradeSection,
    List<String>? witnesses,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reports'),
      headers: _headers,
      body: json.encode({
        'title': title,
        'description': description,
        'category': category,
        'incident_date': incidentDate.toIso8601String(),
        'incident_location': incidentLocation,
        'evidence_filename': evidenceUrl,
        'bully_name': bullyName,
        'bully_grade_section': bullyGradeSection,
        'witnesses': witnesses,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final item = json.decode(response.body);
      final newReport = ReportModel(
        id: item['id'].toString(),
        parentId: item['parent_id'].toString(),
        parentName: item['parent_name'] ?? 'Parent',
        studentName: item['student_name'] ?? 'Student',
        studentSection: item['student_section'] ?? '',
        studentGrade: item['student_grade'] ?? '',
        title: item['title'] ?? '',
        description: item['description'] ?? '',
        category: item['category'] ?? '',
        incidentDate: DateTime.parse(item['incident_date']),
        incidentLocation: item['incident_location'] ?? '',
        evidenceUrl: item['evidence_url'],
        evidenceVerificationState: item['evidence_verification_state'] ?? 'Unverified',
        evidenceVerificationDetails: item['evidence_verification_details'],
        aiSummary: item['ai_summary'],
        status: item['status'] ?? 'Pending',
        disciplineAction: item['discipline_action'],
        disciplineNotes: item['discipline_notes'],
        appealedReason: item['appealed_reason'],
        appealCount: item['appeal_count'] ?? 0,
        createdAt: DateTime.parse(item['created_at']),
        bullyName: item['bully_name'],
        bullyGradeSection: item['bully_grade_section'],
        witnesses: item['witnesses'] != null ? List<String>.from(item['witnesses']) : null,
      );

      // Cache the new report locally and notify listeners
      _reports.insert(0, newReport);
      notifyListeners();
      
      // Asynchronously trigger sync to align background cache
      syncData();
      
      return newReport;
    } else {
      try {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to submit report.');
      } catch (_) {
        throw Exception('Failed to submit report. Server returned an unexpected response (Status ${response.statusCode}).');
      }
    }
  }

  List<UserModel> getParentsList() {
    return _users.values.toList();
  }

  // --- MEETINGS ---

  List<MeetingModel> getMeetingsForReport(String reportId) {
    // Return cache. Trigger async update
    _asyncFetchMeetings(reportId);
    return _meetings.where((m) => m.reportId == reportId).toList();
  }

  Future<void> _asyncFetchMeetings(String reportId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports/$reportId/meetings'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        bool changed = false;

        for (var item in data) {
          final id = item['id'].toString();
          if (!_meetings.any((m) => m.id == id)) {
            _meetings.add(MeetingModel(
              id: id,
              reportId: item['report_id'].toString(),
              scheduledByUserId: item['scheduled_by_user_id'].toString(),
              scheduledByUserName: item['scheduled_by_user_name'],
              scheduledByUserRole: item['scheduled_by_user_role'],
              meetingDate: DateTime.parse(item['meeting_date']),
              notes: item['notes'] ?? '',
              meetingType: item['meeting_type'] ?? 'In-Person',
              createdAt: DateTime.parse(item['created_at']),
            ));
            changed = true;
          }
        }
        if (changed) notifyListeners();
      }
    } catch (_) {}
  }

  Future<MeetingModel> scheduleMeeting({
    required String reportId,
    required DateTime meetingDate,
    required String notes,
    required String meetingType,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/meetings'),
      headers: _headers,
      body: json.encode({
        'report_id': reportId,
        'meeting_date': meetingDate.toIso8601String(),
        'notes': notes,
        'meeting_type': meetingType,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      await syncData();
      await _asyncFetchMeetings(reportId);
      return _meetings.firstWhere((m) => m.reportId == reportId);
    } else {
      try {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to schedule meeting.');
      } catch (_) {
        throw Exception('Failed to schedule meeting. Server returned an unexpected response (Status ${response.statusCode}).');
      }
    }
  }

  Future<MeetingModel> rescheduleMeeting({
    required String meetingId,
    required DateTime newDate,
    required String newNotes,
    required String newType,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/meetings/$meetingId'),
      headers: _headers,
      body: json.encode({
        'meeting_date': newDate.toIso8601String(),
        'notes': newNotes,
        'meeting_type': newType,
      }),
    );

    if (response.statusCode == 200) {
      // Update cache
      final idx = _meetings.indexWhere((m) => m.id == meetingId);
      if (idx != -1) {
        _meetings[idx] = _meetings[idx].copyWith(
          meetingDate: newDate,
          notes: newNotes,
          meetingType: newType,
        );
      }
      await syncData();
      notifyListeners();
      return _meetings[idx];
    } else {
      try {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to reschedule meeting.');
      } catch (_) {
        throw Exception('Failed to reschedule meeting. Server returned an unexpected response (Status ${response.statusCode}).');
      }
    }
  }

  // --- CHATS ---

  List<ChatMessage> getMessagesForMeeting(String meetingId) {
    _asyncFetchChat(meetingId);
    return _messages.where((m) => m.meetingId == meetingId).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> _asyncFetchChat(String meetingId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/meetings/$meetingId/chat'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        bool changed = false;

        for (var item in data) {
          final id = item['id'].toString();
          if (!_messages.any((m) => m.id == id)) {
            _messages.add(ChatMessage(
              id: id,
              meetingId: item['meeting_id'].toString(),
              senderId: item['sender_id'].toString(),
              senderName: item['sender_name'],
              senderRole: item['sender_role'],
              message: item['message'],
              timestamp: DateTime.parse(item['created_at']),
              isReadByReceiver: item['is_read'] == 1 || item['is_read'] == true,
            ));
            changed = true;
          }
        }
        if (changed) notifyListeners();
      }
    } catch (_) {}
  }

  int getUnreadMessageCount(String meetingId) {
    if (_currentUser == null) return 0;
    return _messages
        .where((m) => m.meetingId == meetingId && m.senderId != _currentUser!.id && !m.isReadByReceiver)
        .length;
  }

  void markMessagesAsRead(String meetingId) async {
    if (_currentUser == null) return;
    
    // Optimistic cache update
    bool updated = false;
    for (int i = 0; i < _messages.length; i++) {
      if (_messages[i].meetingId == meetingId && _messages[i].senderId != _currentUser!.id && !_messages[i].isReadByReceiver) {
        _messages[i] = _messages[i].copyWith(isReadByReceiver: true);
        updated = true;
      }
    }
    if (updated) notifyListeners();

    // Call API
    try {
      await http.post(
        Uri.parse('$baseUrl/meetings/$meetingId/chat/read'),
        headers: _headers,
      );
    } catch (_) {}
  }

  Future<ChatMessage> sendChatMessage({
    required String meetingId,
    required String messageText,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: _headers,
      body: json.encode({
        'meeting_id': meetingId,
        'message': messageText,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      await _asyncFetchChat(meetingId);
      return _messages.lastWhere((m) => m.meetingId == meetingId && m.senderId == _currentUser!.id);
    } else {
      throw Exception('Failed to send message.');
    }
  }

  // --- ACTIONS ---

  Future<void> escalateReport(String reportId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reports/$reportId/escalate'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      await syncData();
    } else {
      try {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to escalate report.');
      } catch (_) {
        throw Exception('Failed to escalate report. Server returned an unexpected response (Status ${response.statusCode}).');
      }
    }
  }

  Future<void> resolveReport({
    required String reportId,
    required String disciplineAction,
    required String disciplineNotes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reports/$reportId/resolve'),
      headers: _headers,
      body: json.encode({
        'discipline_action': disciplineAction,
        'discipline_notes': disciplineNotes,
      }),
    );

    if (response.statusCode == 200) {
      await syncData();
    } else {
      try {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to resolve report.');
      } catch (_) {
        throw Exception('Failed to resolve report. Server returned an unexpected response (Status ${response.statusCode}).');
      }
    }
  }

  Future<void> appealReport({
    required String reportId,
    required String reason,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reports/$reportId/appeal'),
      headers: _headers,
      body: json.encode({
        'reason': reason,
      }),
    );

    if (response.statusCode == 200) {
      await syncData();
    } else {
      try {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to submit appeal.');
      } catch (_) {
        throw Exception('Failed to submit appeal. Server returned an unexpected response (Status ${response.statusCode}).');
      }
    }
  }

  Future<void> reAppealReport({
    required String reportId,
    required String reason,
    String? comments,
    String? newEvidenceUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reports/$reportId/re-appeal'),
      headers: _headers,
      body: json.encode({
        'reason': reason,
        if (comments != null) 'comments': comments,
        if (newEvidenceUrl != null) 'new_evidence_url': newEvidenceUrl,
      }),
    );

    if (response.statusCode == 200) {
      await syncData();
    } else {
      try {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to submit re-appeal.');
      } catch (_) {
        throw Exception('Failed to submit re-appeal. Server returned an unexpected response (Status ${response.statusCode}).');
      }
    }
  }

  // --- TIMELINE ---

  List<TimelineEvent> getTimelineEvents(String reportId) {
    _asyncFetchTimeline(reportId);
    return _timelines.where((t) => t.reportId == reportId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> _asyncFetchTimeline(String reportId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reports/$reportId/timeline'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        bool changed = false;

        for (var item in data) {
          final id = item['id'].toString();
          if (!_timelines.any((t) => t.id == id)) {
            _timelines.add(TimelineEvent(
              id: id,
              reportId: item['report_id'].toString(),
              title: item['title'] ?? '',
              description: item['description'] ?? '',
              actorName: item['actor_name'] ?? '',
              actorRole: item['actor_role'] ?? 'System',
              timestamp: DateTime.parse(item['created_at']),
            ));
            changed = true;
          }
        }
        if (changed) notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> updateAiSummary(String reportId, String summary) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reports/$reportId/ai-summary'),
      headers: _headers,
      body: json.encode({
        'ai_summary': summary,
      }),
    );

    if (response.statusCode == 200) {
      final idx = _reports.indexWhere((r) => r.id == reportId);
      if (idx != -1) {
        _reports[idx] = _reports[idx].copyWith(aiSummary: summary);
      }
      notifyListeners();
    } else {
      try {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to save AI summary.');
      } catch (_) {
        throw Exception('Failed to save AI summary. Server returned an unexpected response (Status ${response.statusCode}).');
      }
    }
  }

  Future<void> addTimelineNote(String reportId, String description) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reports/$reportId/timeline'),
      headers: _headers,
      body: json.encode({
        'description': description,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      await syncData();
      await _asyncFetchTimeline(reportId);
    } else {
      try {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to add timeline note.');
      } catch (_) {
        throw Exception('Failed to add timeline note. Server returned an unexpected response (Status ${response.statusCode}).');
      }
    }
  }
}
