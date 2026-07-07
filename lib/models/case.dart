class Case {
  final int? id;
  final String caseNumber;
  final String caseType;
  final String court;
  final String circle;
  final int clientId;
  final DateTime? createdAt;

  Case({
    this.id,
    required this.caseNumber,
    required this.caseType,
    required this.court,
    required this.circle,
    required this.clientId,
    this.createdAt,
  });

  /// إنشاء نسخة جديدة مع إمكانية تعديل بعض الحقول بشكل آمن (Immutable update)
  Case copyWith({
    int? id,
    String? caseNumber,
    String? caseType,
    String? court,
    String? circle,
    int? clientId,
    DateTime? createdAt,
  }) {
    return Case(
      id: id ?? this.id,
      caseNumber: caseNumber ?? this.caseNumber,
      caseType: caseType ?? this.caseType,
      court: court ?? this.court,
      circle: circle ?? this.circle,
      clientId: clientId ?? this.clientId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// تحويل البيانات القادمة من قاعدة البيانات أو JSON إلى كائن Case
  factory Case.fromJson(Map<String, dynamic> json) {
    return Case(
      id: json['id'] as int?,
      caseNumber: json['case_number'] as String,
      caseType: json['case_type'] as String,
      court: json['court'] as String,
      circle: json['circle'] as String,
      clientId: json['client_id'] as int,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  /// تحويل كائن Case إلى Map لحفظه في قاعدة البيانات أو استخدامه كـ JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'case_number': caseNumber,
      'case_type': caseType,
      'court': court,
      'circle': circle,
      'client_id': clientId,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Case(id: $id, caseNumber: $caseNumber, caseType: $caseType, court: $court, circle: $circle, clientId: $clientId, createdAt: $createdAt)';
  }
}
