import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// A bottom sheet widget for selecting how to input data:
/// Manual, Voice, Photo OCR, or BLE sync.
class InputMethodSelector extends StatelessWidget {
  final void Function(InputMethod method) onSelected;

  const InputMethodSelector({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('选择录入方式', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOption(context, Icons.keyboard, '手动', InputMethod.manual),
                _buildOption(context, Icons.mic, '语音', InputMethod.voice),
                _buildOption(context, Icons.camera_alt, '拍照OCR', InputMethod.ocr),
                _buildOption(context, Icons.bluetooth, '蓝牙', InputMethod.ble),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, IconData icon, String label, InputMethod method) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onSelected(method);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Icon(icon, size: 36, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

enum InputMethod { manual, voice, ocr, ble }

/// OCR utility: pick an image and simulate text extraction.
/// In production, integrate ML Kit / Google Vision.
class OcrHelper {
  static final _picker = ImagePicker();

  /// Pick an image from gallery and return extracted text (simulated).
  static Future<String?> pickAndRecognize() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (xfile == null) return null;

    // In real app: pass xfile.path to ML Kit OCR
    // For now, return a placeholder message
    return '[OCR] 选中图片: ${xfile.name}。实际集成OCR后将自动提取数字。';
  }

  /// Pick from camera and recognize.
  static Future<String?> captureAndRecognize() async {
    final xfile = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1024);
    if (xfile == null) return null;

    return '[OCR-拍照] 已拍照: ${xfile.name}。实际集成OCR后将自动提取数字。';
  }
}

/// Voice input utility.
/// In production, integrate speech_to_text package.
class VoiceHelper {
  /// Start listening and return transcribed text.
  /// Returns null if cancelled or failed.
  static Future<String?> startListening() async {
    // Placeholder: in real app, use SpeechToText from speech_to_text package
    // to start listening, wait for result, and return text.
    await Future.delayed(const Duration(seconds: 2));
    return null; // Simulate: return transcribed text
  }
}
