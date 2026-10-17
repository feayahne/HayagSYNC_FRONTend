import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/student_model.dart';
import '../../models/user_model.dart';

class AiSummaryScreen extends StatefulWidget {
  const AiSummaryScreen({super.key});

  @override
  State<AiSummaryScreen> createState() => _AiSummaryScreenState();
}

class _AiSummaryScreenState extends State<AiSummaryScreen> {
  final _db = DatabaseService();
  String _selectedPeriod = 'weekly'; // weekly, monthly, yearly
  
  // Scoped filters
  StudentModel? _parentSelectedChild;
  String? _selectedClass; // For Principal / OSD / Ministrong
  
  bool _isLoading = false;
  String? _errorMessage;
  String? _summaryText;
  Map<String, dynamic>? _stats;
  String _lastGenerated = 'Never';

  final List<String> _classSections = [
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

  @override
  void initState() {
    super.initState();
    final user = _db.currentUser;
    if (user != null) {
      if (user.role == UserRole.parent) {
        _parentSelectedChild = _db.selectedChild;
      } else if (user.role == UserRole.adviser) {
        _selectedClass = user.assignedSection;
      }
    }
    _loadSummary();
  }

  Future<void> _loadSummary({bool refresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _db.currentUser;
      if (user == null) throw Exception('No logged-in user.');

      Map<String, dynamic> data;
      String? studentId = user.role == UserRole.parent ? _parentSelectedChild?.id : null;
      String? classFilter = (user.role == UserRole.principal || user.role == UserRole.osd || user.role == UserRole.ministrong_tagasubaybay)
          ? _selectedClass
          : null;

      if (refresh) {
        data = await _db.refreshAiSummary(
          _selectedPeriod,
          studentId: studentId,
          className: classFilter,
        );
      } else {
        data = await _db.getAiSummary(
          _selectedPeriod,
          studentId: studentId,
          className: classFilter,
        );
      }

      setState(() {
        _summaryText = data['summary_text'];
        _stats = data['stats'];
        if (data['updated_at'] != null) {
          final parsedDate = DateTime.parse(data['updated_at']).toLocal();
          _lastGenerated = '${parsedDate.month}/${parsedDate.day}/${parsedDate.year} at ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}';
        } else {
          _lastGenerated = 'Just now';
        }
      });
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

  @override
  Widget build(BuildContext context) {
    final user = _db.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Unauthorized')));

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Premium Dark Slate
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('AI Analysis Summaries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Period Filters
                _buildPeriodFilterRow(),
                const SizedBox(height: 12),

                // Role-scoped context filters
                _buildRoleContextFilters(),
                const SizedBox(height: 16),

                // Last generated & refresh button row
                _buildHeaderControlRow(),
                const SizedBox(height: 16),

                if (_isLoading)
                  const Card(
                    color: Color(0xFF1E293B),
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48.0),
                      child: Column(
                        children: [
                          CircularProgressIndicator(color: Color(0xFF2563EB)),
                          SizedBox(height: 16),
                          Text('Aggregating incident logs & generating report...', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                        ],
                      ),
                    ),
                  )
                else if (_errorMessage != null)
                  Card(
                    color: const Color(0xFF451A03),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF78350F)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, color: Color(0xFFF59E0B), size: 36),
                          const SizedBox(height: 12),
                          Text(_errorMessage!, style: const TextStyle(color: Color(0xFFFCD34D), fontSize: 13), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  )
                else ...[
                  // Stats Visualizer Card
                  if (_stats != null && _stats!['total_cases'] > 0) ...[
                    _buildStatsVisualizerCard(),
                    const SizedBox(height: 16),
                  ],

                  // AI Analysis Markdown Card
                  Card(
                    color: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF334155)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: _summaryText != null
                          ? MarkdownText(text: _summaryText!)
                          : const Center(
                              child: Text(
                                'No summary content loaded.',
                                style: TextStyle(color: Color(0xFF94A3B8)),
                              ),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodFilterRow() {
    return Row(
      children: [
        _buildPeriodButton('Weekly', 'weekly'),
        const SizedBox(width: 8),
        _buildPeriodButton('Monthly', 'monthly'),
        const SizedBox(width: 8),
        _buildPeriodButton('Yearly', 'yearly'),
      ],
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedPeriod = value;
          });
          _loadSummary();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1E293B),
          foregroundColor: isSelected ? Colors.white : const Color(0xFF94A3B8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF334155)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  Widget _buildRoleContextFilters() {
    final user = _db.currentUser;
    if (user == null) return const SizedBox();

    if (user.role == UserRole.parent) {
      final children = user.students ?? [];
      if (children.isEmpty) return const SizedBox();
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          children: [
            const Icon(Icons.child_care, color: Color(0xFF2563EB), size: 20),
            const SizedBox(width: 12),
            const Text('Switch Child:', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  border: Border.all(color: const Color(0xFF334155)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<StudentModel>(
                    value: _parentSelectedChild,
                    hint: const Text('Select a child', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    dropdownColor: const Color(0xFF1E293B),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    items: children.map((c) {
                      return DropdownMenuItem<StudentModel>(
                        value: c,
                        child: Text(c.name),
                      );
                    }).toList(),
                    onChanged: (newChild) {
                      setState(() {
                        _parentSelectedChild = newChild;
                      });
                      _loadSummary();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (user.role == UserRole.principal || user.role == UserRole.osd || user.role == UserRole.ministrong_tagasubaybay) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Row(
          children: [
            const Icon(Icons.class_outlined, color: Color(0xFF2563EB), size: 20),
            const SizedBox(width: 12),
            const Text('Section Filter:', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  border: Border.all(color: const Color(0xFF334155)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedClass,
                    hint: const Text('School-wide / All Classes', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    dropdownColor: const Color(0xFF1E293B),
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('School-wide / All Classes'),
                      ),
                      ..._classSections.map((c) {
                        return DropdownMenuItem<String>(
                          value: c,
                          child: Text(c),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _selectedClass = val;
                      });
                      _loadSummary();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox();
  }

  Widget _buildHeaderControlRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('LAST REFRESHED', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(_lastGenerated, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _loadSummary(refresh: true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E293B),
            foregroundColor: const Color(0xFF2563EB),
            side: const BorderSide(color: Color(0xFF334155)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Refresh AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildStatsVisualizerCard() {
    final total = _stats!['total_cases'] ?? 0;
    final resolved = _stats!['resolved_cases'] ?? 0;
    final pending = _stats!['pending_cases'] ?? 0;
    final escalated = _stats!['escalated_cases'] ?? 0;

    return Card(
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF334155)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('PERIOD STATISTICS', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatLabel('Total Cases', total.toString(), Colors.white),
                _buildStatLabel('Resolved', resolved.toString(), const Color(0xFF10B981)),
                _buildStatLabel('Pending', pending.toString(), const Color(0xFF3B82F6)),
                _buildStatLabel('Escalated', escalated.toString(), const Color(0xFFEF4444)),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF334155)),
            const SizedBox(height: 12),
            _buildStatProgressBar('Resolved Cases', resolved, total, const Color(0xFF10B981)),
            const SizedBox(height: 10),
            _buildStatProgressBar('Pending Cases', pending, total, const Color(0xFF3B82F6)),
            const SizedBox(height: 10),
            _buildStatProgressBar('Escalated Cases', escalated, total, const Color(0xFFEF4444)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatLabel(String title, String val, Color valColor) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: valColor)),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
      ],
    );
  }

  Widget _buildStatProgressBar(String label, int val, int total, Color color) {
    final double percent = total > 0 ? (val / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            Text('${(percent * 100).round()}%', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: percent,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MarkdownText extends StatelessWidget {
  final String text;
  const MarkdownText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final List<Widget> children = [];

    for (var line in lines) {
      if (line.trim().isEmpty) {
        children.add(const SizedBox(height: 8));
        continue;
      }

      if (line.startsWith('### ')) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            line.substring(4),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
          ),
        ));
      } else if (line.startsWith('#### ')) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Text(
            line.substring(5),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFE2E8F0)),
          ),
        ));
      } else if (line.startsWith('- ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2563EB))),
              Expanded(
                child: _buildRichText(line.substring(2)),
              ),
            ],
          ),
        ));
      } else if (line.startsWith('> ')) {
        children.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            border: const Border(left: BorderSide(color: Color(0xFF2563EB), width: 4)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: _buildRichText(line.substring(2)),
        ));
      } else {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: _buildRichText(line),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _buildRichText(String rawText) {
    final List<TextSpan> spans = [];
    final regExp = RegExp(r'\*\*(.*?)\*\*');
    int lastIndex = 0;

    for (final match in regExp.allMatches(rawText)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: rawText.substring(lastIndex, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
      ));
      lastIndex = match.end;
    }

    if (lastIndex < rawText.length) {
      spans.add(TextSpan(text: rawText.substring(lastIndex)));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.5),
        children: spans,
      ),
    );
  }
}
