import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:diet_log/logic/providers/auth_provider.dart';
import 'package:diet_log/logic/providers/inference_provider.dart';
import 'package:diet_log/presentation/theme/app_theme.dart';

/// Camera / food scanner overlay screen.
///
/// Simulates a camera viewfinder with corner brackets. Integrates with
/// [InferenceNotifier] to drive the Gemini Vision analysis pipeline.
/// Uses native [CircularProgressIndicator] for loading and
/// [AnimatedScale] + [Icons.check_circle] for success — no Lottie.
class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Reset inference state on screen entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inferenceNotifierProvider.notifier).reset();
    });
  }

  Future<void> _pickAndAnalyze() async {
    final user = ref.read(currentAuthUserProvider);
    if (user == null) {
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
          userId: user.id,
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

    // Listen for state changes to show feedback
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
          // ── Dark camera background ─────────────────────────────────────
          Container(
            color: const Color(0xFF1A1A1A),
            child: Center(
              child: Icon(
                Icons.camera_alt,
                size: 80,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),

          // ── Top bar ────────────────────────────────────────────────────
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
                      icon: const Icon(Icons.bolt, color: Colors.white),
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
                    IconButton(
                      onPressed: () {},
                      icon:
                          const Icon(Icons.settings, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Center state overlay ───────────────────────────────────────
          Center(child: _buildCenterOverlay(inferenceState)),

          // ── Detecting chip (above viewfinder) ──────────────────────────
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
                        'Detecting...',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Bottom sheet ───────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: inferenceState is InferenceLoading ? null : 
                             inferenceState is InferenceSuccess ? 1.0 : 0.0,
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
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppTheme.divider),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel',
                              style: TextStyle(color: AppTheme.textPrimary)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed:
                              inferenceState is InferenceLoading
                                  ? null
                                  : _pickAndAnalyze,
                          icon: const Icon(Icons.restaurant, size: 18),
                          label: Text(
                            inferenceState is InferenceLoading
                                ? 'Analyzing...'
                                : 'Snap & Log',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
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

  /// Build the center overlay based on the current inference state.
  Widget _buildCenterOverlay(InferenceState state) {
    if (state is InferenceLoading) {
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

    // Idle or error — show viewfinder brackets
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        children: [
          // Top-left bracket
          Positioned(
            top: 0, left: 0,
            child: _CornerBracket(corner: _Corner.topLeft),
          ),
          // Top-right bracket
          Positioned(
            top: 0, right: 0,
            child: _CornerBracket(corner: _Corner.topRight),
          ),
          // Bottom-left bracket
          Positioned(
            bottom: 0, left: 0,
            child: _CornerBracket(corner: _Corner.bottomLeft),
          ),
          // Bottom-right bracket
          Positioned(
            bottom: 0, right: 0,
            child: _CornerBracket(corner: _Corner.bottomRight),
          ),
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
          bottom: corner == _Corner.bottomLeft || corner == _Corner.bottomRight
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
          left: corner == _Corner.topLeft || corner == _Corner.bottomLeft
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
          right: corner == _Corner.topRight || corner == _Corner.bottomRight
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
        ),
      ),
    );
  }
}
