import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/call_session_model.dart';
import '../blocs/calls/calls_bloc.dart';
import '../blocs/calls/calls_event.dart';
import '../blocs/calls/calls_state.dart';

class CallsPage extends StatefulWidget {
  const CallsPage({super.key});

  @override
  State<CallsPage> createState() => _CallsPageState();
}

class _CallsPageState extends State<CallsPage> {
  String? _filter; // all, incoming, outgoing, missed

  @override
  void initState() {
    super.initState();
    context.read<CallsBloc>().add(CallsFetchRequested());
  }

  List<CallSession> _filteredCalls(CallsState state) {
    if (_filter == null) return state.calls;
    return state.calls.where((c) => c.direction == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Log'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => context.read<CallsBloc>().add(CallsFetchRequested())),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(label: 'All', selected: _filter == null, onSelected: (_) => setState(() => _filter = null)),
                const SizedBox(width: 8),
                _FilterChip(label: 'Incoming', selected: _filter == 'incoming', onSelected: (_) => setState(() => _filter = 'incoming')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Outgoing', selected: _filter == 'outgoing', onSelected: (_) => setState(() => _filter = 'outgoing')),
                const SizedBox(width: 8),
                _FilterChip(label: 'Missed', selected: _filter == 'missed', onSelected: (_) => setState(() => _filter = 'missed')),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<CallsBloc, CallsState>(
              builder: (context, state) {
                if (state.status == CallsStatus.loading && state.calls.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                final calls = _filteredCalls(state);
                if (calls.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone_callback, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text('No calls logged', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text('Tap + to log a call', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => context.read<CallsBloc>().add(CallsFetchRequested()),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: calls.length,
                    itemBuilder: (context, index) => _CallCard(call: calls[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        onPressed: () => context.push('/calls/add'),
        icon: const Icon(Icons.add_call),
        label: const Text('Log Call'),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  const _FilterChip({required this.label, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppTheme.primary.withOpacity(0.15),
      checkmarkColor: AppTheme.primary,
      labelStyle: TextStyle(color: selected ? AppTheme.primary : AppTheme.textSecondary),
    );
  }
}

class _CallCard extends StatelessWidget {
  final CallSession call;
  const _CallCard({required this.call});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d');
    final timeFormat = DateFormat('h:mm a');
    final isMissed = call.direction == 'missed';

    return Dismissible(
      key: Key('call_${call.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(context: context, builder: (_) => AlertDialog(
          title: const Text('Delete Call?'),
          content: const Text('This cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: AppTheme.error))),
          ],
        )) ?? false;
      },
      onDismissed: (_) => context.read<CallsBloc>().add(CallDeleteRequested(call.id)),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppTheme.error,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/calls/${call.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Direction icon
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: isMissed ? AppTheme.error.withOpacity(0.1) : AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      call.directionIcon,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isMissed ? AppTheme.error : AppTheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(call.contactName ?? 'Unknown', style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                          ),
                          if (call.hasVoiceMemo)
                            Icon(Icons.mic, size: 16, color: AppTheme.success),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(call.directionLabel, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                          if (call.durationSeconds > 0) ...[
                            const SizedBox(width: 8),
                            Text('•', style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(width: 8),
                            Text(call.durationFormatted ?? '${call.durationSeconds}s', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(dateFormat.format(call.startedAt ?? call.createdAt), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                    Text(timeFormat.format(call.startedAt ?? call.createdAt), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
