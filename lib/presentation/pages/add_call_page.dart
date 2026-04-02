import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../core/theme/app_theme.dart';
import '../blocs/calls/calls_bloc.dart';
import '../blocs/calls/calls_event.dart';
import '../blocs/calls/calls_state.dart';

class AddCallPage extends StatefulWidget {
  const AddCallPage({super.key});

  @override
  State<AddCallPage> createState() => _AddCallPageState();
}

class _AddCallPageState extends State<AddCallPage> {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _durationController = TextEditingController(text: '0');

  String _direction = 'outgoing';
  DateTime _startedAt = DateTime.now();
  bool _hasVoiceMemo = false;

  // Voice memo
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _timer;
  String? _recordingPath;

  @override
  void dispose() {
    _contactController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _durationController.dispose();
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/call_memo_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 16000, numChannels: 1), path: path);
        setState(() {
          _isRecording = true;
          _recordingPath = path;
          _recordingSeconds = 0;
        });
        _timer = Timer.periodic(const Duration(seconds: 1), (t) {
          setState(() => _recordingSeconds++);
          if (_recordingSeconds >= 120) _stopRecording();
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not start recording: $e')));
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    await _recorder.stop();
    setState(() { _isRecording = false; _hasVoiceMemo = _recordingPath != null; });
  }

  String _formatDuration(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final duration = int.tryParse(_durationController.text) ?? 0;
    final endedAt = _startedAt.add(Duration(seconds: duration));

    final callData = {
      'contact_name': _contactController.text.trim(),
      'phone_number': _phoneController.text.trim(),
      'direction': _direction,
      'duration_seconds': duration,
      'started_at': _startedAt.toIso8601String(),
      'ended_at': endedAt.toIso8601String(),
      'notes': _notesController.text.trim(),
    };

    if (_hasVoiceMemo && _recordingPath != null) {
      context.read<CallsBloc>().add(CallCreateWithMemoRequested(
        data: callData,
        audioFile: File(_recordingPath!),
      ));
    } else {
      context.read<CallsBloc>().add(CallCreateRequested(callData));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log a Call')),
      body: BlocListener<CallsBloc, CallsState>(
        listener: (context, state) {
          if (state.status == CallsStatus.loaded) context.pop();
          if (state.status == CallsStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Error'), backgroundColor: AppTheme.error),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Direction selector
                Text('Call Direction', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _DirectionChip(
                      label: 'Outgoing',
                      icon: Icons.call_made,
                      selected: _direction == 'outgoing',
                      color: AppTheme.success,
                      onTap: () => setState(() => _direction = 'outgoing'),
                    ),
                    const SizedBox(width: 8),
                    _DirectionChip(
                      label: 'Incoming',
                      icon: Icons.call_received,
                      selected: _direction == 'incoming',
                      color: AppTheme.primary,
                      onTap: () => setState(() => _direction = 'incoming'),
                    ),
                    const SizedBox(width: 8),
                    _DirectionChip(
                      label: 'Missed',
                      icon: Icons.call_missed,
                      selected: _direction == 'missed',
                      color: AppTheme.error,
                      onTap: () => setState(() => _direction = 'missed'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Contact name
                TextFormField(
                  controller: _contactController,
                  decoration: const InputDecoration(labelText: 'Contact Name', prefixIcon: Icon(Icons.person_outline)),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                // Phone number
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number (optional)', prefixIcon: Icon(Icons.phone_outlined)),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                // Duration
                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (seconds)',
                    prefixIcon: Icon(Icons.timer_outlined),
                    hintText: 'e.g. 300 for 5 minutes',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter duration';
                    if (int.tryParse(v) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notes (optional)', prefixIcon: Icon(Icons.note_outlined)),
                  maxLines: 3,
                ),

                const SizedBox(height: 24),

                // Voice memo section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.mic, color: _hasVoiceMemo ? AppTheme.success : AppTheme.textSecondary),
                          const SizedBox(width: 8),
                          Text('Voice Memo', style: Theme.of(context).textTheme.titleMedium),
                          const Spacer(),
                          if (_hasVoiceMemo && !_isRecording)
                            Chip(
                              label: Text('Attached', style: TextStyle(color: AppTheme.success, fontSize: 12)),
                              backgroundColor: AppTheme.success.withOpacity(0.1),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Attach a voice note to remember call details', style: Theme.of(context).textTheme.bodyMedium, maxLines: 2),
                      const SizedBox(height: 16),
                      if (_isRecording) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.fiber_manual_record, color: AppTheme.error, size: 16),
                            const SizedBox(width: 4),
                            Text(_formatDuration(_recordingSeconds), style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton.icon(
                            onPressed: _stopRecording,
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop Recording'),
                            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                          ),
                        ),
                      ] else ...[
                        if (_hasVoiceMemo)
                          Center(
                            child: TextButton.icon(
                              onPressed: () { setState(() { _hasVoiceMemo = false; _recordingPath = null; }); },
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Remove memo'),
                              style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                            ),
                          )
                        else
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: _startRecording,
                              icon: const Icon(Icons.mic),
                              label: const Text('Record Memo'),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                BlocBuilder<CallsBloc, CallsState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state.status == CallsStatus.creating ? null : _submit,
                      child: state.status == CallsStatus.creating
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save Call Log'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DirectionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _DirectionChip({required this.label, required this.icon, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.15) : AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? color : AppTheme.divider, width: selected ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? color : AppTheme.textSecondary, size: 24),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.normal, color: selected ? color : AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
