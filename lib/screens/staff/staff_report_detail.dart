import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/ai_service.dart';
import '../../models/user_model.dart';
import '../../models/report_model.dart';
import '../../models/meeting_model.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/timeline_widget.dart';
import '../chat/chat_screen.dart';
import '../../widgets/evidence_media_widget.dart';

class StaffReportDetailScreen extends StatefulWidget {
  final String reportId;

  const StaffReportDetailScreen({super.key, required this.reportId});

  @override
  State<StaffReportDetailScreen> createState() => _StaffReportDetailScreenState();
}

class _StaffReportDetailScreenState extends State<StaffReportDetailScreen> {
  final _db = DatabaseService();
  final _ai = AIService();

  // Scheduler controllers
  DateTime _meetingDate = DateTime.now();
  TimeOfDay _meetingTime = TimeOfDay.now();
  final _meetingNotesController = TextEditingController();
  String _meetingType = 'In-Person';
  bool _isScheduling = false;

  // Resolution controllers
  String _selectedDiscipline = 'Warning';
  final _disciplineNotesController = TextEditingController();
  bool _isResolving = false;

  // AI Summary generation state
  bool _isGeneratingSummary = false;

  @override
  void initState() {
    super.initState();
    _db.addListener(_onDbUpdate);
  }

  @override
  void dispose() {
    _db.removeListener(_onDbUpdate);
    _meetingNotesController.dispose();
    _disciplineNotesController.dispose();
    super.dispose();
  }

  void _onDbUpdate() {
    if (mounted) setState(() {});
  }

  // Card builder helper for Light Slate style
  Widget _buildCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BoxBorder? border,
    Color color = Colors.white,
  }) {
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: border ?? Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // OCR/AI Evidence Verification Badge
  Widget _buildEvidenceVerificationBadge(String state) {
    Color bg;
    Color border;
    Color text;

    switch (state) {
      case 'Verified':
        bg = const Color(0xFFF0FDF4); // Green 50
        border = const Color(0xFFBBF7D0); // Green 200
        text = const Color(0xFF16A34A); // Green 600
        break;
      case 'Suspected AI Generated':
        bg = const Color(0xFFFFF1F2); // Red 50
        border = const Color(0xFFFECDD3); // Red 200
        text = const Color(0xFFE11D48); // Red 600
        break;
      case 'Suspected Google Image':
        bg = const Color(0xFFFEF3C7); // Amber 50
        border = const Color(0xFFFDE68A); // Amber 200
        text = const Color(0xFFD97706); // Amber 600
        break;
      default:
        bg = const Color(0xFFF8FAFC); // Slate 50
        border = const Color(0xFFE2E8F0); // Slate 200
        text = const Color(0xFF64748B); // Slate 500
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        state.toUpperCase(),
        style: TextStyle(
          color: text,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Future<void> _selectMeetingDate(StateSetter setDialogState) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _meetingDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2028),
    );
    if (picked != null) {
      setDialogState(() {
        _meetingDate = picked;
      });
    }
  }

  Future<void> _selectMeetingTime(StateSetter setDialogState) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _meetingTime,
    );
    if (picked != null) {
      setDialogState(() {
        _meetingTime = picked;
      });
    }
  }

  void _showScheduleMeetingDialog() {
    _meetingDate = DateTime.now();
    _meetingTime = TimeOfDay.now();
    _meetingNotesController.clear();
    _meetingType = 'In-Person';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text(
                'Schedule Meeting',
                style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Schedule a discussion with the parent to coordinate details.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    MediaQuery.of(context).size.width < 400
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _selectMeetingDate(setDialogState),
                                icon: const Icon(Icons.calendar_today, size: 14),
                                label: Text(
                                  '${_meetingDate.year}-${_meetingDate.month.toString().padLeft(2, '0')}-${_meetingDate.day.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF475569),
                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () => _selectMeetingTime(setDialogState),
                                icon: const Icon(Icons.access_time, size: 14),
                                label: Text(
                                  _meetingTime.format(context),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF475569),
                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _selectMeetingDate(setDialogState),
                                  icon: const Icon(Icons.calendar_today, size: 14),
                                  label: Text(
                                    '${_meetingDate.year}-${_meetingDate.month.toString().padLeft(2, '0')}-${_meetingDate.day.toString().padLeft(2, '0')}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF475569),
                                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _selectMeetingTime(setDialogState),
                                  icon: const Icon(Icons.access_time, size: 14),
                                  label: Text(
                                    _meetingTime.format(context),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF475569),
                                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _meetingType,
                      decoration: _dialogInputDecoration('Meeting Type'),
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                      items: ['In-Person', 'Virtual']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => _meetingType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _meetingNotesController,
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                      maxLines: 3,
                      decoration: _dialogInputDecoration('Meeting Agenda / Notes'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  onPressed: _isScheduling ? null : () => _handleScheduleMeeting(setDialogState),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isScheduling
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Schedule'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleScheduleMeeting(StateSetter? setDialogState, {String? existingMeetingId}) async {
    if (setDialogState != null) {
      setDialogState(() => _isScheduling = true);
    }
    setState(() => _isScheduling = true);

    try {
      final combinedDateTime = DateTime(
        _meetingDate.year,
        _meetingDate.month,
        _meetingDate.day,
        _meetingTime.hour,
        _meetingTime.minute,
      );

      if (existingMeetingId != null) {
        await _db.rescheduleMeeting(
          meetingId: existingMeetingId,
          newDate: combinedDateTime,
          newNotes: _meetingNotesController.text.trim().isEmpty ? "No notes provided." : _meetingNotesController.text.trim(),
          newType: _meetingType,
        );
        if (!mounted) return;
        Navigator.of(context).pop(); // Dismiss reschedule dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meeting rescheduled successfully.')),
        );
      } else {
        await _db.scheduleMeeting(
          reportId: widget.reportId,
          meetingDate: combinedDateTime,
          notes: _meetingNotesController.text.trim().isEmpty ? "No notes provided." : _meetingNotesController.text.trim(),
          meetingType: _meetingType,
        );
        _meetingNotesController.clear();
        if (!mounted) return;
        Navigator.of(context).pop(); // Dismiss schedule dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meeting scheduled successfully.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action failed: $e')),
      );
    } finally {
      if (mounted) {
        if (setDialogState != null) {
          setDialogState(() => _isScheduling = false);
        }
        setState(() => _isScheduling = false);
      }
    }
  }

  void _showRescheduleDialog(MeetingModel meeting) {
    _meetingDate = meeting.meetingDate;
    _meetingTime = TimeOfDay.fromDateTime(meeting.meetingDate);
    _meetingNotesController.text = meeting.notes;
    _meetingType = meeting.meetingType;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text(
                'Reschedule Meeting',
                style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Only the original scheduler can update this date/time.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    MediaQuery.of(context).size.width < 400
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _selectMeetingDate(setDialogState),
                                icon: const Icon(Icons.calendar_today, size: 14),
                                label: Text(
                                  '${_meetingDate.year}-${_meetingDate.month.toString().padLeft(2, '0')}-${_meetingDate.day.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF475569),
                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () => _selectMeetingTime(setDialogState),
                                icon: const Icon(Icons.access_time, size: 14),
                                label: Text(
                                  _meetingTime.format(context),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF475569),
                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _selectMeetingDate(setDialogState),
                                  icon: const Icon(Icons.calendar_today, size: 14),
                                  label: Text(
                                    '${_meetingDate.year}-${_meetingDate.month.toString().padLeft(2, '0')}-${_meetingDate.day.toString().padLeft(2, '0')}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF475569),
                                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _selectMeetingTime(setDialogState),
                                  icon: const Icon(Icons.access_time, size: 14),
                                  label: Text(
                                    _meetingTime.format(context),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF475569),
                                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _meetingType,
                      decoration: _dialogInputDecoration('Meeting Type'),
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                      items: ['In-Person', 'Virtual']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => _meetingType = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _meetingNotesController,
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                      maxLines: 3,
                      decoration: _dialogInputDecoration('Reschedule Notes'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  onPressed: _isScheduling ? null : () => _handleScheduleMeeting(setDialogState, existingMeetingId: meeting.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isScheduling
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Confirm Reschedule'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showResolveCaseDialog() {
    _selectedDiscipline = 'Warning';
    _disciplineNotesController.clear();

    final staff = _db.currentUser;
    final isMinorOnly = staff?.role == UserRole.principal || staff?.role == UserRole.ministrong_tagasubaybay;
    final dropdownItems = isMinorOnly
        ? ['Warning', 'Counseling', 'Mediation', 'Community Service', 'Parent Consultation', 'Other']
        : ['Warning', 'Counseling', 'Mediation', 'Suspension', 'Expulsion', 'Community Service', 'Parent Consultation', 'Other'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text(
                'Resolve Incident Case',
                style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Input the final resolution action and closing notes for this case.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedDiscipline,
                      decoration: _dialogInputDecoration('Disciplinary Action Given'),
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                      items: dropdownItems
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => _selectedDiscipline = val);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _disciplineNotesController,
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                      maxLines: 3,
                      decoration: _dialogInputDecoration('Detailed Resolution Notes'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  onPressed: _isResolving ? null : () => _handleResolve(setDialogState),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isResolving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Resolve Incident'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleResolve(StateSetter setDialogState) async {
    if (_disciplineNotesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter resolution notes.')),
      );
      return;
    }

    setDialogState(() => _isResolving = true);
    setState(() => _isResolving = true);

    try {
      await _db.resolveReport(
        reportId: widget.reportId,
        disciplineAction: _selectedDiscipline,
        disciplineNotes: _disciplineNotesController.text.trim(),
      );
      _disciplineNotesController.clear();
      if (!mounted) return;
      Navigator.of(context).pop(); // Dismiss resolve dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Case marked as resolved successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resolution failed: $e')),
      );
    } finally {
      if (mounted) {
        setDialogState(() => _isResolving = false);
        setState(() => _isResolving = false);
      }
    }
  }

  void _showEscalateDialog() {
    final staff = _db.currentUser;
    if (staff == null) return;

    String title = 'Escalate Case';
    String content = 'Are you sure you want to escalate this report?';
    if (staff.role == UserRole.adviser) {
      title = 'Escalate to Principal';
      content = 'Are you sure you want to escalate this report to the School Principal for formal review?';
    } else if (staff.role == UserRole.principal) {
      title = 'Escalate to Ministrong';
      content = 'Are you sure you want to escalate this report to the Ministrong Tagasubaybay for review?';
    } else if (staff.role == UserRole.ministrong_tagasubaybay) {
      title = 'Escalate to OSD';
      content = 'Are you sure you want to forward this report to the Office of Student Discipline (OSD) for formal investigation?';
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            title,
            style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Text(
            content,
            style: const TextStyle(color: Color(0xFF334155), fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _handleEscalate();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Escalate'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleEscalate() async {
    final staff = _db.currentUser;
    if (staff == null) return;

    try {
      await _db.escalateReport(widget.reportId);
      if (!mounted) return;
      
      String msg = 'Report successfully escalated.';
      if (staff.role == UserRole.adviser) {
        msg = 'Report successfully escalated to the School Principal.';
      } else if (staff.role == UserRole.principal) {
        msg = 'Report successfully escalated to the Ministrong Tagasubaybay.';
      } else if (staff.role == UserRole.ministrong_tagasubaybay) {
        msg = 'Report successfully escalated to the Office of Student Discipline (OSD).';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Escalation failed: $e')),
      );
    }
  }

  void _showAddNoteDialog() {
    final noteController = TextEditingController();
    bool isSavingNote = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: const Text(
                'Add Incident Progress Note',
                style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Attach a progress note or timeline update describing current action steps.',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: noteController,
                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13),
                      maxLines: 4,
                      decoration: _dialogInputDecoration('Write progress note...'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  onPressed: isSavingNote
                      ? null
                      : () async {
                          if (noteController.text.trim().isEmpty) return;
                          setDialogState(() => isSavingNote = true);
                          try {
                            await _db.addTimelineNote(widget.reportId, noteController.text.trim());
                            if (!mounted) return;
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Progress note added to timeline.')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to add note: $e')),
                            );
                          } finally {
                            setDialogState(() => isSavingNote = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isSavingNote
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Add Note'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration _dialogInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
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

  Future<void> _handleGenerateAiSummary(ReportModel report) async {
    setState(() {
      _isGeneratingSummary = true;
    });

    try {
      // Simulate loading spinner for 800ms as requested
      await Future.delayed(const Duration(milliseconds: 800));

      final summary = await _ai.generateReportSummary(
        title: report.title,
        description: report.description,
        category: report.category,
        location: report.incidentLocation,
      );

      await _db.updateAiSummary(report.id, summary);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('AI Incident Summary generated successfully.')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate summary: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingSummary = false;
        });
      }
    }
  }

  Widget _buildAiSummaryCard(ReportModel report) {
    if (_isGeneratingSummary) {
      return _buildCard(
        color: const Color(0xFFF5F3FF), // Violet 50
        border: Border.all(color: const Color(0xFFDDD6FE)), // Violet 200
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
              ),
              SizedBox(height: 16),
              Text(
                'AI is analyzing the report details...',
                style: TextStyle(
                  color: Color(0xFF5B21B6),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Assessing severity and drafting action steps',
                style: TextStyle(color: Color(0xFF7C3AED), fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    if (report.aiSummary != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.psychology, color: Color(0xFF7C3AED), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'AI-Generated Report Summary',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: () => _handleGenerateAiSummary(report),
                icon: const Icon(Icons.refresh, size: 14, color: Color(0xFF7C3AED)),
                label: const Text(
                  'Regenerate',
                  style: TextStyle(color: Color(0xFF7C3AED), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildCard(
            color: const Color(0xFFF5F3FF), // Violet 50
            border: Border.all(color: const Color(0xFFDDD6FE)), // Violet 200
            padding: const EdgeInsets.all(16),
            child: Text(
              report.aiSummary!,
              style: const TextStyle(
                color: Color(0xFF4C1D95),
                fontSize: 12,
                height: 1.5,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      );
    }

    // AI Summary is null
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.psychology, color: Color(0xFF64748B), size: 20),
              SizedBox(width: 8),
              Text(
                'AI Case Summary Generator',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'No AI summary has been generated for this incident yet. Generate a summary to evaluate severity, extract context, and view recommended next steps.',
            style: TextStyle(color: Color(0xFF475569), fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _handleGenerateAiSummary(report),
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: const Text(
              'Generate AI Case Summary',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staff = _db.currentUser;
    if (staff == null) return const SizedBox();

    ReportModel? report;
    try {
      report = _db.getReportById(widget.reportId);
    } catch (_) {
      report = null;
    }

    if (report == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Report details', style: TextStyle(color: Color(0xFF0F172A))),
          iconTheme: const IconThemeData(color: Color(0xFF475569)),
        ),
        body: const Center(child: Text('Unauthorized view access.', style: TextStyle(color: Color(0xFF0F172A)))),
      );
    }

    final meetings = _db.getMeetingsForReport(report.id);
    final timelineEvents = _db.getTimelineEvents(report.id);
    final bool isMobile = MediaQuery.of(context).size.width < 700;

    final Widget leftPane = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Overview Card
        _buildCard(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusBadge(status: report.status),
                  Text(
                    report.createdAt.toLocal().toString().substring(0, 16),
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                report.title,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _victimInfoBox(report),
              const SizedBox(height: 14),
              Text(
                report.description,
                style: const TextStyle(color: Color(0xFF334155), fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Bully & Witnesses Card
        if (report.bullyName != null || (report.witnesses != null && report.witnesses!.isNotEmpty)) ...[
          const Text('Alleged Bully & Witnesses', style: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (report.bullyName != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.person_outline, color: Color(0xFF2563EB), size: 18),
                      const SizedBox(width: 8),
                      const Text('Alleged Bully: ', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                      Text(
                        report.bullyName!,
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      if (report.bullyGradeSection != null) ...[
                        Text(
                          ' (${report.bullyGradeSection})',
                          style: const TextStyle(color: Color(0xFF475569), fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                  if (report.witnesses != null && report.witnesses!.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(color: Color(0xFFE2E8F0)),
                    ),
                ],
                if (report.witnesses != null && report.witnesses!.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.people_outline, color: Color(0xFF2563EB), size: 18),
                      const SizedBox(width: 8),
                      const Text('Witnesses: ', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: report.witnesses!
                              .map((w) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Text(
                                      w,
                                      style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // AI Auto Summary Panel
        _buildAiSummaryCard(report),

        const SizedBox(height: 16),

        // Evidence scan Report
        if (report.evidenceUrl != null) ...[
          const Text('Evidence Analysis Details', style: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildCard(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.photo_outlined, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        report.evidenceUrl!,
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildEvidenceVerificationBadge(report.evidenceVerificationState),
                  ],
                ),
                if (report.evidenceVerificationDetails != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    report.evidenceVerificationDetails!,
                    style: const TextStyle(color: Color(0xFF475569), fontSize: 11, height: 1.3),
                  ),
                ],
                EvidenceMediaWidget(filename: report.evidenceUrl!),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Timeline logs
        const Text('Timeline Activity Logs', style: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildCard(
          padding: const EdgeInsets.all(16.0),
          child: TimelineWidget(events: timelineEvents),
        ),
      ],
    );

    final Widget rightPane = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Meeting schedules
        if (meetings.isNotEmpty) ...[
          const Text('Meeting Schedules', style: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...meetings.map((meeting) {
            final unreadChats = _db.getUnreadMessageCount(meeting.id);
            return _buildCard(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${meeting.meetingType} Meet',
                        style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Text(
                          meeting.meetingDate.toLocal().toString().substring(0, 16),
                          style: const TextStyle(color: Color(0xFF2563EB), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('Notes: ${meeting.notes ?? "No notes."}', style: const TextStyle(color: Color(0xFF475569), fontSize: 12)),
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ChatScreen(meetingId: meeting.id)),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: Badge(
                          isLabelVisible: unreadChats > 0,
                          label: Text('$unreadChats'),
                          child: const Icon(Icons.chat_bubble_outline, size: 14),
                        ),
                        label: const Text('Open Chat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      if (meeting.scheduledByUserId == staff.id)
                        OutlinedButton(
                          onPressed: () => _showRescheduleDialog(meeting),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF475569),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: const Text('Reschedule', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        // Quick Actions
        const Text('Quick Case Actions', style: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildCard(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (report.status != 'resolved' && report.status != 'closed') ...[
                // Schedule Button
                ElevatedButton.icon(
                  onPressed: _showScheduleMeetingDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.video_call_outlined, size: 18),
                  label: const Text('Schedule Coordination Meeting', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(height: 10),

                // Resolve Button
                if (staff.role != UserRole.adviser) ...[
                  ElevatedButton.icon(
                    onPressed: _showResolveCaseDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Resolve Incident Case', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  const SizedBox(height: 10),
                ],
              ],

              // Escalate Button (if allowed)
              if ((staff.role == UserRole.adviser && report.status == 'Pending') ||
                  (staff.role == UserRole.principal && report.status == 'Escalated to Principal') ||
                  (staff.role == UserRole.ministrong_tagasubaybay && report.status == 'Escalated to Ministrong')) ...[
                ElevatedButton.icon(
                  onPressed: _showEscalateDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEA580C),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  label: Text(
                    staff.role == UserRole.adviser
                        ? 'Escalate to Principal'
                        : staff.role == UserRole.principal
                            ? 'Escalate to Ministrong'
                            : 'Forward to OSD Officer',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Add Note Button
              OutlinedButton.icon(
                onPressed: _showAddNoteDialog,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.note_add_outlined, size: 18),
                label: const Text('Add Timeline Progress Note', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
        ),

        // Case Outcome Outcome Card (If Resolved)
        if (report.status == 'resolved' || report.status == 'closed') ...[
          const SizedBox(height: 16),
          const Text('Incident Resolution Outcome', style: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildCard(
            color: const Color(0xFFF0FDF4),
            border: Border.all(color: const Color(0xFFBBF7D0)),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Color(0xFF16A34A)),
                    SizedBox(width: 8),
                    Text(
                      'Case Resolved Outcome',
                      style: TextStyle(color: Color(0xFF14532D), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Action Given: ${report.disciplineAction}',
                  style: const TextStyle(color: Color(0xFF166534), fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Resolution Notes:\n${report.disciplineNotes}',
                  style: const TextStyle(color: Color(0xFF1E3A1E), fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        title: Text(
          'Incident Detail: ${report.studentName}',
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF475569)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            child: isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      leftPane,
                      const SizedBox(height: 16),
                      rightPane,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: leftPane),
                      const SizedBox(width: 16),
                      Expanded(flex: 4, child: rightPane),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _victimInfoBox(ReportModel r) {
    final isAdviserObserved = r.reportSource == 'Adviser-Observed';
    final reporterLabel = isAdviserObserved 
        ? (r.reporterName != null ? 'Adviser: ${r.reporterName}' : r.parentName)
        : '${r.parentName} (Parent)';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAdviserObserved ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        border: Border.all(color: isAdviserObserved ? const Color(0xFF99F6E4) : const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          if (isAdviserObserved) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_outlined, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'ADVISER-OBSERVED INCIDENT',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ],
          _infoRow('Victim name', r.studentName),
          const SizedBox(height: 6),
          _infoRow('Grade / Section', '${r.studentGrade} - ${r.studentSection}'),
          const SizedBox(height: 6),
          _infoRow('Report Source', isAdviserObserved ? 'Adviser Direct Observation' : 'Parent-Reported'),
          const SizedBox(height: 6),
          _infoRow('Submitted By', reporterLabel),
          if (r.urgencyLevel != 'Moderate') ...[
            const SizedBox(height: 6),
            _infoRow('Urgency Level', '${r.urgencyLevel} Severity'),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
        Text(val, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 11, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
