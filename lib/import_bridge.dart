import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'models/profile.dart';
import 'providers/app_provider.dart';

/// Импорт из нативного слоя: Android (intents) и iOS (открытие файла из «Файлы» и т.п.).
class ImportBridge {
  static const _channel = MethodChannel('com.agronom.agronom_app/import');

  /// Сохранение файла через системный диалог «Сохранить как» (Android [ACTION_CREATE_DOCUMENT]).
  /// Возвращает `true`, если файл успешно записан, `false` при отмене или ошибке.
  static Future<bool> saveFileAs({
    required String content,
    required String fileName,
  }) async {
    if (!Platform.isAndroid) return false;
    try {
      final result = await _channel.invokeMethod<dynamic>(
        'saveFile',
        {'content': content, 'fileName': fileName},
      );
      return result == true;
    } catch (_) {
      return false;
    }
  }

  /// Выбор файла через системный диалог (Android [ACTION_OPEN_DOCUMENT], iOS UIDocumentPicker). UTF-8 текст или `null` при отмене.
  static Future<String?> pickFileUtf8() async {
    if (!Platform.isAndroid && !Platform.isIOS) return null;
    try {
      final raw = await _channel.invokeMethod<dynamic>('pickFile');
      if (raw == null) return null;
      final s = raw is String ? raw : raw.toString();
      final t = s.trim();
      return t.isEmpty ? null : t;
    } catch (_) {
      return null;
    }
  }

  static Future<void> tryConsumePendingImport(BuildContext context) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    try {
      final raw = await _channel.invokeMethod('takePendingImport');
      final json = raw is String ? raw : raw?.toString();
      if (json == null || json.isEmpty) return;
      if (!context.mounted) return;
      await importProfileFromJsonString(context, json);
    } catch (_) {
      // канал недоступен на других платформах
    }
  }

  /// Импорт из JSON-строки (буфер, файл, intent). Возвращает `true`, если профиль создан.
  static Future<bool> importProfileFromJsonString(BuildContext context, String raw) async {
    try {
      final map = jsonDecode(raw.trim()) as Map<String, dynamic>;
      if (map['type'] != 'agronom_profile') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Неверный формат файла'), backgroundColor: Colors.redAccent),
          );
        }
        return false;
      }
      final profile = Profile.fromJson(map);
      await context.read<AppProvider>().createProfile(profile);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Профиль «${profile.name}» импортирован'),
            backgroundColor: const Color(0xFF1976D2),
          ),
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка импорта: $e'), backgroundColor: Colors.redAccent),
        );
      }
      return false;
    }
  }
}
