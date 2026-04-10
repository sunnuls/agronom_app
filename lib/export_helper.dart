import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Общий экспорт JSON: шаринг и сохранение копии на устройстве.
class ExportHelper {
  ExportHelper._();

  static bool _okFileChar(int c) {
    if (c >= 0x30 && c <= 0x39) return true;
    if (c >= 0x41 && c <= 0x5A) return true;
    if (c >= 0x61 && c <= 0x7A) return true;
    if (c == 0x20 || c == 0x2D || c == 0x5F) return true;
    if (c >= 0x0400 && c <= 0x04FF) return true;
    return false;
  }

  static String sanitizeFileStem(String raw, {String fallback = 'export'}) {
    final buf = StringBuffer();
    for (final c in raw.runes) {
      if (_okFileChar(c)) buf.writeCharCode(c);
    }
    var s = buf.toString().trim().replaceAll(RegExp(r'\s+'), '_');
    if (s.isEmpty) s = fallback;
    if (s.length > 64) s = s.substring(0, 64);
    return s;
  }

  /// На iOS лист «Поделиться» должен быть привязан к ненулевому [Rect] в координатах экрана.
  static Rect _sharePositionOrigin(BuildContext context) {
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      final size = box.size;
      if (size.width >= 1 && size.height >= 1) {
        return box.localToGlobal(Offset.zero) & size;
      }
    }
    final media = MediaQuery.maybeOf(context);
    final sz = media?.size ?? const Size(390, 844);
    final top = (media?.viewPadding.top ?? media?.padding.top ?? 0) + 36;
    return Rect.fromCenter(center: Offset(sz.width / 2, top), width: 48, height: 48);
  }

  static Future<void> shareJson({
    required BuildContext context,
    required Map<String, dynamic> data,
    required String fileStem,
    required String shareSubject,
  }) async {
    final sharePositionOrigin = _sharePositionOrigin(context);
    final json = const JsonEncoder.withIndent('  ').convert(data);
    final name = '${sanitizeFileStem(fileStem)}.agronom';
    final dir = await getTemporaryDirectory();
    final file = File(join(dir.path, name));
    await file.writeAsString(json, encoding: utf8);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      text: shareSubject,
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  /// Открывает системный диалог «Сохранить как» — пользователь сам выбирает папку.
  /// Работает через [ACTION_CREATE_DOCUMENT] на Android.
  static Future<void> saveJsonCopy({
    required BuildContext context,
    required Map<String, dynamic> data,
    required String fileStem,
  }) async {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    final name = '${sanitizeFileStem(fileStem)}.agronom';

    if (Platform.isAndroid) {
      // MethodChannel без const — const локальные переменные дестабилизируют ConstantEvaluator.
      final ch = MethodChannel('com.agronom.agronom_app/import');
      bool saved = false;
      try {
        final r = await ch.invokeMethod<dynamic>('saveFile', {'content': jsonStr, 'fileName': name});
        saved = r == true;
      } catch (_) {}
      if (!context.mounted) return;
      if (saved) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Файл сохранён'),
            backgroundColor: Color(0xFF1976D2),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        // Пользователь отменил диалог — ничего не показываем
      }
      return;
    }

    // iOS / desktop: песочница приложения; удобнее отдать копию через «Поделиться» → «Сохранить в Файлы».
    try {
      final base = await getApplicationDocumentsDirectory();
      final exportDir = Directory(join(base.path, 'agronom_exports'));
      if (!await exportDir.exists()) await exportDir.create(recursive: true);
      final file = File(join(exportDir.path, name));
      await file.writeAsString(jsonStr, encoding: utf8);
      if (!context.mounted) return;
      final hint = Platform.isIOS
          ? 'Сохранено в приложении. Чтобы положить в «Файлы», используйте кнопку «Поделиться».'
          : 'Файл сохранён:\n${file.path}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hint, style: const TextStyle(fontSize: 13)),
          backgroundColor: const Color(0xFF1976D2),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка сохранения: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }
}
