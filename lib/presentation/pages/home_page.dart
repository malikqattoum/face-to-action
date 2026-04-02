import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/log_model.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import '../blocs/logs/logs_bloc.dart';
import '../blocs/logs/logs_event.dart';
import '../blocs/logs/logs_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _showRecordingWarning = false;
  int _recordingSeconds = 0;
  Timer? _timer;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    context.read<LogsBloc>().add(LogsFetchRequested());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _recorder.start(
          RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 16000, numChannels: 1),
          path: path,
        );
        setState(() {
          _isRecording = true;
          _recordingPath = path;
          _recordingSeconds = 0;
          _showRecordingWarning = false;
        });
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordingSeconds++;
            _showRecordingWarning = _recordingSeconds >= 25; // warn at 25s
          });
          if (_recordingSeconds >= 30) _stopRecording();
        });
      } else {
        _showPermissionDenied();
      }
    } catch (e) {
      if (mounted) _showError('Could not start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    await _recorder.stop();
    final path = _recordingPath;
    setState(() { _isRecording = false; _showRecordingWarning = false; });

    if (path != null && mounted) {
      context.read<LogsBloc>().add(LogCreateRequested(
        audioFile: File(path),
        recordedAt: DateTime.now(),
      ));
    }
  }

  void _showPermissionDenied() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Microphone permission required. Please enable it in Settings.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating),
    );
  }

  String _formatDuration(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, authState) {
        if (authState.status == AuthStatus.unauthenticated) {
          context.go('/login');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Face-to-Action'),
          actions: [
            IconButton(icon: const Icon(Icons.phone), tooltip: 'Call Log', onPressed: () => context.push('/calls')),
            IconButton(icon: const Icon(Icons.history), onPressed: () => context.push('/history')),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'logout') context.read<AuthBloc>().add(AuthLogoutRequested());
                if (v == 'settings') context.push('/settings');
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'settings', child: Text('Settings')),
                const PopupMenuItem(value: 'logout', child: Text('Sign Out')),
              ],
            ),
          ],
        ),
        body: BlocListener<LogsBloc, LogsState>(
          listener: (context, state) {
            if (state.status == LogsStatus.created && state.lastCreatedLog != null) {
              context.push('/log/${state.lastCreatedLog!.id}');
            } else if (state.status == LogsStatus.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage ?? 'Error'), backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating),
              );
            }
          },
          child: BlocBuilder<LogsBloc, LogsState>(
            builder: (context, logsState) {
              return Column(
                children: [
                  // Recording section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppTheme.primary.withOpacity(0.1), Colors.transparent],
                      ),
                    ),
                    child: Column(
                      children: [
                        // Record button
                        GestureDetector(
                          onTap: _isRecording ? _stopRecording : _startRecording,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: _isRecording ? 140 : 120,
                            height: _isRecording ? 140 : 120,
                            decoration: BoxDecoration(
                              color: _isRecording ? AppTheme.error : AppTheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isRecording ? AppTheme.error : AppTheme.primary).withOpacity(0.4),
                                  blurRadius: _isRecording ? 30 : 20,
                                  spreadRadius: _isRecording ? 5 : 0,
                                ),
                              ],
                            ),
                            child: Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white, size: _isRecording ? 60 : 50),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Status text
                        Text(
                          _isRecording
                              ? 'Recording... ${_formatDuration(_recordingSeconds)} / 00:30'
                              : 'Tap to record',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: _isRecording ? AppTheme.error : AppTheme.textSecondary,
                              ),
                        ),
                        if (_isRecording) ...[
                          const SizedBox(height: 4),
                          if (_showRecordingWarning)
                            Text('Almost done — tap to stop', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.accent))
                          else
                            Text('Tap again to stop', style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 16),
                          _RecordingWave(),
                        ],
                        if (logsState.status == LogsStatus.creating) ...[
                          const SizedBox(height: 16),
                          const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            SizedBox(width: 8),
                            Text('Transcribing with AI...'),
                          ]),
                        ],
                        if (!_isRecording && logsState.status != LogsStatus.creating && logsState.logs.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () => context.push('/calls'),
                            icon: const Icon(Icons.phone, size: 18),
                            label: const Text('Log a call'),
                            style: TextButton.styleFrom(foregroundColor: AppTheme.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Recent logs header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Recent Logs', style: Theme.of(context).textTheme.titleLarge),
                        if (logsState.logs.isNotEmpty)
                          TextButton(onPressed: () => context.push('/history'), child: const Text('See all')),
                      ],
                    ),
                  ),
                  // Logs list
                  Expanded(
                    child: _buildLogsList(logsState),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogsList(LogsState state) {
    if (state.status == LogsStatus.loading && state.logs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == LogsStatus.error && state.logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('Could not load logs', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: () => context.read<LogsBloc>().add(LogsFetchRequested()), child: const Text('Retry')),
          ],
        ),
      );
    }
    if (state.logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_add, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text('No logs yet', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Tap the mic to create your first log', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => context.read<LogsBloc>().add(LogsFetchRequested()),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: state.logs.take(5).length,
        itemBuilder: (context, index) => _LogCard(log: state.logs[index]),
      ),
    );
  }
}

class _RecordingWave extends StatefulWidget {
  @override
  State<_RecordingWave> createState() => _RecordingWaveState();
}

class _RecordingWaveState extends State<_RecordingWave> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final offset = (i - 2).abs() / 4;
            final height = 20 + (30 * (0.5 + _controller.value * 0.5) * (1 - offset));
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}

class _LogCard extends StatelessWidget {
  final LogEntry log;
  const _LogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/log/${log.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.receipt_long, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(log.customerName ?? 'Unknown Customer',
                        style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(log.actionTaken ?? 'No action recorded',
                        style: Theme.of(context).textTheme.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (log.amount != null)
                    Text('\$${log.amount!.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.success)),
                  Text(dateFormat.format(log.createdAt),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
