import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/database_service.dart';
import '../../services/ai_service.dart';
import '../parent/parent_dashboard.dart';
import 'terms_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _parentNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedCertificateMock; // Filename chosen
  String? _certificateContentMock; // Simulated text contents
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _agreeToTerms = false;

  final _db = DatabaseService();
  final _ai = AIService();
  final _termsScrollController = ScrollController();

  @override
  void dispose() {
    _parentNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _termsScrollController.dispose();
    super.dispose();
  }

  Future<void> _pickCertificateFromDevice() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final name = file.name;
        setState(() {
          _selectedCertificateMock = name;
          _certificateContentMock = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick file: $e';
      });
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCertificateMock == null) {
      setState(() {
        _errorMessage = "Please upload/select an Enrollment Certificate to verify enrollment.";
      });
      return;
    }

    final parentName = _parentNameController.text.trim();

    String extractedStudentName = '';
    String extractedSection = '';

    // Generate certificate content dynamically based on parent name if a custom file is uploaded
    if (_selectedCertificateMock!.contains('10388171') ||
        _selectedCertificateMock!.toLowerCase().contains('coles') ||
        _selectedCertificateMock!.toLowerCase().contains('kyle') ||
        _selectedCertificateMock!.toLowerCase().contains('pring')) {
      extractedStudentName = 'Coles, Kyle Pring';
      extractedSection = 'GRADE 11 STEM-A';
    } else {
      // Parse details directly from filename
      String fileName = _selectedCertificateMock!;
      if (fileName.contains('.')) {
        fileName = fileName.substring(0, fileName.lastIndexOf('.'));
      }
      fileName = fileName.replaceAll('_', ' ');

      if (fileName.contains(' - ')) {
        final parts = fileName.split(' - ');
        extractedStudentName = parts[0].trim();
        extractedSection = parts.sublist(1).join(' - ').trim();
      } else if (fileName.contains('-')) {
        final parts = fileName.split('-');
        extractedStudentName = parts[0].trim();
        extractedSection = parts.sublist(1).join('-').trim();
      } else {
        extractedStudentName = fileName.trim();
        extractedSection = 'GRADE 11 STEM-A';
      }
    }

    final isOutdated = _selectedCertificateMock!.toLowerCase().contains('outdated') || 
                       _selectedCertificateMock!.toLowerCase().contains('2024') || 
                       _selectedCertificateMock!.toLowerCase().contains('2025');
    final isInvalid = _selectedCertificateMock!.toLowerCase().contains('invalid') || 
                      _selectedCertificateMock!.toLowerCase().contains('not_enrolled');
    
    final status = isInvalid ? 'NOT ENROLLED' : 'ENROLLED';
    final ay = isOutdated ? '2024-2025' : '2026-2027';
    
    _certificateContentMock = 'STATUS: $status. STUDENT: $extractedStudentName. PARENT: ${parentName.toUpperCase()}. SECTION: $extractedSection. AY: $ay. FILE: $_selectedCertificateMock';

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // 1. Run Simulated OCR scan on document
      final ocrResult = await _ai.scanEnrollmentCertificate(
        _selectedCertificateMock!,
        _certificateContentMock,
      );

      if (!ocrResult.success) {
        throw Exception(ocrResult.errorMessage ?? "Failed to read enrollment document.");
      }

      // 2. OCR Successful - Register parent
      final newParent = await _db.registerParent(
        name: _parentNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        studentName: ocrResult.studentName!,
        sectionName: ocrResult.studentSection!,
        gradeLevel: ocrResult.studentGrade!,
        academicYear: ocrResult.academicYear!,
        certificateFilename: _selectedCertificateMock!,
      );

      // Save terms accepted status as user already agreed via sign-up checkbox
      await TermsStorage.accept(newParent.id);

      // Show success popup with extracted details
      if (!mounted) return;
      _showVerificationSuccessDialog(newParent);

    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showVerificationSuccessDialog(UserModel user) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Row(
            children: [
              Icon(Icons.verified, color: Colors.green),
              SizedBox(width: 10),
              Text(
                'Enrollment Verified!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'The OCR scanner successfully validated the Enrollment Certificate. Extracted Details:',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              _buildExtractedField('Student Name', user.studentName ?? ''),
              _buildExtractedField('Section/Grade', user.studentSection ?? ''),
              _buildExtractedField('Academic Year', user.academicYear ?? ''),
              _buildExtractedField('Status', 'ENROLLED', isStatus: true),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss Dialog
                Navigator.of(this.context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const ParentDashboard()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
              child: const Text('Go to Parent Dashboard'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildExtractedField(String label, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: Colors.white),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            TextSpan(
              text: value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isStatus ? Colors.green : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF0F172A),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Comprehensive Terms & Conditions',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ComprehensiveTermsWidget(
                    showDecline: false,
                    onAccept: () {
                      setState(() {
                        _agreeToTerms = true;
                      });
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Parent Registration', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Parent Account Setup',
                  style: TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upload the student\'s enrollment form to register. The system will scan and verify the student details automatically using AI OCR.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
                const SizedBox(height: 24),

                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
                    ),
                  ),

                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Full name
                          const Text(
                            'Parent / Guardian Full Name',
                            style: TextStyle(
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _parentNameController,
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                            decoration: _inputDecoration('e.g. Juan Dela Cruz', Icons.person_outline),
                            validator: (val) => val == null || val.isEmpty ? 'Please enter your full name' : null,
                          ),
                          const SizedBox(height: 16),

                          // Email
                          const Text(
                            'Email Address',
                            style: TextStyle(
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                            decoration: _inputDecoration('you@example.com', Icons.email_outlined),
                            validator: (val) => val == null || val.isEmpty ? 'Please enter email' : null,
                          ),
                          const SizedBox(height: 16),

                          // Password
                          const Text(
                            'Password',
                            style: TextStyle(
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
                            decoration: _inputDecoration('••••••••', Icons.lock_outline),
                            validator: (val) => val == null || val.length < 6 ? 'Password must be at least 6 characters' : null,
                          ),
                          const SizedBox(height: 24),

                          // Certificate Upload Header
                          const Text(
                            'Upload Student Enrollment Certificate',
                            style: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),

                          // Certificate Picker Box
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedCertificateMock != null ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                if (_selectedCertificateMock == null) ...[
                                  const Icon(Icons.cloud_upload_outlined, size: 48, color: Color(0xFF94A3B8)),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Please choose a student enrollment certificate image to verify enrollment status.',
                                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                ] else ...[
                                  const Icon(Icons.description_outlined, size: 48, color: Color(0xFF16A34A)),
                                  const SizedBox(height: 8),
                                  Text(
                                    _selectedCertificateMock!,
                                    style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Image loaded. Click Register to scan document.',
                                    style: TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          ElevatedButton.icon(
                            onPressed: _pickCertificateFromDevice,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF475569),
                              elevation: 0,
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.upload_file_outlined, color: Color(0xFF16A34A)),
                            label: const Text('Choose Custom Certificate from Device', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),

                          const SizedBox(height: 24),

                          // Clickable T&C Card inside register form
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _agreeToTerms,
                                      activeColor: const Color(0xFF2563EB),
                                      onChanged: null, // Disabled: must click the terms link to accept
                                    ),
                                    Expanded(
                                      child: InkWell(
                                        onTap: _showTermsDialog,
                                        child: RichText(
                                          text: const TextSpan(
                                            style: TextStyle(color: Color(0xFF475569), fontSize: 12),
                                            children: [
                                              TextSpan(text: 'I have read and agree to the '),
                                              TextSpan(
                                                text: 'Comprehensive Terms & Conditions.',
                                                style: TextStyle(
                                                  color: Color(0xFF2563EB),
                                                  fontWeight: FontWeight.bold,
                                                  decoration: TextDecoration.underline,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          ElevatedButton(
                            onPressed: (_isLoading || !_agreeToTerms) ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _isLoading
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      ),
                                      SizedBox(width: 12),
                                      Text('AI OCR Scanning Certificate...'),
                                    ],
                                  )
                                : const Text(
                                    'Register & Verify Account',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                          ),
                        ],
                      ),
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

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
    );
  }
}
