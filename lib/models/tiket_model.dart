class TiketModel {
  final String? id; // Server ID (Null saat DRAFT)
  final String localId;
  final String userId;
  final String kategori; // 'Sarpras' atau 'Kebersihan'
  final String judul;
  final String lokasiDetail;
  final String deskripsi;
  final List<String> fotoPaths;
  final int jumlahUpvote;
  final String statusTiket; // 'DRAFT', 'SUBMITTED', 'PENDING_REVIEW', 'APPROVED', 'REJECTED', 'RESOLVED'
  final String? alasanReject;
  final DateTime createdAt;

  TiketModel({
    this.id,
    required this.localId,
    required this.userId,
    required this.kategori,
    required this.judul,
    required this.lokasiDetail,
    required this.deskripsi,
    required this.fotoPaths,
    required this.jumlahUpvote,
    required this.statusTiket,
    this.alasanReject,
    required this.createdAt,
  });

  factory TiketModel.fromJson(Map<String, dynamic> json) {
    return TiketModel(
      id: json['_id'] as String?,
      localId: json['local_id'] as String,
      userId: json['user_id'] as String,
      kategori: json['kategori'] as String,
      judul: json['judul'] as String? ?? 'Tanpa Judul',
      lokasiDetail: json['lokasi_detail'] as String,
      deskripsi: json['deskripsi'] as String,
      fotoPaths: List<String>.from(json['foto_paths'] ?? []),
      jumlahUpvote: json['jumlah_upvote'] as int? ?? 0,
      statusTiket: json['status_tiket'] as String,
      alasanReject: json['alasan_reject'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'local_id': localId,
      'user_id': userId,
      'kategori': kategori,
      'judul': judul,
      'lokasi_detail': lokasiDetail,
      'deskripsi': deskripsi,
      'foto_paths': fotoPaths,
      'jumlah_upvote': jumlahUpvote,
      'status_tiket': statusTiket,
      'alasan_reject': alasanReject,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
