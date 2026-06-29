import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/report_model.dart';
import '../../widgets/status_badge.dart';
import '../auth/login_screen.dart';
import 'submit_report.dart';
import 'report_detail.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  final _db = DatabaseService();
  bool _showResolved = false;

  // Settings fields
  final _passwordFormKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _isSavingPassword = false;
  String? _passwordError;
  String? _passwordSuccess;

  // Preset avatars matching Unsplash references
  final List<String> _presetAvatars = [
    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150', // Female
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150', // Male
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150', // Alternative Female
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150', // Alternative Male
  ];

  @override
  void initState() {
    super.initState();
    _db.addListener(_onDbUpdate);
  }

  @override
  void dispose() {
    _db.removeListener(_onDbUpdate);
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _onDbUpdate() {
    if (mounted) setState(() {});
  }

  void _handleLogout() {
    _db.logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _changePassword(StateSetter dialogSetState) async {
    if (!_passwordFormKey.currentState!.validate()) return;
    dialogSetState(() {
      _isSavingPassword = true;
      _passwordError = null;
      _passwordSuccess = null;
    });

    try {
      await _db.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );
      dialogSetState(() {
        _passwordSuccess = "Password updated successfully.";
        _currentPasswordController.clear();
        _newPasswordController.clear();
      });
    } catch (e) {
      dialogSetState(() {
        _passwordError = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      dialogSetState(() {
        _isSavingPassword = false;
      });
    }
  }

  void _changeAvatar(String url) async {
    await _db.updateProfilePicture(url);
    if (!mounted) return;
    Navigator.of(context).pop(); // Close avatar selector / settings dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile picture updated successfully.')),
    );
  }

  void _showSettingsDialog() {
    final parent = _db.currentUser;
    if (parent == null) return;

    // Reset password messages when opening settings
    _passwordError = null;
    _passwordSuccess = null;
    _currentPasswordController.clear();
    _newPasswordController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profile & Settings',
                    style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar & Info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: parent.avatarUrl != null ? NetworkImage(parent.avatarUrl!) : null,
                          backgroundColor: const Color(0xFF2563EB),
                          child: parent.avatarUrl == null
                              ? Text(
                                  parent.name.substring(0, 2).toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                parent.name,
                                style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                parent.email,
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Avatar Selection presets
                    const Text(
                      'Choose Preset Avatar',
                      style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _presetAvatars.map((url) {
                        final isSelected = parent.avatarUrl == url;
                        return InkWell(
                          onTap: () => _changeAvatar(url),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(url),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 16),

                    // Student details helper card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LINKED STUDENT',
                            style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Name: ${parent.studentName}',
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Class: ${parent.studentGrade} - ${parent.studentSection}',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                          ),
                          Text(
                            'Academic Year: ${parent.academicYear}',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 16),

                    // Password update form
                    const Text(
                      'Update Password',
                      style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Form(
                      key: _passwordFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_passwordSuccess != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: Text(_passwordSuccess!, style: const TextStyle(color: Color(0xFF16A34A), fontSize: 12)),
                            ),
                          if (_passwordError != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFCA5A5)),
                              ),
                              child: Text(_passwordError!, style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12)),
                            ),
                          TextFormField(
                            controller: _currentPasswordController,
                            obscureText: true,
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                            decoration: _dialogInputDecoration('Current Password', Icons.lock_outline),
                            validator: (val) => val == null || val.isEmpty ? 'Enter current password' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _newPasswordController,
                            obscureText: true,
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                            decoration: _dialogInputDecoration('New Password', Icons.lock_open),
                            validator: (val) => val == null || val.length < 6 ? 'Must be at least 6 characters' : null,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _isSavingPassword ? null : () => _changePassword(dialogSetState),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: _isSavingPassword
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _dialogInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
      prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

  @override
  Widget build(BuildContext context) {
    final parent = _db.currentUser;
    if (parent == null) return const SizedBox();

    final allReports = _db.getReports();
    final activeReports = allReports.where((r) => r.status != 'resolved' && r.status != 'closed').toList();
    final resolvedReports = allReports.where((r) => r.status == 'resolved' || r.status == 'closed').toList();
    final meetingsCount = allReports.where((r) => r.status == 'scheduled_meeting').length;

    final currentList = _showResolved ? resolvedReports : activeReports;

    final double screenWidth = MediaQuery.of(context).size.width;
    final double childAspectRatio = screenWidth < 360 ? 1.2 : (screenWidth < 450 ? 1.5 : 1.9);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_outlined, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HAYAGSYNC',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
                ),
                Text(
                  'Parent Portal | ${parent.studentGrade}',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: _showSettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sign Out',
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SubmitReportScreen()),
          );
        },
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 2,
        icon: const Icon(Icons.add_comment_outlined, size: 20),
        label: const Text('New Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 4 Statistics Cards Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: childAspectRatio,
                  children: [
                    _buildStatCard('Total Reports', allReports.length, const Color(0xFF1E293B), Colors.white),
                    _buildStatCard('Active Cases', activeReports.length, const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
                    _buildStatCard('Meetings Set', meetingsCount, const Color(0xFF7C3AED), const Color(0xFFF5F3FF)),
                    _buildStatCard('Resolved', resolvedReports.length, const Color(0xFF16A34A), const Color(0xFFF0FDF4)),
                  ],
                ),
                const SizedBox(height: 24),

                // Inline tab buttons (Active vs Resolved toggle)
                Row(
                  children: [
                    _buildTabButton('Active Reports', activeReports.length, !_showResolved, () {
                      setState(() => _showResolved = false);
                    }),
                    const SizedBox(width: 10),
                    _buildTabButton('Resolved Cases', resolvedReports.length, _showResolved, () {
                      setState(() => _showResolved = true);
                    }, activeColor: const Color(0xFF16A34A)),
                  ],
                ),
                const SizedBox(height: 16),

                // Reports List view
                _buildReportsList(currentList, isResolvedTab: _showResolved),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            value.toString(),
            style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int count, bool isActive, VoidCallback onTap, {Color activeColor = const Color(0xFF2563EB)}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.white,
            border: Border.all(color: isActive ? activeColor : const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              '$label ($count)',
              style: TextStyle(
                color: isActive ? Colors.white : const Color(0xFF475569),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportsList(List<ReportModel> reports, {required bool isResolvedTab}) {
    if (reports.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              isResolvedTab ? Icons.verified_user_outlined : Icons.inbox_outlined,
              size: 44,
              color: const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 12),
            Text(
              isResolvedTab ? 'No resolved cases yet.' : 'No active reports.',
              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              isResolvedTab
                  ? 'When an adviser resolves your case, details will appear here.'
                  : 'Click "New Report" to submit your first case.',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final report = reports[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReportDetailScreen(reportId: report.id),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatusBadge(status: report.status),
                      Text(
                        report.createdAt.toLocal().toString().substring(0, 10),
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    report.title,
                    style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '${report.category} · ${report.incidentLocation}',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      if (report.evidenceVerificationState != 'Unverified') ...[
                        Icon(
                          report.evidenceVerificationState == 'Verified' ? Icons.check_circle_outline : Icons.warning_amber_outlined,
                          size: 13,
                          color: report.evidenceVerificationState == 'Verified' ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          report.evidenceVerificationState == 'Verified' ? 'Evidence Checked' : 'AI Flagged',
                          style: TextStyle(
                            color: report.evidenceVerificationState == 'Verified' ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
