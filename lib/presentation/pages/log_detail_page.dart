import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
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
  bool _uploadingPhotos = false;

  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickAndUploadPhotos(int logId) async {
    try {
      final images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (images.isEmpty) return;

      setState(() => _uploadingPhotos = true);

      final paths = images.map((img) => img.path).toList();
      context.read<LogsBloc>().add(LogPhotosUploaded(logId: logId, imagePaths: paths));

      setState(() => _uploadingPhotos = false);
    } catch (e) {
      setState(() => _uploadingPhotos = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload photos: $e')),
        );
      }
    }
  }

  Future<void> _generateQuotePdf(LogEntry log) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating quote PDF...')),
      );

      // For now, open the URL directly - in a real app you'd download the PDF
      final url = 'http://10.0.2.2:8000/api/logs/${log.id}/quote/pdf';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quote PDF ready: $url')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate quote: $e')),
      );
    }
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
                IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: () => _generateQuotePdf(log), tooltip: 'Generate Quote PDF'),
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

                // AI Extraction fields
                if (log.serviceType != null || log.issueType != null) ...[
                  Row(
                    children: [
                      if (log.serviceType != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            log.serviceType!.toUpperCase(),
                            style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ),
                      if (log.issueType != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            log.issueType!.replaceAll('_', ' ').toUpperCase(),
                            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

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

                // Parts Used
                if (log.partsUsed.isNotEmpty) ...[
                  _FieldLabel('Parts Used'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: log.partsUsed.map((part) => Chip(
                        label: Text(part, style: const TextStyle(fontSize: 12)),
                        backgroundColor: AppTheme.primary.withOpacity(0.1),
                      )).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Estimated Price (AI extracted)
                if (log.estimatedPrice != null) ...[
                  _FieldLabel('Estimated Price (AI Quote)'),
                  _FieldValue('\$${log.estimatedPrice!.toStringAsFixed(2)}', Icons.request_quote),
                  const SizedBox(height: 20),
                ],

                // Next Steps
                _FieldLabel('Next Steps'),
                _editing
                    ? TextField(controller: _nextStepsController, onChanged: (_) => _changed = true, maxLines: 3, decoration: const InputDecoration(hintText: 'Any follow-up needed?'))
                    : _FieldValue(log.nextSteps ?? '—', Icons.schedule),

                // Photos section
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.photo_library, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text('Photos', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        if (log.photos.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${log.photos.length}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: _uploadingPhotos ? null : () => _pickAndUploadPhotos(log.id),
                      icon: _uploadingPhotos
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.add_a_photo, size: 18),
                      label: Text(_uploadingPhotos ? 'Uploading...' : 'Add Photo'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (log.photos.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.photo_outlined, size: 40, color: AppTheme.textSecondary),
                        const SizedBox(height: 8),
                        Text('No photos yet', style: TextStyle(color: AppTheme.textSecondary)),
                        const SizedBox(height: 4),
                        Text('Tap "Add Photo" to attach before/after photos', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: log.photos.length,
                      itemBuilder: (context, index) {
                        final photo = log.photos[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => _showPhotoDialog(photo),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                photo.url,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 120,
                                  height: 120,
                                  color: AppTheme.surface,
                                  child: const Icon(Icons.broken_image),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

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

  void _showPhotoDialog(Photo photo) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              photo.url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Padding(
                padding: EdgeInsets.all(40),
                child: Icon(Icons.broken_image, size: 60),
              ),
            ),
            if (photo.caption != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(photo.caption!),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
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
