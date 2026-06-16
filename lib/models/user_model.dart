enum UserRole {
  admin,
  petugas,
  pelanggan;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.pelanggan,
    );
  }
}

enum TipePelanggan {
  rumahTangga,
  bisnis;

  String get dbValue {
    switch (this) {
      case TipePelanggan.rumahTangga:
        return 'rumah_tangga';
      case TipePelanggan.bisnis:
        return 'bisnis';
    }
  }

  static TipePelanggan fromString(String? value) {
    if (value == 'rumah_tangga') return TipePelanggan.rumahTangga;
    if (value == 'bisnis') return TipePelanggan.bisnis;
    return TipePelanggan.rumahTangga;
  }
}

class UserModel {
  final String id;
  final String username;
  final UserRole role;
  final String namaLengkap;
  final String alamat;
  final TipePelanggan tipePelanggan;
  final bool isFirstLogin;

  UserModel({
    required this.id,
    required this.username,
    required this.role,
    required this.namaLengkap,
    required this.alamat,
    required this.tipePelanggan,
    required this.isFirstLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String? ?? 'pelanggan'),
      namaLengkap: json['nama_lengkap'] as String? ?? '',
      alamat: json['alamat'] as String? ?? '',
      tipePelanggan: TipePelanggan.fromString(json['tipe_pelanggan'] as String?),
      isFirstLogin: json['is_first_login'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role.name,
      'nama_lengkap': namaLengkap,
      'alamat': alamat,
      'tipe_pelanggan': tipePelanggan.dbValue,
      'is_first_login': isFirstLogin,
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    UserRole? role,
    String? namaLengkap,
    String? alamat,
    TipePelanggan? tipePelanggan,
    bool? isFirstLogin,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      role: role ?? this.role,
      namaLengkap: namaLengkap ?? this.namaLengkap,
      alamat: alamat ?? this.alamat,
      tipePelanggan: tipePelanggan ?? this.tipePelanggan,
      isFirstLogin: isFirstLogin ?? this.isFirstLogin,
    );
  }
}
