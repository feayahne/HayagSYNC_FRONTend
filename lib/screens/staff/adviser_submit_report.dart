import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/database_service.dart';
import '../../services/ai_service.dart';
import '../../models/student_model.dart';
import '../../widgets/glass_panel.dart';

class AdviserSubmitReportScreen extends StatefulWidget {
  const AdviserSubmitReportScreen({super.key});

  @override
  State<AdviserSubmitReportScreen> createState() => _AdviserSubmitReportScreenState();
}

class _AdviserSubmitReportScreenState extends State<AdviserSubmitReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _db = DatabaseService();
  final _aiService = AIService();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController(text: 'Classroom');
  final _bullyNameController = TextEditingController();
  final _bullyGradeSectionController = TextEditingController();
  final _witnessesController = TextEditingController();
  final _studentNameController = TextEditingController();

  String _selectedSection = 'Grade 11 - STEM A';
  String _selectedGrade = 'Grade 11';
  String _selectedCategory = 'Physical';
  String _selectedUrgency = 'High';
  DateTime _incidentDate = DateTime.now();

  StudentModel? _selectedStudent;
  StudentModel? _selectedBullyStudent;
  List<StudentModel> _filteredSectionStudents = [];
  List<StudentModel> _allSystemStudents = [];

  String? _evidenceFileName;
  String? _evidenceFilePath;
  bool _isAnalyzingEvidence = false;
  PhotoVerificationResult? _aiVerificationResult;
  bool _isSubmitting = false;

  final List<String> _allSections = [
    'Grade 7 - Mahogany',
    'Grade 7 - Narra',
    'Grade 8 - Uranus',
    'Grade 8 - Venus',
    'Grade 9 - Eagle',
    'Grade 9 - Falcon',
    'Grade 10 - Rizal',
    'Grade 10 - Bonifacio',
    'Grade 10 - Jupiter',
    'Grade 11 - STEM A',
    'Grade 11 - ABM A',
    'Grade 12 - STEM A',
    'Grade 12 - ABM A',
  ];

  final List<String> _categories = [
    'Physical',
    'Verbal',
    'Relational / Social',
    'Cyber',
    'Sexual',
    'Extortion / Threat',
  ];

  final List<String> _locations = [
    'Classroom',
    'Canteen / Cafeteria',
    'School Hallway',
    'Gymnasium / Court',
    'Playground',
    'Washroom / Restroom',
    'Online / Social Media',
    'School Gate / Perimeter',
    'Other Location',
  ];

  // Comprehensive master roster linking fake/pre-seeded students to active parent accounts
  final List<StudentModel> _masterPreseededStudents = [
    // Grade 7
    StudentModel(id: 'st_7_1', parentId: 'p_7_1', name: 'Sophia Mahogany', grade: 'Grade 7', section: 'Grade 7 - Mahogany', academicYear: '2025-2026'),
    StudentModel(id: 'st_7_2', parentId: 'p_7_2', name: 'Ethan Santos', grade: 'Grade 7', section: 'Grade 7 - Mahogany', academicYear: '2025-2026'),
    StudentModel(id: 'st_7_3', parentId: 'p_7_3', name: 'Mateo Narra', grade: 'Grade 7', section: 'Grade 7 - Narra', academicYear: '2025-2026'),
    StudentModel(id: 'st_7_4', parentId: 'p_7_4', name: 'Isabella Cruz', grade: 'Grade 7', section: 'Grade 7 - Narra', academicYear: '2025-2026'),
    
    // Grade 8
    StudentModel(id: 'st_8_1', parentId: 'p_8_1', name: 'Noah Uranus', grade: 'Grade 8', section: 'Grade 8 - Uranus', academicYear: '2025-2026'),
    StudentModel(id: 'st_8_2', parentId: 'p_8_2', name: 'Emma Garcia', grade: 'Grade 8', section: 'Grade 8 - Uranus', academicYear: '2025-2026'),
    StudentModel(id: 'st_8_3', parentId: 'p_8_3', name: 'Oliver Venus', grade: 'Grade 8', section: 'Grade 8 - Venus', academicYear: '2025-2026'),
    StudentModel(id: 'st_8_4', parentId: 'p_8_4', name: 'Ava Mendoza', grade: 'Grade 8', section: 'Grade 8 - Venus', academicYear: '2025-2026'),

    // Grade 9
    StudentModel(id: 'st_9_1', parentId: 'p_9_1', name: 'Lucas Eagle', grade: 'Grade 9', section: 'Grade 9 - Eagle', academicYear: '2025-2026'),
    StudentModel(id: 'st_9_2', parentId: 'p_9_2', name: 'Mia Ramos', grade: 'Grade 9', section: 'Grade 9 - Eagle', academicYear: '2025-2026'),
    StudentModel(id: 'st_9_3', parentId: 'p_9_3', name: 'Benjamin Falcon', grade: 'Grade 9', section: 'Grade 9 - Falcon', academicYear: '2025-2026'),
    StudentModel(id: 'st_9_4', parentId: 'p_9_4', name: 'Charlotte Torres', grade: 'Grade 9', section: 'Grade 9 - Falcon', academicYear: '2025-2026'),

    // Grade 10
    StudentModel(id: 'st_10_1', parentId: 'p_10_1', name: 'Elijah Rizal', grade: 'Grade 10', section: 'Grade 10 - Rizal', academicYear: '2025-2026'),
    StudentModel(id: 'st_10_2', parentId: 'p_10_2', name: 'Amelia Flores', grade: 'Grade 10', section: 'Grade 10 - Rizal', academicYear: '2025-2026'),
    StudentModel(id: 'st_10_3', parentId: 'p_10_3', name: 'Jisung Park', grade: 'Grade 10', section: 'Grade 10 - Bonifacio', academicYear: '2025-2026'),
    StudentModel(id: 'st_10_4', parentId: 'p_10_4', name: 'James Bonifacio', grade: 'Grade 10', section: 'Grade 10 - Bonifacio', academicYear: '2025-2026'),
    StudentModel(id: 'st_10_5', parentId: 'p_10_5', name: 'Jung Woo', grade: 'Grade 10', section: 'Grade 10 - Jupiter', academicYear: '2025-2026'),

    // Grade 11
    StudentModel(id: 'st_11_1', parentId: 'p_11_1', name: 'Juan Dela Cruz Jr.', grade: 'Grade 11', section: 'Grade 11 - STEM A', academicYear: '2025-2026'),
    StudentModel(id: 'st_11_2', parentId: 'p_11_2', name: 'Chenle Zhong', grade: 'Grade 11', section: 'Grade 11 - STEM A', academicYear: '2025-2026'),
    StudentModel(id: 'st_11_3', parentId: 'p_11_3', name: 'Coles, Kyle Pring', grade: 'Grade 11', section: 'Grade 11 - STEM A', academicYear: '2025-2026'),
    StudentModel(id: 'st_11_4', parentId: 'p_11_4', name: 'Alexander Abm', grade: 'Grade 11', section: 'Grade 11 - ABM A', academicYear: '2025-2026'),
    StudentModel(id: 'st_11_5', parentId: 'p_11_5', name: 'Evelyn Castillo', grade: 'Grade 11', section: 'Grade 11 - ABM A', academicYear: '2025-2026'),

    // Grade 12
    StudentModel(id: 'st_12_1', parentId: 'p_12_1', name: 'Jaemin Na', grade: 'Grade 12', section: 'Grade 12 - STEM A', academicYear: '2025-2026'),
    StudentModel(id: 'st_12_2', parentId: 'p_12_2', name: 'Jeno Lee', grade: 'Grade 12', section: 'Grade 12 - STEM A', academicYear: '2025-2026'),
    StudentModel(id: 'st_12_3', parentId: 'p_12_3', name: 'Huang Renjun', grade: 'Grade 12', section: 'Grade 12 - STEM A', academicYear: '2025-2026'),
    StudentModel(id: 'st_12_4', parentId: 'p_12_4', name: 'Haechan Lee', grade: 'Grade 12', section: 'Grade 12 - STEM A', academicYear: '2025-2026'),
    StudentModel(id: 'st_12_5', parentId: 'p_12_5', name: 'Jung Jaehyun', grade: 'Grade 12', section: 'Grade 12 - STEM A', academicYear: '2025-2026'),
    StudentModel(id: 'st_12_6', parentId: 'p_12_6', name: 'Daniel Abm12', grade: 'Grade 12', section: 'Grade 12 - ABM A', academicYear: '2025-2026'),
    StudentModel(id: 'st_12_7', parentId: 'p_12_7', name: 'Sofia Dela Rosa', grade: 'Grade 12', section: 'Grade 12 - ABM A', academicYear: '2025-2026'),
  ];

  @override
  void initState() {
    super.initState();
    _loadAllStudents();
  }

  void _loadAllStudents() {
    final staff = _db.currentUser;
    final defaultSection = staff?.assignedSection ?? 'Grade 11 - STEM A';

    // Merge system DB students with master pre-seeded students
    final allParents = _db.getParentsList();
    final systemList = <StudentModel>[];
    for (final parent in allParents) {
      if (parent.students != null) {
        systemList.addAll(parent.students!);
      }
    }

    final Map<String, StudentModel> mergedMap = {};
    for (final st in _masterPreseededStudents) {
      mergedMap[st.name.toLowerCase()] = st;
    }
    for (final st in systemList) {
      mergedMap[st.name.toLowerCase()] = st;
    }

    setState(() {
      _allSystemStudents = mergedMap.values.toList();
      _selectedSection = _allSections.contains(defaultSection) ? defaultSection : _allSections.first;
      _updateSectionFilter(_selectedSection);
    });
  }

  void _updateSectionFilter(String sectionName) {
    // Extract Grade
    final gradeMatch = RegExp(r'(Grade\s*\d+)', caseSensitive: false).firstMatch(sectionName);
    final grade = gradeMatch != null ? gradeMatch.group(1)! : 'Grade 11';

    // Filter students matching selected section
    final sectionNorm = sectionName.toLowerCase().replaceAll(' ', '').replaceAll('-', '');
    final filtered = _allSystemStudents.where((st) {
      final stNorm = st.section.toLowerCase().replaceAll(' ', '').replaceAll('-', '');
      return stNorm.contains(sectionNorm) || sectionNorm.contains(stNorm);
    }).toList();

    setState(() {
      _selectedSection = sectionName;
      _selectedGrade = grade;
      _filteredSectionStudents = filtered.isNotEmpty ? filtered : _allSystemStudents;

      if (_filteredSectionStudents.isNotEmpty) {
        _selectedStudent = _filteredSectionStudents.first;
        _studentNameController.text = _selectedStudent!.name;
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _bullyNameController.dispose();
    _bullyGradeSectionController.dispose();
    _witnessesController.dispose();
    _studentNameController.dispose();
    super.dispose();
  }

  Future<void> _pickDateAndTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _incidentDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_incidentDate),
    );
    if (time == null) return;

    setState(() {
      _incidentDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickEvidenceFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'mp4'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _evidenceFileName = file.name;
          _evidenceFilePath = file.path;
          _isAnalyzingEvidence = true;
          _aiVerificationResult = null;
        });

        final verification = await _aiService.verifyEvidencePhoto(
          file.name,
          file.size / 1024,
        );

        if (mounted) {
          setState(() {
            _aiVerificationResult = verification;
            _isAnalyzingEvidence = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File selection error: $e')),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final witnessesList = _witnessesController.text.trim().isNotEmpty
          ? _witnessesController.text.split(',').map((w) => w.trim()).where((w) => w.isNotEmpty).toList()
          : null;

      final aiSummaryText = await _aiService.generateReportSummary(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        location: _locationController.text.trim(),
      );

      final bullyName = _selectedBullyStudent != null
          ? _selectedBullyStudent!.name
          : (_bullyNameController.text.trim().isNotEmpty ? _bullyNameController.text.trim() : null);

      final bullySection = _selectedBullyStudent != null
          ? _selectedBullyStudent!.section
          : (_bullyGradeSectionController.text.trim().isNotEmpty ? _bullyGradeSectionController.text.trim() : null);

      await _db.submitAdviserReport(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        incidentDate: _incidentDate,
        incidentLocation: _locationController.text.trim(),
        studentName: _studentNameController.text.trim(),
        studentSection: _selectedSection,
        studentGrade: _selectedGrade,
        studentId: _selectedStudent?.id,
        evidenceUrl: _evidenceFileName,
        evidenceVerificationState: _aiVerificationResult?.state ?? 'Verified',
        evidenceVerificationDetails: _aiVerificationResult?.details,
        aiSummary: aiSummaryText,
        bullyName: bullyName,
        bullyGradeSection: bullySection,
        witnesses: witnessesList,
        urgencyLevel: _selectedUrgency,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Adviser-Observed Incident Report created successfully!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = _db.currentUser;
    final adviserName = staff?.name ?? 'Section Adviser';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adviser Incident Report'),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Banner Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F766E).withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Create Adviser-Initiated Report',
                                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Reporting Adviser: $adviserName',
                                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.4)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.visibility_outlined, color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Adviser-Observed',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Use this form to document incidents witnessed directly during class, activities, or school hours, even if neither student nor parent filed a report.',
                          style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // SECTION 1: INVOLVED STUDENTS & SECTION SELECTORS
                  GlassPanel(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.person_pin_outlined, color: Color(0xFF0F766E)),
                            SizedBox(width: 8),
                            Text(
                              'Involved Students & Section Selection',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // Section Dropdown Selector
                        const Text(
                          'Select Grade & Section *',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedSection,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.class_outlined, color: Color(0xFF0F766E)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: _allSections.map((sec) {
                            return DropdownMenuItem(
                              value: sec,
                              child: Text(sec, style: const TextStyle(fontWeight: FontWeight.bold)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              _updateSectionFilter(val);
                            }
                          },
                        ),

                        const SizedBox(height: 18),

                        // Student / Victim Dropdown Selector (Connected to Parents)
                        const Text(
                          'Select Victim / Involved Student (Linked Parent Profile) *',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<StudentModel>(
                          value: _filteredSectionStudents.contains(_selectedStudent) ? _selectedStudent : (_filteredSectionStudents.isNotEmpty ? _filteredSectionStudents.first : null),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.face, color: Color(0xFF0F766E)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: _filteredSectionStudents.map((st) {
                            return DropdownMenuItem(
                              value: st,
                              child: Text('${st.name} (${st.section})'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedStudent = val;
                                _studentNameController.text = val.name;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 18),

                        // Alleged Bully Student Selector (Dropdown / Manual)
                        const Text(
                          'Select Alleged Bully / Offender (or enter manually)',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<StudentModel?>(
                          value: _selectedBullyStudent,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.warning_amber_outlined, color: Colors.amber),
                            hintText: 'Select student from system roster...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: [
                            const DropdownMenuItem<StudentModel?>(
                              value: null,
                              child: Text('-- Manual Entry / External Offender --', style: TextStyle(color: Colors.grey)),
                            ),
                            ..._allSystemStudents.map((st) {
                              return DropdownMenuItem<StudentModel?>(
                                value: st,
                                child: Text('${st.name} (${st.section})'),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedBullyStudent = val;
                              if (val != null) {
                                _bullyNameController.text = val.name;
                                _bullyGradeSectionController.text = val.section;
                              } else {
                                _bullyNameController.clear();
                                _bullyGradeSectionController.clear();
                              }
                            });
                          },
                        ),

                        if (_selectedBullyStudent == null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _bullyNameController,
                                  decoration: InputDecoration(
                                    labelText: 'Alleged Bully Name',
                                    hintText: 'e.g., Student A',
                                    prefixIcon: const Icon(Icons.person_outline),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _bullyGradeSectionController,
                                  decoration: InputDecoration(
                                    labelText: 'Bully Section / Grade',
                                    hintText: 'e.g., Grade 7 STEM A',
                                    prefixIcon: const Icon(Icons.meeting_room_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SECTION 2: INCIDENT DETAILS
                  GlassPanel(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.assignment_late_outlined, color: Color(0xFF0F766E)),
                            SizedBox(width: 8),
                            Text(
                              'Incident Particulars',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        // Incident Title
                        TextFormField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Report Title / Headline *',
                            hintText: 'e.g., Classroom Verbal & Physical Bullying Incident',
                            prefixIcon: const Icon(Icons.subtitles_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a title' : null,
                        ),

                        const SizedBox(height: 16),

                        // Category & Urgency Row
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                decoration: InputDecoration(
                                  labelText: 'Incident Category *',
                                  prefixIcon: const Icon(Icons.category_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                                onChanged: (v) => setState(() => _selectedCategory = v!),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedUrgency,
                                decoration: InputDecoration(
                                  labelText: 'Urgency / Severity *',
                                  prefixIcon: Icon(
                                    Icons.flag_outlined,
                                    color: _selectedUrgency == 'High'
                                        ? Colors.red
                                        : (_selectedUrgency == 'Moderate' ? Colors.orange : Colors.green),
                                  ),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                items: ['Low', 'Moderate', 'High'].map((u) {
                                  return DropdownMenuItem(
                                    value: u,
                                    child: Text(
                                      '$u Severity',
                                      style: TextStyle(
                                        color: u == 'High' ? Colors.red : (u == 'Moderate' ? Colors.orange.shade800 : Colors.green),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) => setState(() => _selectedUrgency = v!),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Location & Date/Time
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _locations.contains(_locationController.text) ? _locationController.text : _locations.first,
                                decoration: InputDecoration(
                                  labelText: 'Incident Location *',
                                  prefixIcon: const Icon(Icons.place_outlined),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                items: _locations.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _locationController.text = v);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: _pickDateAndTime,
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: 'Date & Time Observed *',
                                    prefixIcon: const Icon(Icons.event_outlined),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: Text(
                                    '${_incidentDate.year}-${_incidentDate.month.toString().padLeft(2, '0')}-${_incidentDate.day.toString().padLeft(2, '0')} ${_incidentDate.hour.toString().padLeft(2, '0')}:${_incidentDate.minute.toString().padLeft(2, '0')}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Description
                        TextFormField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: 'Detailed Observation / Description *',
                            hintText: 'Describe exactly what you witnessed as an Adviser...',
                            alignLabelWithHint: true,
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 60),
                              child: Icon(Icons.description_outlined),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Please enter observation details' : null,
                        ),

                        const SizedBox(height: 16),

                        // Witnesses
                        TextFormField(
                          controller: _witnessesController,
                          decoration: InputDecoration(
                            labelText: 'Witnesses (Optional)',
                            hintText: 'Comma-separated names, e.g., Student C, Mr. Santos',
                            prefixIcon: const Icon(Icons.people_outline),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SECTION 3: EVIDENCE ATTACHMENT
                  GlassPanel(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.attachment_outlined, color: Color(0xFF0F766E)),
                            SizedBox(width: 8),
                            Text(
                              'Evidence & Proof (Optional)',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickEvidenceFile,
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Attach Photo / Video / File'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F766E),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            if (_evidenceFileName != null) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'File: $_evidenceFileName',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ]
                          ],
                        ),

                        if (_isAnalyzingEvidence) ...[
                          const SizedBox(height: 12),
                          const Row(
                            children: [
                              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                              SizedBox(width: 10),
                              Text('Running AI Evidence Verification...', style: TextStyle(color: Color(0xFF0F766E), fontSize: 13)),
                            ],
                          ),
                        ],

                        if (_aiVerificationResult != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _aiVerificationResult!.state == 'Verified'
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _aiVerificationResult!.state == 'Verified'
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF59E0B),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _aiVerificationResult!.state == 'Verified' ? Icons.verified : Icons.warning_amber_rounded,
                                      color: _aiVerificationResult!.state == 'Verified' ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'AI Verification: ${_aiVerificationResult!.state}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _aiVerificationResult!.state == 'Verified' ? const Color(0xFF065F46) : const Color(0xFF92400E),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _aiVerificationResult!.details,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // SUBMIT ACTION BUTTON
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F766E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    child: _isSubmitting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                              SizedBox(width: 12),
                              Text('Submitting Adviser Report...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded),
                              SizedBox(width: 10),
                              Text('Submit Adviser Incident Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
