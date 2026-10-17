import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/user_model.dart';
import '../../models/report_model.dart';
import '../../widgets/status_badge.dart';
import '../auth/login_screen.dart';
import 'staff_report_detail.dart';
import 'ai_summary_screen.dart';
import 'duplicate_manager_screen.dart';
import 'adviser_submit_report.dart';

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _db = DatabaseService();

  String? _selectedStatusFilter;
  String? _selectedSectionFilter; // For Principal/OSD global views

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _db.addListener(_onDbUpdate);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _db.removeListener(_onDbUpdate);
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

  void _toggleStatusFilter(String status) {
    setState(() {
      if (_selectedStatusFilter == status) {
        _selectedStatusFilter = null; // Clear filter on double click
      } else {
        _selectedStatusFilter = status;
      }
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    final staff = _db.currentUser;
    if (staff == null) return const SizedBox();

    // Query reports based on RLS rules
    var reports = _db.getReports();

    // Calculate count for stats cards
    final pendingCount = reports.where((r) => r.status.toLowerCase() == 'pending').length;
    final reviewCount = reports.where((r) => r.status.toLowerCase() == 'under review' || r.status.toLowerCase() == 'under_review').length;
    final scheduledCount = reports.where((r) => r.status.toLowerCase() == 'scheduled' || r.status.toLowerCase() == 'scheduled_meeting').length;
    final escalatedCount = reports.where((r) => r.status.toLowerCase() == 'escalated' || r.status.toLowerCase() == 'escalated to ministrong' || r.status.toLowerCase() == 'escalated to principal').length;
    final resolvedCount = reports.where((r) => r.status.toLowerCase() == 'resolved' || r.status.toLowerCase() == 'closed').length;

    // Apply Status Filter
    if (_selectedStatusFilter != null) {
      if (_selectedStatusFilter == 'resolved') {
        reports = reports.where((r) => r.status.toLowerCase() == 'resolved' || r.status.toLowerCase() == 'closed').toList();
      } else if (_selectedStatusFilter == 'under_review') {
        reports = reports.where((r) => r.status.toLowerCase() == 'under review' || r.status.toLowerCase() == 'under_review').toList();
      } else if (_selectedStatusFilter == 'scheduled_meeting') {
        reports = reports.where((r) => r.status.toLowerCase() == 'scheduled' || r.status.toLowerCase() == 'scheduled_meeting').toList();
      } else if (_selectedStatusFilter == 'escalated') {
        reports = reports.where((r) => r.status.toLowerCase() == 'escalated' || r.status.toLowerCase() == 'escalated to ministrong' || r.status.toLowerCase() == 'escalated to principal').toList();
      } else {
        reports = reports.where((r) => r.status.toLowerCase() == _selectedStatusFilter).toList();
      }
    }

    // Apply Section Filter (Principal/OSD/Ministrong only)
    if ((staff.role == UserRole.principal || staff.role == UserRole.osd || staff.role == UserRole.ministrong_tagasubaybay) && _selectedSectionFilter != null) {
      reports = reports.where((r) => r.studentSection == _selectedSectionFilter).toList();
    }

    final parentsList = _db.getParentsList();

    final allSections = [
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

    // Determine role banner gradient colors
    List<Color> bannerColors;
    String roleBadge;
    if (staff.role == UserRole.adviser) {
      bannerColors = const [Color(0xFF0F766E), Color(0xFF0D9488)]; // Teal
      roleBadge = 'Section Adviser';
    } else if (staff.role == UserRole.principal) {
      bannerColors = const [Color(0xFF1E40AF), Color(0xFF2563EB)]; // Blue
      roleBadge = 'Principal';
    } else if (staff.role == UserRole.ministrong_tagasubaybay) {
      bannerColors = const [Color(0xFF7C3AED), Color(0xFF8B5CF6)]; // Purple
      roleBadge = 'Ministrong Tagasubaybay';
    } else {
      bannerColors = const [Color(0xFF1E293B), Color(0xFF475569)]; // Slate (OSD)
      roleBadge = 'OSD Officer';
    }

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
                  'Staff Portal | $roleBadge',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology_outlined),
            tooltip: 'AI Summaries',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AiSummaryScreen()),
              );
            },
          ),
          if (staff.role == UserRole.principal || staff.role == UserRole.osd)
            IconButton(
              icon: const Icon(Icons.group_off_outlined),
              tooltip: 'Duplicate Accounts Manager',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DuplicateManagerScreen()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sign Out',
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2563EB),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF2563EB),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Incident Management'),
            Tab(icon: Icon(Icons.people_outline), text: 'Parents Directory'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // INCIDENT MANAGEMENT VIEW
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Body Header Banner (Role Gradient)
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: bannerColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: bannerColors.first.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Text(
                              staff.name.substring(0, 2).toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  staff.name,
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        roleBadge,
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (staff.role == UserRole.adviser) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        'Assigned: ${staff.assignedSection}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (staff.role == UserRole.adviser) ...[
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const AdviserSubmitReportScreen()),
                                );
                              },
                              icon: const Icon(Icons.add_alert_outlined, size: 18),
                              label: const Text('Create Incident Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF0F766E),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 2,
                              ),
                            ),
                          ],
                          if (staff.role == UserRole.osd || staff.role == UserRole.ministrong_tagasubaybay) ...[
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: escalatedCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                                boxShadow: [
                                  if (escalatedCount > 0)
                                    BoxShadow(
                                      color: const Color(0xFFEF4444).withOpacity(0.4),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$escalatedCount',
                                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    escalatedCount == 1 ? 'ESCALATION' : 'ESCALATIONS',
                                    style: const TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Statistics Row (Clickable filter cards)
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isMobile = constraints.maxWidth < 600;
                        if (isMobile) {
                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.3,
                            children: [
                              _buildStatCard('Pending', pendingCount, const Color(0xFFCA8A04), const Color(0xFFFEF9C3), 'pending'),
                              _buildStatCard('Under Review', reviewCount, const Color(0xFF2563EB), const Color(0xFFEFF6FF), 'under_review'),
                              _buildStatCard('Meetings', scheduledCount, const Color(0xFF7C3AED), const Color(0xFFF5F3FF), 'scheduled_meeting'),
                              _buildStatCard('Escalated', escalatedCount, const Color(0xFFEA580C), const Color(0xFFFFEDD5), 'escalated'),
                              _buildStatCard('Resolved', resolvedCount, const Color(0xFF16A34A), const Color(0xFFF0FDF4), 'resolved'),
                            ],
                          );
                        } else {
                          return Row(
                            children: [
                              Expanded(child: _buildStatCard('Pending', pendingCount, const Color(0xFFCA8A04), const Color(0xFFFEF9C3), 'pending')),
                              const SizedBox(width: 8),
                              Expanded(child: _buildStatCard('Under Review', reviewCount, const Color(0xFF2563EB), const Color(0xFFEFF6FF), 'under_review')),
                              const SizedBox(width: 8),
                              Expanded(child: _buildStatCard('Meetings', scheduledCount, const Color(0xFF7C3AED), const Color(0xFFF5F3FF), 'scheduled_meeting')),
                              const SizedBox(width: 8),
                              Expanded(child: _buildStatCard('Escalated', escalatedCount, const Color(0xFFEA580C), const Color(0xFFFFEDD5), 'escalated')),
                              const SizedBox(width: 8),
                              Expanded(child: _buildStatCard('Resolved', resolvedCount, const Color(0xFF16A34A), const Color(0xFFF0FDF4), 'resolved')),
                            ],
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    // Filter toolbar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Incident Reports Log',
                              style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            if (_selectedStatusFilter != null) ...[
                              const SizedBox(width: 10),
                              Chip(
                                label: Text(
                                  _selectedStatusFilter!.toUpperCase().replaceAll('_', ' '),
                                  style: const TextStyle(color: Color(0xFF2563EB), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: const Color(0xFFEFF6FF),
                                side: const BorderSide(color: Color(0xFFBFDBFE)),
                                onDeleted: () => setState(() => _selectedStatusFilter = null),
                                deleteIconColor: const Color(0xFF2563EB),
                              ),
                            ],
                            if (_selectedSectionFilter != null) ...[
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(
                                  _selectedSectionFilter!,
                                  style: const TextStyle(color: Color(0xFF0D9488), fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                backgroundColor: const Color(0xFFF0FDFA),
                                side: const BorderSide(color: Color(0xFF99F6E4)),
                                onDeleted: () => setState(() => _selectedSectionFilter = null),
                                deleteIconColor: const Color(0xFF0D9488),
                              ),
                            ],
                          ],
                        ),

                        // Section Dropdown for Admin Roles
                        if (staff.role == UserRole.principal || staff.role == UserRole.osd || staff.role == UserRole.ministrong_tagasubaybay)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedSectionFilter,
                              hint: const Text('Filter Section', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                              underline: const SizedBox(),
                              dropdownColor: Colors.white,
                              style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12),
                              items: [
                                const DropdownMenuItem<String>(value: null, child: Text('All Sections')),
                                ...allSections.map((sec) => DropdownMenuItem<String>(value: sec, child: Text(sec))),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _selectedSectionFilter = val;
                                });
                              },
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Reports Table / List
                    _buildReportsList(reports),
                  ],
                ),
              ),
            ),
          ),

          // PARENTS DIRECTORY VIEW
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      staff.role == UserRole.adviser
                          ? 'Section Registered Directory (${staff.assignedSection})'
                          : 'Global Registered Parent Directory (All Sections)',
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildParentsTable(parentsList),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color, Color bg, String filterValue) {
    final isSelected = _selectedStatusFilter == filterValue;
    return Card(
      color: isSelected ? bg : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? color : const Color(0xFFE2E8F0),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () => _toggleStatusFilter(filterValue),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportsList(List<ReportModel> reports) {
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
            Icon(Icons.rule_folder_outlined, size: 44, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            const Text(
              'No incident reports found matching this criteria.',
              style: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold),
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
                  builder: (_) => StaffReportDetailScreen(reportId: report.id),
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
                    style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.description,
                    style: const TextStyle(color: Color(0xFF475569), fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_outline, size: 13, color: Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Text(
                                  'Victim: ${report.studentName} (${report.studentGrade})',
                                  style: const TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.class_outlined, size: 13, color: Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Text(
                                  'Section: ${report.studentSection}',
                                  style: const TextStyle(color: Color(0xFF475569), fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF94A3B8)),
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

  Widget _buildParentsTable(List<UserModel> parents) {
    if (parents.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 44, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            const Text(
              'No parents registered in this directory yet.',
              style: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 0,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          constraints: const BoxConstraints(minWidth: 500),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(2),
            },
            border: const TableBorder(
              horizontalInside: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
            children: [
              // Table Header
              const TableRow(
                decoration: BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text('Parent Name', style: TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text('Student Name', style: TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text('Section', style: TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              
              // Table Content
              ...parents.map((p) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(p.name, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(p.studentName ?? 'N/A', style: const TextStyle(color: Color(0xFF334155), fontSize: 12)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(p.studentSection ?? 'N/A', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
