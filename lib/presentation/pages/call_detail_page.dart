import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/call_session_model.dart';
import '../blocs/calls/calls_bloc.dart';
import '../blocs/calls/calls_event.dart';
import '../blocs/calls/calls_state.dart';

class CallDetailPage extends StatefulWidget {
  final int callId;
  const CallDetailPage({super.key, required this.callId});

  @override
  State<CallDetailPage> createState() => _CallDetailPageState();
}

class _CallDetailPageState extends State<CallDetailPage> {
  bool _editing = false;
  late TextEditingController _contactController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;
  late TextEditingController _durationController;
  String _direction = 'outgoing';

  @override
  void initState() {
    super.initState();
    _contactController = TextEditingController();
    _phoneController = TextEditingController();
    _notesController = TextEditingController();
    _durationController = TextEditingController();
  }

  @override
  void dispose() {
    _contactController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _populate(CallSession call) {
    if (!_editing) {
      _contactController.text = call.contactName ?? '';
      _phoneController.text = call.phoneNumber ?? '';
      _notesController.text = call.notes ?? '';
      _durationController.text = call.durationSeconds.toString();
      _direction = call.direction;
    }
  }

  void _save(CallSession call) {
    final data = <String, dynamic>{};
    if (_contactController.text != call.contactName) data['contact_name'] = _contactController.text;
    if (_phoneController.text != call.phoneNumber) data['phone_number'] = _phoneController.text;
    if (_notesController.text != call.notes) data['notes'] = _notesController.text;
    if (_durationController.text.isNotEmpty) {
      final dur = int.tryParse(_durationController.text);
      if (dur != null && dur != call.durationSeconds) data['duration_seconds'] = dur;
    }
    if (_direction != call.direction) data['direction'] = _direction;

    if (data.isNotEmpty) {
      context.read<CallsBloc>().add(CallUpdateRequested(id: call.id, data: data));
    }
    setState(() => _editing = false);
  }

  void _confirmDelete(CallSession call) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete Call?'),
      content: const Text('This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: () {
          Navigator.pop(context);
          context.read<CallsBloc>().add(CallDeleteRequested(call.id));
          context.pop();
        }, child: Text('Delete', style: TextStyle(color: AppTheme.error))),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return BlocBuilder<CallsBloc, CallsState>(
      builder: (context, state) {
        final call = state.calls.where((c) => c.id == widget.callId).firstOrNull;
        if (call == null) {
          return Scaffold(appBar: AppBar(title: const Text('Call')), body: const Center(child: Text('Call not found')));
        }

        _populate(call);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Call Details'),
            actions: [
              if (!_editing) ...[
                IconButton(icon: const Icon(Icons.edit), onPressed: () => setState(() => _editing = true)),
                IconButton(icon: Icon(Icons.delete, color: AppTheme.error), onPressed: () => _confirmDelete(call)),
              ] else ...[
                TextButton(onPressed: () { setState(() => _editing = false); }, child: const Text('Cancel')),
                TextButton(onPressed: () => _save(call), child: const Text('Save')),
              ],
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Direction badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: call.direction == 'missed' ? AppTheme.error.withOpacity(0.1) : AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(call.directionIcon, style: TextStyle(color: call.direction == 'missed' ? AppTheme.error : AppTheme.primary)),
                          const SizedBox(width: 4),
                          Text(call.directionLabel, style: TextStyle(color: call.direction == 'missed' ? AppTheme.error : AppTheme.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (call.hasVoiceMemo) Icon(Icons.mic, color: AppTheme.success, size: 20),
                    const SizedBox(width: 4),
                    if (call.hasVoiceMemo) Text('Has voice memo', style: TextStyle(color: AppTheme.success, fontSize: 12)),
                  ],
                ),

                const SizedBox(height: 20),

                // Timestamp
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    if (call.startedAt != null)
                      Text('${dateFormat.format(call.startedAt!)} at ${timeFormat.format(call.startedAt!)}', style: Theme.of(context).textTheme.bodyMedium)
                    else
                      Text('${dateFormat.format(call.createdAt)} at ${timeFormat.format(call.createdAt)}', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),

                const SizedBox(height: 24),

                // Contact name
                _FieldLabel('Contact Name'),
                _editing
                    ? TextField(controller: _contactController, decoration: const InputDecoration(hintText: 'e.g. Mr. Smith'))
                    : _FieldValue(call.contactName ?? '—', Icons.person_outline),

                const SizedBox(height: 20),

                // Phone number
                _FieldLabel('Phone Number'),
                _editing
                    ? TextField(controller: _phoneController, decoration: const InputDecoration(hintText: '+1 234 567 8900'), keyboardType: TextInputType.phone)
                    : _FieldValue(call.phoneNumber ?? '—', Icons.phone_outlined),

                const SizedBox(height: 20),

                // Duration
                _FieldLabel('Duration'),
                _editing
                    ? TextField(controller: _durationController, decoration: const InputDecoration(hintText: 'Seconds', prefixText: 'Duration: '), keyboardType: TextInputType.number)
                    : _FieldValue(call.durationFormatted ?? '${call.durationSeconds}s', Icons.timer_outlined),

                const SizedBox(height: 20),

                // Notes
                _FieldLabel('Notes'),
                _editing
                    ? TextField(controller: _notesController, maxLines: 3, decoration: const InputDecoration(hintText: 'Call notes...'))
                    : _FieldValue(call.notes ?? '—', Icons.note_outlined),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
    );
  }
}

class _FieldValue extends StatelessWidget {
  final String value;
  final IconData icon;
  const _FieldValue(this.value, this.icon);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
