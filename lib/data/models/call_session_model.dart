class CallSession {
  final int id;
  final int userId;
  final String? contactName;
  final String? phoneNumber;
  final String direction; // incoming, outgoing, missed
  final int durationSeconds;
  final String? durationFormatted;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? notes;
  final bool hasVoiceMemo;
  final DateTime createdAt;

  CallSession({
    required this.id,
    required this.userId,
    this.contactName,
    this.phoneNumber,
    required this.direction,
    required this.durationSeconds,
    this.durationFormatted,
    this.startedAt,
    this.endedAt,
    this.notes,
    this.hasVoiceMemo = false,
    required this.createdAt,
  });

  factory CallSession.fromJson(Map<String, dynamic> json) {
    return CallSession(
      id: json['id'],
      userId: json['user_id'] ?? 0,
      contactName: json['contact_name'],
      phoneNumber: json['phone_number'],
      direction: json['direction'] ?? 'outgoing',
      durationSeconds: json['duration_seconds'] ?? 0,
      durationFormatted: json['duration_formatted'],
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      notes: json['notes'],
      hasVoiceMemo: json['has_voice_memo'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'contact_name': contactName,
      'phone_number': phoneNumber,
      'direction': direction,
      'duration_seconds': durationSeconds,
      'started_at': startedAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'notes': notes,
      'has_voice_memo': hasVoiceMemo,
      'created_at': createdAt.toIso8601String(),
    };
  }

  CallSession copyWith({
    int? id,
    int? userId,
    String? contactName,
    String? phoneNumber,
    String? direction,
    int? durationSeconds,
    String? durationFormatted,
    DateTime? startedAt,
    DateTime? endedAt,
    String? notes,
    bool? hasVoiceMemo,
    DateTime? createdAt,
  }) {
    return CallSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      contactName: contactName ?? this.contactName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      direction: direction ?? this.direction,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      durationFormatted: durationFormatted ?? this.durationFormatted,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      notes: notes ?? this.notes,
      hasVoiceMemo: hasVoiceMemo ?? this.hasVoiceMemo,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get directionIcon {
    switch (direction) {
      case 'incoming': return '↓';
      case 'outgoing': return '↑';
      case 'missed': return '✕';
      default: return '?';
    }
  }

  String get directionLabel {
    switch (direction) {
      case 'incoming': return 'Incoming';
      case 'outgoing': return 'Outgoing';
      case 'missed': return 'Missed';
      default: return direction;
    }
  }
}
