import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:diet_log/logic/providers/auth_provider.dart';
import 'package:diet_log/logic/providers/inference_provider.dart';
import 'package:diet_log/presentation/theme/app_theme.dart';

/// Camera / food scanner overlay screen with live camera preview.
///
/// ## Clean Architecture Role (Presentation Layer):
/// This screen consumes two Riverpod providers:
/// - [currentAuthUserIdProvider] for the authenticated user's ID
/// - [inferenceNotifierProvider] for the Gemini AI inference state machine
///
/// ## Gemini Vision Pipeline:
/// User captures photo → CameraController.takePicture() → File created →
/// InferenceNotifier.analyzeAndLog() → GeminiService.analyzeFood() →
/// InferenceResult parsed → NutritionLog persisted → UI shows success.
///
/// Uses native [CircularProgressIndicator] for loading state.
/// Uses [AnimatedScale] + [Icons.check_circle] for success — NO Lottie.
class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  final ImagePicker _picker = ImagePicker();
  bool _isCameraInitialized = false;
  bool _isCameraError = false;
  String _cameraErrorMsg = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Reset inference state when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inferenceNotifierProvider.notifier).reset();
    });
    _initCamera();
  }

  /// Initialize the device camera (back-facing) for live preview.
  /// Falls back to a static dark frame if no camera is available.
  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _isCameraError = true;
          _cameraErrorMsg = 'No cameras found on this device';
        });
        return;
      }

      // Prefer the back camera for food scanning
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false, // No audio needed for food scanning
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraError = true;
          _cameraErrorMsg = 'Camera initialization failed: $e';
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Dispose camera when app goes to background, reinit on resume
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
      _cameraController = null;
      if (mounted) setState(() => _isCameraInitialized = false);
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // CRITICAL: Dispose camera controller to prevent memory leaks
    _cameraController?.dispose();
    super.dispose();
  }

  /// Capture a photo from the live camera and send to Gemini for analysis.
  ///
  /// Pipeline: CameraController.takePicture() → XFile → File →
  /// InferenceNotifier.analyzeAndLog() (Gemini Vision API)
  Future<void> _captureAndAnalyze() async {
    // Verify user is authenticated before calling the AI pipeline
    final userId = ref.read(currentAuthUserIdProvider);
    if (userId == null) {
      _showSnack('Please sign in first', isError: true);
      return;
    }

    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final XFile photo = await _cameraController!.takePicture();
        ref.read(inferenceNotifierProvider.notifier).analyzeAndLog(
              imageFile: File(photo.path),
              userId: userId,
            );
      } catch (e) {
        _showSnack('Failed to capture photo: $e', isError: true);
      }
    } else {
      // Camera not available — fall back to gallery picker
      _pickFromGallery();
    }
  }

  /// Fallback: pick image from device gallery for analysis.
  Future<void> _pickFromGallery() async {
    final userId = ref.read(currentAuthUserIdProvider);
    if (userId == null) {
      _showSnack('Please sign in first', isError: true);
      return;
    }

    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );

    if (image == null) return;

    ref.read(inferenceNotifierProvider.notifier).analyzeAndLog(
          imageFile: File(image.path),
          userId: userId,
        );
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : AppTheme.primaryDark,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inferenceState = ref.watch(inferenceNotifierProvider);

    // Listen for state transitions to show success/error feedback
    ref.listen<InferenceState>(inferenceNotifierProvider, (prev, next) {
      if (next is InferenceSuccess) {
        _showSnack('Logged: ${next.log.foodName} (${next.log.calories} kcal)');
        final navigator = Navigator.of(context);
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (mounted) navigator.pop();
        });
      } else if (next is InferenceError) {
        _showSnack(next.message, isError: true);
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Live camera preview or fallback ──────────────────────────
          _buildCameraBackground(),

          // ── Top bar ─────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'DietLog',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    // Gallery pick fallback button
                    IconButton(
                      onPressed: inferenceState is InferenceLoading
                          ? null
                          : _pickFromGallery,
                      icon: const Icon(Icons.photo_library_outlined,
                          color: Colors.white),
                      tooltip: 'Pick from gallery',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Center state overlay ────────────────────────────────────
          Center(child: _buildCenterOverlay(inferenceState)),

          // ── Detecting chip (above viewfinder during loading) ────────
          if (inferenceState is InferenceLoading)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.32,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.restaurant,
                          color: AppTheme.primary, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Analyzing with Gemini AI...',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Bottom sheet ─────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    inferenceState is InferenceSuccess
                        ? 'Meal Logged!'
                        : 'Point at your meal',
                    style: AppTheme.headingSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    inferenceState is InferenceSuccess
                        ? 'Your nutrition has been recorded.'
                        : 'Hold steady to identify nutrients automatically.',
                    style: AppTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),

                  // Progress bar — indeterminate while Gemini is analyzing
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: inferenceState is InferenceLoading
                          ? null
                          : inferenceState is InferenceSuccess
                              ? 1.0
                              : 0.0,
                      minHeight: 6,
                      backgroundColor: AppTheme.divider,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primary),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            side:
                                const BorderSide(color: AppTheme.divider),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel',
                              style:
                                  TextStyle(color: AppTheme.textPrimary)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: inferenceState is InferenceLoading
                              ? null
                              : _captureAndAnalyze,
                          icon:
                              const Icon(Icons.camera_alt_rounded, size: 18),
                          label: Text(
                            inferenceState is InferenceLoading
                                ? 'Analyzing...'
                                : 'Snap & Log',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the camera preview or a dark fallback if camera is unavailable.
  Widget _buildCameraBackground() {
    if (_isCameraInitialized && _cameraController != null) {
      // Live camera preview — the core of the food scanning UX
      return CameraPreview(_cameraController!);
    }

    if (_isCameraError) {
      return Container(
        color: const Color(0xFF1A1A1A),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.camera_alt, size: 64,
                  color: Colors.white.withValues(alpha: 0.15)),
              const SizedBox(height: 12),
              Text(
                _cameraErrorMsg,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Use the gallery icon to pick a photo instead',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    // Camera is initializing — show loading
    return Container(
      color: const Color(0xFF1A1A1A),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
        ),
      ),
    );
  }

  /// Build the center overlay based on the current inference state.
  Widget _buildCenterOverlay(InferenceState state) {
    if (state is InferenceLoading) {
      // Gemini API is processing the food image
      return const SizedBox(
        width: 80,
        height: 80,
        child: CircularProgressIndicator(
          strokeWidth: 4,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
        ),
      );
    }

    if (state is InferenceSuccess) {
      // Inference succeeded — show animated checkmark
      return AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
        child: const Icon(
          Icons.check_circle,
          color: AppTheme.primary,
          size: 80,
        ),
      );
    }

    // Idle or error — show viewfinder corner brackets
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        children: [
          Positioned(
              top: 0, left: 0,
              child: _CornerBracket(corner: _Corner.topLeft)),
          Positioned(
              top: 0, right: 0,
              child: _CornerBracket(corner: _Corner.topRight)),
          Positioned(
              bottom: 0, left: 0,
              child: _CornerBracket(corner: _Corner.bottomLeft)),
          Positioned(
              bottom: 0, right: 0,
              child: _CornerBracket(corner: _Corner.bottomRight)),
        ],
      ),
    );
  }
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

class _CornerBracket extends StatelessWidget {
  final _Corner corner;
  const _CornerBracket({required this.corner});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border(
          top: corner == _Corner.topLeft || corner == _Corner.topRight
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
          bottom:
              corner == _Corner.bottomLeft || corner == _Corner.bottomRight
                  ? const BorderSide(color: Colors.white, width: 3)
                  : BorderSide.none,
          left: corner == _Corner.topLeft || corner == _Corner.bottomLeft
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
          right:
              corner == _Corner.topRight || corner == _Corner.bottomRight
                  ? const BorderSide(color: Colors.white, width: 3)
                  : BorderSide.none,
        ),
      ),
    );
  }
}
