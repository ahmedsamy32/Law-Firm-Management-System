class PowerOfAttorney {
  final int? id;
  final String poaNumber;
  final String documentationOffice;
  final String? filePath;
  final int clientId;
  final DateTime? createdAt;

  PowerOfAttorney({
    this.id,
    required this.poaNumber,
    required this.documentationOffice,
    this.filePath,
    required this.clientId,
    this.createdAt,
  });

  /// إنشاء نسخة جديدة مع إمكانية تعديل بعض الحقول بشكل آمن (Immutable update)
  PowerOfAttorney copyWith({
    int? id,
    String? poaNumber,
    String? documentationOffice,
    String? filePath,
    int? clientId,
    DateTime? createdAt,
  }) {
    return PowerOfAttorney(
      id: id ?? this.id,
      poaNumber: poaNumber ?? this.poaNumber,
      documentationOffice: documentationOffice ?? this.documentationOffice,
      filePath: filePath ?? this.filePath,
      clientId: clientId ?? this.clientId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// تحويل البيانات القادمة من قاعدة البيانات أو JSON إلى كائن PowerOfAttorney
  factory PowerOfAttorney.fromJson(Map<String, dynamic> json) {
    return PowerOfAttorney(
      id: json['id'] as int?,
      poaNumber: json['poa_number'] as String,
      documentationOffice: json['documentation_office'] as String,
      filePath: json['file_path'] as String?,
      clientId: json['client_id'] as int,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  /// تحويل كائن PowerOfAttorney إلى Map لحفظه في قاعدة البيانات أو استخدامه كـ JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'poa_number': poaNumber,
      'documentation_office': documentationOffice,
      'file_path': filePath,
      'client_id': clientId,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'PowerOfAttorney(id: $id, poaNumber: $poaNumber, documentationOffice: $documentationOffice, filePath: $filePath, clientId: $clientId, createdAt: $createdAt)';
  }
}
