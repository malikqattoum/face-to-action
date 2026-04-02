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
  // AI Extraction fields
  final String? issueType;
  final List<String> partsUsed;
  final double? estimatedPrice;
  final String? serviceType;
  // Photos
  final List<Photo> photos;

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
    this.issueType,
    this.partsUsed = const [],
    this.estimatedPrice,
    this.serviceType,
    this.photos = const [],
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
      issueType: json['issue_type'],
      partsUsed: json['parts_used'] != null
          ? List<String>.from(json['parts_used'])
          : [],
      estimatedPrice: json['estimated_price'] != null
          ? double.tryParse(json['estimated_price'].toString())
          : null,
      serviceType: json['service_type'],
      photos: json['photos'] != null
          ? (json['photos'] as List).map((p) => Photo.fromJson(p)).toList()
          : [],
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
    String? issueType,
    List<String>? partsUsed,
    double? estimatedPrice,
    String? serviceType,
    List<Photo>? photos,
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
      issueType: issueType ?? this.issueType,
      partsUsed: partsUsed ?? this.partsUsed,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      serviceType: serviceType ?? this.serviceType,
      photos: photos ?? this.photos,
    );
  }
}

class Photo {
  final int id;
  final int logId;
  final String? caption;
  final String url;
  final DateTime createdAt;

  Photo({
    required this.id,
    required this.logId,
    this.caption,
    required this.url,
    required this.createdAt,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'],
      logId: json['log_id'] ?? 0,
      caption: json['caption'],
      url: json['url'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
