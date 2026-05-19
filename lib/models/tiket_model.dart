import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

class TiketModel {
  final String? id; // '_id' in MongoDB
  final String idTiket; // 'idTiket'
  final String idUser; // 'idUser'
  final String emailUser; // 'emailUser'

  final String judulSingkat; // 'judulSingkat'
  final String deskripsiTiket; // 'deskripsiTiket'
  final String? deskripsiLokasi; // 'deskripsiLokasi'

  final KategoriModel kategori; // 'kategori'
  final LokasiModel lokasi; // 'lokasi'

  final List<String> buktiVisual; // 'buktiVisual'

  final String
  status; // 'status' (Menunggu Verifikasi, Approved, Rejected, Documented)
  final String?
  tingkatUrgensi; // 'tingkatUrgensi' (Prioritas Tinggi, Prioritas Sedang, Prioritas Rendah)

  final DateTime tanggalPembuatan; // 'tanggalPembuatan'
  final DateTime tanggalPengajuan; // 'tanggalPengajuan'
  final DateTime? tanggalVerifikasi; // 'tanggalVerifikasi'
  final DateTime? tanggalApproval; // 'tanggalApproval'
  final DateTime? tanggalRejection; // 'tanggalRejection'
  final DateTime? tanggalExport; // 'tanggalExport'

  final String? alasanRejection; // 'alasanRejection'
  final String? catatanPJ; // 'catatanPJ'
  final String? idPenanggungJawab; // 'idPenanggungJawab'

  final int jumlahVote; // 'jumlahVote'
  final List<CommentModel> comments; // 'comments'

  final DateTime createdAt; // 'createdAt'
  final DateTime updatedAt; // 'updatedAt'
  final DateTime? deletedAt; // 'deletedAt'

  TiketModel({
    this.id,
    required this.idTiket,
    required this.idUser,
    required this.emailUser,
    required this.judulSingkat,
    required this.deskripsiTiket,
    this.deskripsiLokasi,
    required this.kategori,
    required this.lokasi,
    required this.buktiVisual,
    required this.status,
    this.tingkatUrgensi,
    required this.tanggalPembuatan,
    required this.tanggalPengajuan,
    this.tanggalVerifikasi,
    this.tanggalApproval,
    this.tanggalRejection,
    this.tanggalExport,
    this.alasanRejection,
    this.catatanPJ,
    this.idPenanggungJawab,
    required this.jumlahVote,
    required this.comments,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory TiketModel.fromJson(Map<String, dynamic> json) {
    return TiketModel(
      id: _parseObjectId(json['_id']),
      idTiket: json['idTiket'] as String? ?? 'UNKNOWN',
      idUser: _parseObjectId(json['idUser']) ?? '',
      emailUser: json['emailUser'] as String? ?? '',
      judulSingkat: json['judulSingkat'] as String? ?? 'Tanpa Judul',
      deskripsiTiket: json['deskripsiTiket'] as String? ?? '',
      deskripsiLokasi: json['deskripsiLokasi'] as String?,
      kategori: KategoriModel.fromJson(json['kategori'] ?? {}),
      lokasi: LokasiModel.fromJson(json['lokasi'] ?? {}),
      buktiVisual: List<String>.from(json['buktiVisual'] ?? []),
      status: json['status'] as String? ?? 'Menunggu Verifikasi',
      tingkatUrgensi: json['tingkatUrgensi'] as String?,
      tanggalPembuatan: _parseDate(json['tanggalPembuatan']),
      tanggalPengajuan: _parseDate(json['tanggalPengajuan']),
      tanggalVerifikasi: _parseNullableDate(json['tanggalVerifikasi']),
      tanggalApproval: _parseNullableDate(json['tanggalApproval']),
      tanggalRejection: _parseNullableDate(json['tanggalRejection']),
      tanggalExport: _parseNullableDate(json['tanggalExport']),
      alasanRejection: json['alasanRejection'] as String?,
      catatanPJ: json['catatanPJ'] as String?,
      idPenanggungJawab: _parseObjectId(json['idPenanggungJawab']),
      jumlahVote: json['jumlahVote'] as int? ?? 0,
      comments:
          (json['comments'] as List<dynamic>?)
              ?.map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      deletedAt: _parseNullableDate(json['deletedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'idTiket': idTiket,
      'idUser': idUser,
      'emailUser': emailUser,
      'judulSingkat': judulSingkat,
      'deskripsiTiket': deskripsiTiket,
      'deskripsiLokasi': deskripsiLokasi,
      'kategori': kategori.toJson(),
      'lokasi': lokasi.toJson(),
      'buktiVisual': buktiVisual,
      'status': status,
      'tingkatUrgensi': tingkatUrgensi,
      'tanggalPembuatan': tanggalPembuatan.toIso8601String(),
      'tanggalPengajuan': tanggalPengajuan.toIso8601String(),
      'tanggalVerifikasi': tanggalVerifikasi?.toIso8601String(),
      'tanggalApproval': tanggalApproval?.toIso8601String(),
      'tanggalRejection': tanggalRejection?.toIso8601String(),
      'tanggalExport': tanggalExport?.toIso8601String(),
      'alasanRejection': alasanRejection,
      'catatanPJ': catatanPJ,
      if (idPenanggungJawab != null) 'idPenanggungJawab': idPenanggungJawab,
      'jumlahVote': jumlahVote,
      'comments': comments.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
    if (id != null) map['_id'] = id; // Jangan set id jika tidak ada
    return map;
  }

  String get lokasiDisplay {
    final base = lokasi.lantai > 0
        ? '${lokasi.gedung}, Lt ${lokasi.lantai}'
        : lokasi.gedung;
    if (deskripsiLokasi != null && deskripsiLokasi!.isNotEmpty) {
      return '$base · ${deskripsiLokasi!}';
    }
    return base;
  }

  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is DateTime) return date;
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    return DateTime.now();
  }

  static DateTime? _parseNullableDate(dynamic date) {
    if (date == null) return null;
    if (date is DateTime) return date;
    if (date is String) return DateTime.tryParse(date);
    return null;
  }

  static String? _parseObjectId(dynamic value) {
    if (value == null) return null;
    if (value is ObjectId) return value.toHexString();
    // Jika value string yang berformat ObjectId("..."), kita ekstrak (fallback)
    final str = value.toString();
    if (str.startsWith('ObjectId("') && str.endsWith('")')) {
      return str.substring(10, str.length - 2);
    }
    return str;
  }
}

class KategoriModel {
  final String utama;
  final String jenis;

  KategoriModel({required this.utama, required this.jenis});

  factory KategoriModel.fromJson(Map<String, dynamic> json) {
    return KategoriModel(
      utama: json['utama'] as String? ?? '',
      jenis: json['jenis'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'utama': utama, 'jenis': jenis};
}

class LokasiModel {
  final String gedung;
  final int lantai;
  final String ruangan;

  LokasiModel({
    required this.gedung,
    required this.lantai,
    required this.ruangan,
  });

  factory LokasiModel.fromJson(Map<String, dynamic> json) {
    return LokasiModel(
      gedung: json['gedung'] as String? ?? '',
      lantai: json['lantai'] as int? ?? 0,
      ruangan: json['ruangan'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'gedung': gedung,
    'lantai': lantai,
    'ruangan': ruangan,
  };
}

class CommentModel {
  final String? id;
  final String idUser;
  final String emailUser;
  final String content;
  final DateTime tanggalKomentar;
  final bool isDeleted;
  final String? profileImageUrl;

  CommentModel({
    this.id,
    required this.idUser,
    required this.emailUser,
    required this.content,
    required this.tanggalKomentar,
    required this.isDeleted,
    this.profileImageUrl,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: TiketModel._parseObjectId(json['_id']),
      idUser: TiketModel._parseObjectId(json['idUser']) ?? '',
      emailUser: json['emailUser'] as String? ?? '',
      content: json['content'] as String? ?? '',
      tanggalKomentar: TiketModel._parseDate(json['tanggalKomentar']),
      isDeleted: json['isDeleted'] as bool? ?? false,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'idUser': idUser,
      'emailUser': emailUser,
      'content': content,
      'tanggalKomentar': tanggalKomentar.toIso8601String(),
      'isDeleted': isDeleted,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
    };
  }
}
