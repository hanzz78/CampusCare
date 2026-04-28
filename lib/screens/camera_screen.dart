import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'camera_confirmation_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isReady = false;
  FlashMode _flashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );
      
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isReady = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _toggleFlash() {
    if (_controller == null) return;
    setState(() {
      _flashMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
      _controller!.setFlashMode(_flashMode);
    });
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final XFile image = await _controller!.takePicture();
      // Reset flash mode just in case
      if (_flashMode == FlashMode.torch) {
         _toggleFlash(); 
      }
      _navigateToConfirmation(image.path);
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _navigateToConfirmation(image.path);
    }
  }

  void _navigateToConfirmation(String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraConfirmationScreen(imagePath: imagePath),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              color: Colors.black,
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(text: 'Campus', style: TextStyle(color: Color(0xFFF39C12), fontSize: 24, fontWeight: FontWeight.bold)),
                            TextSpan(text: 'Care', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 20,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Camera Preview
            Expanded(
              child: _isReady && _controller != null
                  ? SizedBox(
                      width: double.infinity,
                      child: CameraPreview(_controller!),
                    )
                  : const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
            
            // Bottom Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              color: Colors.black,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Gallery Button
                  _buildBottomButton(
                    icon: Icons.image_outlined,
                    size: 50,
                    iconSize: 24,
                    onTap: _pickFromGallery,
                  ),
                  
                  // Capture Button
                  _buildBottomButton(
                    icon: Icons.camera_alt,
                    size: 80,
                    iconSize: 40,
                    borderWidth: 4,
                    onTap: _takePicture,
                  ),
                  
                  // Flash Button
                  _buildBottomButton(
                    icon: _flashMode == FlashMode.torch ? Icons.flash_on : Icons.flash_off,
                    size: 50,
                    iconSize: 24,
                    onTap: _toggleFlash,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required double size,
    required double iconSize,
    required VoidCallback onTap,
    double borderWidth = 2,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: const Color(0xFF3B696D), // Teal gelap
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade400, width: borderWidth),
        ),
        child: Center(
          child: Icon(icon, color: Colors.white, size: iconSize),
        ),
      ),
    );
  }
}
