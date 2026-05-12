import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/report_form_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/feed_provider.dart';
import 'camera_screen.dart';

class ReportFormWizardScreen extends StatefulWidget {
  const ReportFormWizardScreen({super.key});

  @override
  State<ReportFormWizardScreen> createState() => _ReportFormWizardScreenState();
}

class _ReportFormWizardScreenState extends State<ReportFormWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;
  bool _isSubmitting = false;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    final provider = context.read<ReportFormProvider>();
    bool canProceed = false;

    if (_currentStep == 0)
      canProceed = provider.isStep1Valid;
    else if (_currentStep == 1)
      canProceed = provider.isStep2Valid;
    else if (_currentStep == 2)
      canProceed = provider.isStep3Valid;

    if (canProceed) {
      if (_currentStep < _totalSteps - 1) {
        setState(() {
          _currentStep++;
        });
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap lengkapi data pada tahap ini terlebih dahulu!'),
        ),
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context); // Kembali ke Dashboard
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentStep > 0) {
          _prevStep();
          return false; // Mencegah pop karena kita mundur langkah
        }
        return true; // Boleh pop jika di langkah 1
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF2A5256), // Teal gelap untuk latar atas
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                          ),
                          child: CircleAvatar(
                            backgroundColor: Colors.transparent,
                            radius: 18,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: _prevStep,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Form Pelaporan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${_currentStep + 1}/$_totalSteps',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Main Content Area
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8F3EC),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    children: [
                      // PageView for content
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          physics:
                              const NeverScrollableScrollPhysics(), // Disable swipe
                          children: [
                            _buildStep1Image(context),
                            _buildStep2CategoryLocation(context),
                            _buildStep3Details(context),
                            _buildStep4Review(context),
                          ],
                        ),
                      ),

                      // Bottom Navigation Button
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Align(
                          alignment: _currentStep == _totalSteps - 1 ? Alignment.center : Alignment.centerRight,
                          child: SizedBox(
                            width: _currentStep == _totalSteps - 1 ? double.infinity : 150,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: (_isSubmitting || (_currentStep == _totalSteps - 1 && (context.watch<ReportFormProvider>().deskripsi.trim().isEmpty || !_agreeToTerms)))
                                  ? null
                                  : () async {
                                      if (_currentStep == _totalSteps - 1) {
                                        // Submit Report
                                        setState(() {
                                          _isSubmitting = true;
                                        });
                                        try {
                                          final authProvider = context
                                              .read<AuthProvider>();
                                          final formProvider = context
                                              .read<ReportFormProvider>();

                                          final email =
                                              authProvider.email ??
                                              'mahasiswa@polban.ac.id';
                                          final userId =
                                              authProvider.userId ??
                                              '6672a1b4f3c3c3c3c3c3c3c1'; // Fallback aman

                                          await formProvider.submitReport(
                                            email,
                                            userId,
                                          );

                                          // Segarkan Beranda
                                          context
                                              .read<FeedProvider>()
                                              .fetchReports();

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Laporan Berhasil Diunggah!',
                                              ),
                                            ),
                                          );
                                          formProvider.resetForm();
                                          Navigator.pop(context);
                                        } catch (e) {
                                          if (e.toString().contains("OFFLINE_SAVED")) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Koneksi terputus. Laporan disimpan secara offline dan akan dikirim otomatis saat online!'),
                                                backgroundColor: Colors.orange,
                                              ),
                                            );
                                            context.read<ReportFormProvider>().resetForm();
                                            Navigator.pop(context);
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Gagal mengirim laporan: $e',
                                                ),
                                              ),
                                            );
                                          }
                                        } finally {
                                          if (mounted) {
                                            setState(() {
                                              _isSubmitting = false;
                                            });
                                          }
                                        }
                                      } else {
                                        _nextStep();
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _currentStep == _totalSteps - 1
                                    ? const Color(0xFFA03232)
                                    : Colors.white, // Merah untuk akhir
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: _currentStep == _totalSteps - 1
                                        ? Colors.transparent
                                        : const Color(0xFF5A7184),
                                    width: 1,
                                  ),
                                ),
                                elevation: 0,
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : _currentStep == _totalSteps - 1
                                    ? const Text(
                                        'Unggah Pelaporan',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Text(
                                            'Selanjutnya',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF5A7184),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward, size: 16, color: Color(0xFF5A7184)),
                                        ],
                                      ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- STEP 1: UPLOAD IMAGE ---
  Widget _buildStep1Image(BuildContext context) {
    final provider = context.watch<ReportFormProvider>();
    final bool hasImage = provider.imagePath != null;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bukti Kerusakan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5A7184),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GestureDetector(
              onTap: hasImage
                  ? null
                  : () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null) {
                        provider.setImagePath(image.path);
                      }
                    },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(
                          File(provider.imagePath!),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ketuk untuk mengambil foto',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          if (hasImage) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraScreen()));
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Foto Ulang'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5A7184),
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) provider.setImagePath(image.path);
                    },
                    icon: const Icon(Icons.image, size: 18),
                    label: const Text('Gallery'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5A7184),
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraScreen()));
                },
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Buka Kamera'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF5A7184),
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _getTitleOptions(String? utama, String? jenis) {
    if (utama == 'Sarana Prasarana') {
      if (jenis == 'Elektronik') {
        return [
          'AC Mati',
          'Proyektor Rusak',
          'Komputer Rusak',
          'Lampu Ruang Mati',
          'Kipas Angin Tidak Berputar',
          'Stop Kontak Rusak',
        ];
      }
      if (jenis == 'Non Elektronik') {
        return [
          'Pintu Rusak',
          'Kursi Retak',
          'Meja Patah',
          'Jendela Pecah',
          'Plafon Bocor',
          'Kunci Tidak Berfungsi',
        ];
      }
    }

    if (utama == 'Kebersihan') {
      if (jenis == 'Fasilitas Sanitasi') {
        return [
          'Kloset Mampet / Kotor',
          'Wastafel Tersumbat / Kotor',
          'Lantai Toilet Tergenang / Sangat Licin',
          'Bau Tidak Sedap / Menyengat',
          'Tempat Sampah Penuh',
        ];
      }
      if (jenis == 'Dalam Ruangan') {
        return [
          'Lantai Kotor / Lengket / Berdebu',
          'Sampah Berserakan / Tertinggal di Laci',
          'Tempat Sampah Ruangan Penuh / Meluber',
          'Tumpahan Cairan / Sisa Makanan',
          'Jaring Laba-laba / Debu Tebal (Plafon/Sudut Ruangan)',
          'Ada Bangkai Hewan / Hama (Tikus, Kecoa, dsb)',
        ];
      }
      if (jenis == 'Luar Ruangan') {
        return [
          'Sampah / Daun Kering Berserakan & Menumpuk',
          'Selokan / Saluran Air Pembuangan Mampet',
          'Tempat Sampah Umum Terbuka Penuh / Tumpah',
          'Genangan Lumpur / Lumut Licin di Area Jalan',
          'Vandalisme / Coretan di Dinding atau Fasilitas Umum',
          'Sisa Makanan Tertinggal di Area Terbuka (Kantin/Pendopo)',
        ];
      }
    }
    return [];
  }

  // --- STEP 2: LOCATION ---
  Widget _buildStep2CategoryLocation(BuildContext context) {
    final provider = context.watch<ReportFormProvider>();
    final buildings = [
      'Gedung A',
      'Gedung B',
      'Gedung C',
      'Gedung D',
      'Gedung E',
      'Gedung F',
      'Gedung G',
      'Gedung H',
      'Masjid',
      'Perpustakaan',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lokasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5A7184),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: buildings.map((gedung) {
              final isActive = provider.gedung == gedung;
              return GestureDetector(
                onTap: () => provider.setGedung(gedung),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF2A5256) : Colors.white,
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF2A5256)
                          : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    gedung,
                    style: TextStyle(
                      color: isActive ? Colors.white : const Color(0xFF5A7184),
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          const Text(
            'Keterangan Tempat (opsional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5A7184),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: provider.deskripsiLokasi,
            onChanged: (val) => provider.setDeskripsiLokasi(val),
            maxLines: 4,
            style: const TextStyle(color: Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: 'Contoh: Lantai 2 ruang kelas 203',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2A5256),
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 3: CATEGORY & PROBLEM TYPE ---
  Widget _buildStep3Details(BuildContext context) {
    final provider = context.watch<ReportFormProvider>();
    final categories = [
      {'name': 'Sarana Prasarana', 'icon': Icons.business},
      {'name': 'Kebersihan', 'icon': Icons.cleaning_services},
    ];
    final sarprasTypes = ['Elektronik', 'Non Elektronik'];
    final kebersihanTypes = [
      'Fasilitas Sanitasi',
      'Dalam Ruangan',
      'Luar Ruangan',
    ];
    final titleOptions = _getTitleOptions(
      provider.kategoriUtama,
      provider.kategoriJenis,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kategori Masalah',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5A7184),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: categories.map((cat) {
              final isActive = provider.kategoriUtama == cat['name'];
              final bool isSarpras = cat['name'] == 'Sarana Prasarana';
              final activeColor = isSarpras ? const Color(0xFF2A5256) : const Color(0xFFE09F3E);
              
              return Expanded(
                child: GestureDetector(
                  onTap: () => provider.setKategoriUtama(cat['name'] as String),
                  child: Container(
                    margin: EdgeInsets.only(
                      right: cat == categories.first ? 12 : 0,
                      left: cat == categories.last ? 12 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isActive ? activeColor : Colors.white,
                      border: Border.all(
                        color: isActive
                            ? activeColor
                            : Colors.grey.shade300,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      cat['name'] as String,
                      style: TextStyle(
                        color: isActive
                            ? (isSarpras ? Colors.white : const Color(0xFF2A5256))
                            : const Color(0xFF5A7184),
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (provider.kategoriUtama != null) ...[
            const SizedBox(height: 32),
            const Text(
              'Subkategori',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A7184),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 12,
              children:
                  (provider.kategoriUtama == 'Sarana Prasarana'
                          ? sarprasTypes
                          : kebersihanTypes)
                      .map((type) {
                        final isActive = provider.kategoriJenis == type;
                        return GestureDetector(
                          onTap: () => provider.setKategoriJenis(type),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFF2A5256)
                                  : Colors.white,
                              border: Border.all(
                                color: isActive
                                    ? const Color(0xFF2A5256)
                                    : Colors.grey.shade300,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                color: isActive
                                    ? Colors.white
                                    : const Color(0xFF5A7184),
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      })
                      .toList(),
            ),
          ],
          if (provider.kategoriJenis != null) ...[
            const SizedBox(height: 32),
            const Text(
              'Pilih Judul Laporan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A7184),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: titleOptions.map((title) {
                final isSelected = provider.judul == title;
                return Card(
                  color: isSelected ? const Color(0xFF2A5256) : Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF2A5256)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF1E293B),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.white)
                        : null,
                    onTap: () => provider.setJudul(title),
                  ),
                );
              }).toList(),
            ),
          ],
          if (provider.kategoriUtama == null) ...[
            const SizedBox(height: 24),
            Text(
              'Pilih kategori utama untuk menampilkan subkategori dan judul laporan.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
          if (provider.kategoriUtama != null &&
              provider.kategoriJenis == null) ...[
            const SizedBox(height: 24),
            Text(
              'Pilih subkategori terlebih dahulu untuk melihat opsi judul.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  // --- STEP 4: REVIEW ---
  Widget _buildStep4Review(BuildContext context) {
    final provider = context.watch<ReportFormProvider>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Laporan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2A5256),
            ),
          ),
          const SizedBox(height: 24),
          _buildReviewCard(
            title: 'Bukti Laporan',
            stepIndex: 0,
            content: provider.imagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(provider.imagePath!),
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Text('Belum ada foto', style: TextStyle(color: Color(0xFF5A7184))),
          ),
          _buildReviewCard(
            title: 'Lokasi Laporan',
            stepIndex: 1,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(provider.gedung ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                if (provider.deskripsiLokasi.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Detail Lokasi:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  Text(provider.deskripsiLokasi, style: const TextStyle(color: Color(0xFF5A7184))),
                ]
              ],
            ),
          ),
          _buildReviewCard(
            title: 'Kategori & Judul',
            stepIndex: 2,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${provider.kategoriUtama ?? '-'} > ${provider.kategoriJenis ?? '-'}', style: const TextStyle(color: Color(0xFF5A7184))),
                const SizedBox(height: 8),
                Text(provider.judul.isNotEmpty ? provider.judul : '-', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Deskripsi Masalah',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5A7184),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: provider.deskripsi,
            onChanged: (val) => provider.setDeskripsi(val),
            maxLines: 4,
            style: const TextStyle(color: Color(0xFF1E293B)),
            decoration: InputDecoration(
              hintText: 'Contoh: AC bocor udah 2 hari...',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2A5256),
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          // Pernyataan
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pernyataan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A7184),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Laporan yang saya buat benar dan dapat dipertanggungjawabkan',
                  style: TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _agreeToTerms,
                        activeColor: const Color(0xFF2A5256),
                        onChanged: (val) {
                          setState(() {
                            _agreeToTerms = val ?? false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Ya, saya setuju', style: TextStyle(color: Color(0xFF5A7184), fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard({required String title, required int stepIndex, required Widget content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5A7184),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _currentStep = stepIndex;
                  });
                  _pageController.animateToPage(
                    stepIndex,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Text(
                  'Ganti',
                  style: TextStyle(
                    color: Color(0xFF2A5256),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }
}
