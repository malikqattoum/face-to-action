import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/log_model.dart';
import '../blocs/logs/logs_bloc.dart';
import '../blocs/logs/logs_event.dart';
import '../blocs/logs/logs_state.dart';

class LogDetailPage extends StatefulWidget {
  final int logId;
  const LogDetailPage({super.key, required this.logId});

  @override
  State<LogDetailPage> createState() => _LogDetailPageState();
}

class _LogDetailPageState extends State<LogDetailPage> {
  late TextEditingController _customerController;
  late TextEditingController _actionController;
  late TextEditingController _amountController;
  late TextEditingController _nextStepsController;
  bool _editing = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _customerController = TextEditingController();
    _actionController = TextEditingController();
    _amountController = TextEditingController();
    _nextStepsController = TextEditingController();
  }

  @override
  void dispose() {
    _customerController.dispose();
    _actionController.dispose();
    _amountController.dispose();
    _nextStepsController.dispose();
    super.dispose();
  }

  void _populateFields(LogEntry log) {
    if (!_changed) {
      _customerController.text = log.customerName ?? '';
      _actionController.text = log.actionTaken ?? '';
      _amountController.text = log.amount?.toString() ?? '';
      _nextStepsController.text = log.nextSteps ?? '';
    }
  }

  void _save(LogEntry log) {
    final data = <String, dynamic>{};
    if (_customerController.text != log.customerName) data['customer_name'] = _customerController.text;
    if (_actionController.text != log.actionTaken) data['action_taken'] = _actionController.text;
    if (_amountController.text.isNotEmpty && double.tryParse(_amountController.text) != log.amount) {
      data['amount'] = double.tryParse(_amountController.text);
    }
    if (_nextStepsController.text != log.nextSteps) data['next_steps'] = _nextStepsController.text;

    if (data.isNotEmpty) {
      context.read<LogsBloc>().add(LogUpdateRequested(id: log.id, data: data));
    }
    setState(() => _editing = false);
  }

  void _confirmDelete(LogEntry log) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Delete Log?'),
      content: const Text('This action cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            context.read<LogsBloc>().add(LogDeleteRequested(log.id));
            context.pop();
          },
          child: Text('Delete', style: TextStyle(color: AppTheme.error)),
        ),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM d, yyyy • h:mm a');

    return BlocBuilder<LogsBloc, LogsState>(
      builder: (context, state) {
        final log = state.logs.where((l) => l.id == widget.logId).firstOrNull;
        if (log == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Log')),
            body: const Center(child: Text('Log not found')),
          );
        }

        _populateFields(log);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Log Details'),
            actions: [
              if (!_editing) ...[
                IconButton(icon: const Icon(Icons.edit), onPressed: () => setState(() => _editing = true)),
                IconButton(icon: Icon(Icons.delete, color: AppTheme.error), onPressed: () => _confirmDelete(log)),
              ] else ...[
                TextButton(onPressed: () { setState(() { _editing = false; _changed = false; }); }, child: const Text('Cancel')),
                TextButton(onPressed: () => _save(log), child: const Text('Save')),
              ],
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timestamp
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      log.recordedAt != null ? dateFormat.format(log.recordedAt!) : dateFormat.format(log.createdAt),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Customer
                _FieldLabel('Customer Name'),
                _editing
                    ? TextField(controller: _customerController, onChanged: (_) => _changed = true, decoration: const InputDecoration(hintText: 'e.g. Mr. Smith'))
                    : _FieldValue(log.customerName ?? '—', Icons.person_outline),

                const SizedBox(height: 20),

                // Action Taken
                _FieldLabel('Action Taken'),
                _editing
                    ? TextField(controller: _actionController, onChanged: (_) => _changed = true, maxLines: 3, decoration: const InputDecoration(hintText: 'What did you do?'))
                    : _FieldValue(log.actionTaken ?? '—', Icons.build_outlined),

                const SizedBox(height: 20),

                // Amount
                _FieldLabel('Amount'),
                _editing
                    ? TextField(controller: _amountController, onChanged: (_) => _changed = true, keyboardType: TextInputType.number, decoration: const InputDecoration(prefixText: '\$ ', hintText: '0.00'))
                    : _FieldValue(log.amount != null ? '\$${log.amount!.toStringAsFixed(2)}' : '—', Icons.attach_money),

                const SizedBox(height: 20),

                // Next Steps
                _FieldLabel('Next Steps'),
                _editing
                    ? TextField(controller: _nextStepsController, onChanged: (_) => _changed = true, maxLines: 3, decoration: const InputDecoration(hintText: 'Any follow-up needed?'))
                    : _FieldValue(log.nextSteps ?? '—', Icons.schedule),

                // Transcribed text (read-only)
                if (log.transcribedText != null && log.transcribedText!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.text_fields, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Text('Raw Transcript', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.circular(8)),
                    child: Text(log.transcribedText!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
                  ),
                ],
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
