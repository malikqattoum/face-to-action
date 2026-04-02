class LogEntry {
  final int id;
  final int userId;
  final String? customerName;
  final String? actionTaken;
  final double? amount;
  final String currency;
  final String? nextSteps;
  final DateTime? recordedAt;
  final String? transcribedText;
  final DateTime createdAt;

  LogEntry({
    required this.id,
    required this.userId,
    this.customerName,
    this.actionTaken,
    this.amount,
    this.currency = 'USD',
    this.nextSteps,
    this.recordedAt,
    this.transcribedText,
    required this.createdAt,
  });

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      id: json['id'],
      userId: json['user_id'],
      customerName: json['customer_name'],
      actionTaken: json['action_taken'],
      amount: json['amount'] != null ? double.tryParse(json['amount'].toString()) : null,
      currency: json['currency'] ?? 'USD',
      nextSteps: json['next_steps'],
      recordedAt: json['recorded_at'] != null ? DateTime.parse(json['recorded_at']) : null,
      transcribedText: json['transcribed_text'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'customer_name': customerName,
      'action_taken': actionTaken,
      'amount': amount,
      'currency': currency,
      'next_steps': nextSteps,
      'recorded_at': recordedAt?.toIso8601String(),
      'transcribed_text': transcribedText,
      'created_at': createdAt.toIso8601String(),
    };
  }

  LogEntry copyWith({
    int? id,
    int? userId,
    String? customerName,
    String? actionTaken,
    double? amount,
    String? currency,
    String? nextSteps,
    DateTime? recordedAt,
    String? transcribedText,
    DateTime? createdAt,
  }) {
    return LogEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerName: customerName ?? this.customerName,
      actionTaken: actionTaken ?? this.actionTaken,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      nextSteps: nextSteps ?? this.nextSteps,
      recordedAt: recordedAt ?? this.recordedAt,
      transcribedText: transcribedText ?? this.transcribedText,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
