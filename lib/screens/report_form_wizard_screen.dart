import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/report_form_provider.dart';
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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    final provider = context.read<ReportFormProvider>();
    bool canProceed = false;

    if (_currentStep == 0) canProceed = provider.isStep1Valid;
    else if (_currentStep == 1) canProceed = provider.isStep2Valid;
    else if (_currentStep == 2) canProceed = provider.isStep3Valid;

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
        const SnackBar(content: Text('Harap lengkapi data pada tahap ini terlebih dahulu!')),
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
        backgroundColor: const Color(0xFF3B696D), // Teal gelap untuk latar atas
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Color(0xFF3B696D)),
                        onPressed: _prevStep,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Laporan Baru',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              
              // Step Indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_totalSteps, (index) {
                    final isActive = index <= _currentStep;
                    return Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isActive ? Colors.white : Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: isActive ? const Color(0xFF3B696D) : Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          if (index < _totalSteps - 1)
                            Expanded(
                              child: Container(
                                height: 2,
                                color: isActive ? Colors.white : Colors.white24,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 16),

              // Main Content Area
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    // PageView for content
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const NeverScrollableScrollPhysics(), // Disable swipe
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
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentStep == _totalSteps - 1) {
                              // Submit Report
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan Berhasil Diunggah!')));
                              context.read<ReportFormProvider>().resetForm();
                              Navigator.pop(context);
                            } else {
                              _nextStep();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentStep == _totalSteps - 1 ? const Color(0xFFA03232) : const Color(0xFF3B696D), // Merah untuk akhir
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Text(
                            _currentStep == _totalSteps - 1 ? 'Unggah Pelaporan' : 'Selanjutnya',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
          const Text('Bukti Kerusakan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5A7184))),
          const SizedBox(height: 16),
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final picker = ImagePicker();
                final image = await picker.pickImage(source: ImageSource.gallery);
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
                    color: hasImage ? const Color(0xFF3B696D) : Colors.grey.shade300,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(File(provider.imagePath!), fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text('Ketuk untuk mengambil foto', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Buka Kamera Device
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CameraScreen()));
              },
              icon: const Icon(Icons.camera),
              label: const Text('Buka Kamera'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3B696D),
                side: const BorderSide(color: Color(0xFF3B696D)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- STEP 2: CATEGORY & LOCATION ---
  Widget _buildStep2CategoryLocation(BuildContext context) {
    final provider = context.watch<ReportFormProvider>();
    final categories = [
      {'name': 'Sarana Prasarana', 'icon': Icons.business},
      {'name': 'Kebersihan', 'icon': Icons.cleaning_services},
    ];
    final buildings = ['Gedung A', 'Gedung B', 'Gedung C', 'Gedung D', 'Gedung E', 'Masjid', 'Perpustakaan'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kategori', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5A7184))),
          const SizedBox(height: 16),
          Row(
            children: categories.map((cat) {
              final isActive = provider.kategori == cat['name'];
              return Expanded(
                child: GestureDetector(
                  onTap: () => provider.setKategori(cat['name'] as String),
                  child: Container(
                    margin: EdgeInsets.only(right: cat == categories.first ? 12 : 0, left: cat == categories.last ? 12 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.grey.shade200 : Colors.white,
                      border: Border.all(color: isActive ? const Color(0xFF3B696D) : Colors.grey.shade300, width: isActive ? 2 : 1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(cat['icon'] as IconData, size: 32, color: isActive ? const Color(0xFF3B696D) : Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          cat['name'] as String,
                          style: TextStyle(
                            color: isActive ? const Color(0xFF3B696D) : Colors.grey.shade500,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          const Text('Gedung / Lokasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5A7184))),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: buildings.map((gedung) {
              final isActive = provider.gedung == gedung;
              return GestureDetector(
                onTap: () => provider.setGedung(gedung),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF3B696D) : Colors.white,
                    border: Border.all(color: isActive ? const Color(0xFF3B696D) : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    gedung,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey.shade600,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- STEP 3: DETAILS ---
  Widget _buildStep3Details(BuildContext context) {
    final provider = context.watch<ReportFormProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Judul Laporan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5A7184))),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: provider.judul,
            onChanged: (val) => provider.setJudul(val),
            decoration: InputDecoration(
              hintText: 'Contoh: AC Bocor di Kelas',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B696D), width: 2)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text('Deskripsi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF5A7184))),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: provider.deskripsi,
            onChanged: (val) => provider.setDeskripsi(val),
            maxLines: 6,
            decoration: InputDecoration(
              hintText: 'Deskripsikan permasalahan yang terjadi...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B696D), width: 2)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
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
          const Text('Ringkasan Laporan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3B696D))),
          const SizedBox(height: 24),
          if (provider.imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(File(provider.imagePath!), height: 200, width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 24),
          _buildReviewRow('Kategori', provider.kategori ?? '-'),
          const Divider(),
          _buildReviewRow('Lokasi', provider.gedung ?? '-'),
          const Divider(),
          _buildReviewRow('Judul', provider.judul.isNotEmpty ? provider.judul : '-'),
          const Divider(),
          _buildReviewRow('Deskripsi', provider.deskripsi.isNotEmpty ? provider.deskripsi : '-'),
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
        ],
      ),
    );
  }
}
