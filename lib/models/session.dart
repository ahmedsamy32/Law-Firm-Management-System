class Session {
  final int? id;
  final DateTime sessionDate;
  final String? decision;
  final String? nextRequirements;
  final int caseId;
  final DateTime? createdAt;

  Session({
    this.id,
    required this.sessionDate,
    this.decision,
    this.nextRequirements,
    required this.caseId,
    this.createdAt,
  });

  /// إنشاء نسخة جديدة مع إمكانية تعديل بعض الحقول بشكل آمن (Immutable update)
  Session copyWith({
    int? id,
    DateTime? sessionDate,
    String? decision,
    String? nextRequirements,
    int? caseId,
    DateTime? createdAt,
  }) {
    return Session(
      id: id ?? this.id,
      sessionDate: sessionDate ?? this.sessionDate,
      decision: decision ?? this.decision,
      nextRequirements: nextRequirements ?? this.nextRequirements,
      caseId: caseId ?? this.caseId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// تحويل البيانات القادمة من قاعدة البيانات أو JSON إلى كائن Session
  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as int?,
      sessionDate: DateTime.parse(json['session_date'] as String),
      decision: json['decision'] as String?,
      nextRequirements: json['next_requirements'] as String?,
      caseId: json['case_id'] as int,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  /// تحويل كائن Session إلى Map لحفظه في قاعدة البيانات أو استخدامه كـ JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'session_date': sessionDate.toIso8601String(),
      'decision': decision,
      'next_requirements': nextRequirements,
      'case_id': caseId,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Session(id: $id, sessionDate: $sessionDate, decision: $decision, nextRequirements: $nextRequirements, caseId: $caseId, createdAt: $createdAt)';
  }
}
