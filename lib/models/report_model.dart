class ReportModel {
  final String id;
  final String parentId;
  final String parentName;
  final String studentName;
  final String studentSection;
  final String studentGrade;
  final String title;
  final String description;
  final String category;
  final DateTime incidentDate;
  final String incidentLocation;
  final String? evidenceUrl;
  final String evidenceVerificationState; // 'Verified', 'Suspected AI Generated', 'Suspected Google Image', 'Unverified'
  final String? evidenceVerificationDetails;
  final String? aiSummary;
  final String status; // 'Pending', 'Under Review', 'Scheduled', 'Escalated', 'Resolved'
  final String? disciplineAction; // 'Warning', 'Counseling', 'Mediation', 'Suspension', 'Other'
  final String? disciplineNotes;
  final String? appealedReason;
  final int appealCount;
  final DateTime createdAt;
  final String? bullyName;
  final String? bullyGradeSection;
  final List<String>? witnesses;

  ReportModel({
    required this.id,
    required this.parentId,
    required this.parentName,
    required this.studentName,
    required this.studentSection,
    required this.studentGrade,
    required this.title,
    required this.description,
    required this.category,
    required this.incidentDate,
    required this.incidentLocation,
    this.evidenceUrl,
    required this.evidenceVerificationState,
    this.evidenceVerificationDetails,
    this.aiSummary,
    required this.status,
    this.disciplineAction,
    this.disciplineNotes,
    this.appealedReason,
    this.appealCount = 0,
    required this.createdAt,
    this.bullyName,
    this.bullyGradeSection,
    this.witnesses,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'parentName': parentName,
      'studentName': studentName,
      'studentSection': studentSection,
      'studentGrade': studentGrade,
      'title': title,
      'description': description,
      'category': category,
      'incidentDate': incidentDate.toIso8601String(),
      'incidentLocation': incidentLocation,
      'evidenceUrl': evidenceUrl,
      'evidenceVerificationState': evidenceVerificationState,
      'evidenceVerificationDetails': evidenceVerificationDetails,
      'aiSummary': aiSummary,
      'status': status,
      'disciplineAction': disciplineAction,
      'disciplineNotes': disciplineNotes,
      'appealedReason': appealedReason,
      'appealCount': appealCount,
      'createdAt': createdAt.toIso8601String(),
      'bully_name': bullyName,
      'bully_grade_section': bullyGradeSection,
      'witnesses': witnesses,
    };
  }

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id']?.toString() ?? '',
      parentId: json['parentId']?.toString() ?? json['parent_id']?.toString() ?? '',
      parentName: json['parentName'] ?? json['parent_name'] ?? '',
      studentName: json['studentName'] ?? json['student_name'] ?? '',
      studentSection: json['studentSection'] ?? json['student_section'] ?? '',
      studentGrade: json['studentGrade'] ?? json['student_grade'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      incidentDate: DateTime.parse(json['incidentDate'] ?? json['incident_date']),
      incidentLocation: json['incidentLocation'] ?? json['incident_location'] ?? '',
      evidenceUrl: json['evidenceUrl'] ?? json['evidence_url'],
      evidenceVerificationState: json['evidenceVerificationState'] ?? json['evidence_verification_state'] ?? 'Unverified',
      evidenceVerificationDetails: json['evidenceVerificationDetails'] ?? json['evidence_verification_details'],
      aiSummary: json['aiSummary'] ?? json['ai_summary'],
      status: json['status'] ?? 'Pending',
      disciplineAction: json['disciplineAction'] ?? json['discipline_action'],
      disciplineNotes: json['disciplineNotes'] ?? json['discipline_notes'],
      appealedReason: json['appealedReason'] ?? json['appealed_reason'],
      appealCount: json['appealCount'] ?? json['appeal_count'] ?? 0,
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
      bullyName: json['bully_name'] ?? json['bullyName'],
      bullyGradeSection: json['bully_grade_section'] ?? json['bullyGradeSection'],
      witnesses: json['witnesses'] != null ? List<String>.from(json['witnesses']) : null,
    );
  }

  ReportModel copyWith({
    String? status,
    String? aiSummary,
    String? evidenceVerificationState,
    String? evidenceVerificationDetails,
    String? disciplineAction,
    String? disciplineNotes,
    String? appealedReason,
    int? appealCount,
    String? bullyName,
    String? bullyGradeSection,
    List<String>? witnesses,
  }) {
    return ReportModel(
      id: id,
      parentId: parentId,
      parentName: parentName,
      studentName: studentName,
      studentSection: studentSection,
      studentGrade: studentGrade,
      title: title,
      description: description,
      category: category,
      incidentDate: incidentDate,
      incidentLocation: incidentLocation,
      evidenceUrl: evidenceUrl,
      evidenceVerificationState: evidenceVerificationState ?? this.evidenceVerificationState,
      evidenceVerificationDetails: evidenceVerificationDetails ?? this.evidenceVerificationDetails,
      aiSummary: aiSummary ?? this.aiSummary,
      status: status ?? this.status,
      disciplineAction: disciplineAction ?? this.disciplineAction,
      disciplineNotes: disciplineNotes ?? this.disciplineNotes,
      appealedReason: appealedReason ?? this.appealedReason,
      appealCount: appealCount ?? this.appealCount,
      createdAt: createdAt,
      bullyName: bullyName ?? this.bullyName,
      bullyGradeSection: bullyGradeSection ?? this.bullyGradeSection,
      witnesses: witnesses ?? this.witnesses,
    );
  }
}
