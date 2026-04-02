import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/log_model.dart';
import '../blocs/logs/logs_bloc.dart';
import '../blocs/logs/logs_event.dart';
import '../blocs/logs/logs_state.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<LogsBloc>().add(LogsFetchRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LogEntry> _filteredLogs(LogsState state) {
    if (_searchQuery.isEmpty) return state.logs;
    final q = _searchQuery.toLowerCase();
    return state.logs.where((log) {
      return (log.customerName?.toLowerCase().contains(q) ?? false) ||
          (log.actionTaken?.toLowerCase().contains(q) ?? false) ||
          (log.nextSteps?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search by customer, action, or notes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); })
                    : null,
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<LogsBloc, LogsState>(
              builder: (context, state) {
                if (state.status == LogsStatus.loading && state.logs.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                final logs = _filteredLogs(state);
                if (logs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        Text(_searchQuery.isEmpty ? 'No logs yet' : 'No results found', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => context.read<LogsBloc>().add(LogsFetchRequested()),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: logs.length,
                    itemBuilder: (context, index) => _HistoryLogCard(log: logs[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryLogCard extends StatelessWidget {
  final LogEntry log;
  const _HistoryLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    return Dismissible(
      key: Key('log_${log.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showDialog<bool>(context: context, builder: (_) => AlertDialog(
          title: const Text('Delete Log?'),
          content: const Text('This cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: AppTheme.error))),
          ],
        )) ?? false;
      },
      onDismissed: (_) => context.read<LogsBloc>().add(LogDeleteRequested(log.id)),
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
          onTap: () => context.push('/log/${log.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(log.customerName ?? 'Unknown Customer',
                          style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                    ),
                    if (log.amount != null)
                      Text('\$${log.amount!.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.success)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(log.actionTaken ?? 'No action',
                    style: Theme.of(context).textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (log.nextSteps != null && log.nextSteps!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: AppTheme.accent),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(log.nextSteps!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.accent, fontSize: 12,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Text('${dateFormat.format(log.createdAt)} at ${timeFormat.format(log.createdAt)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12, color: AppTheme.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
