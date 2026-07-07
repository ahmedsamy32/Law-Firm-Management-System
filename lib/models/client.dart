class Client {
  final int? id;
  final String name;
  final String nationalId;
  final String? phone;
  final String? address;
  final DateTime? createdAt;

  Client({
    this.id,
    required this.name,
    required this.nationalId,
    this.phone,
    this.address,
    this.createdAt,
  });

  /// إنشاء نسخة جديدة مع إمكانية تعديل بعض الحقول بشكل آمن (Immutable update)
  Client copyWith({
    int? id,
    String? name,
    String? nationalId,
    String? phone,
    String? address,
    DateTime? createdAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      nationalId: nationalId ?? this.nationalId,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// تحويل البيانات القادمة من قاعدة البيانات أو JSON إلى كائن Client
  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] as int?,
      name: json['name'] as String,
      nationalId: json['national_id'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : null,
    );
  }

  /// تحويل كائن Client إلى Map لحفظه في قاعدة البيانات أو استخدامه كـ JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'national_id': nationalId,
      'phone': phone,
      'address': address,
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Client(id: $id, name: $name, nationalId: $nationalId, phone: $phone, address: $address, createdAt: $createdAt)';
  }
}
