import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../export_helper.dart';
import '../providers/app_provider.dart';
import '../models/calculation_log.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final logs = context.watch<AppProvider>().logs;
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text('Журнал расчётов', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: logs.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80, color: Color(0xFF1976D2)),
                  SizedBox(height: 16),
                  Text('Журнал пуст', style: TextStyle(color: Colors.white70, fontSize: 22)),
                  SizedBox(height: 8),
                  Text('Сохраните расчёт на экране расчёта', style: TextStyle(color: Colors.white38, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: logs.length,
              itemBuilder: (ctx, i) => _buildLogCard(ctx, logs[i]),
            ),
    );
  }

  Widget _buildLogCard(BuildContext context, CalculationLog log) {
    final fmt = DateFormat('dd.MM.yyyy HH:mm');
    final isRefill = log.remainderLiters > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF162B42),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isRefill ? Icons.add_circle : Icons.water_drop,
                  color: isRefill ? const Color(0xFF42A5F5) : const Color(0xFF1976D2),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    log.profileNameSnapshot,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  fmt.format(log.createdAt.toLocal()),
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.share, color: Color(0xFF90CAF9), size: 22),
                  tooltip: 'Поделиться расчётом',
                  onPressed: () => _shareCalculation(context, log),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
                IconButton(
                  icon: const Icon(Icons.download_outlined, color: Color(0xFF90CAF9), size: 22),
                  tooltip: 'Сохранить файл',
                  onPressed: () => _saveCalculationFile(context, log),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: () => _confirmDelete(context, log),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _chip('Бак', '${log.tankVolumeSnapshot.toStringAsFixed(0)} л', Colors.white70),
                if (isRefill)
                  _chip('Остаток', '${log.remainderLiters.toStringAsFixed(0)} л', const Color(0xFF90CAF9)),
                _chip('Долито воды', '${log.refillVolumeLiters.toStringAsFixed(1)} л', const Color(0xFF90CAF9)),
                _chip('Площадь', '${log.coveredAreaHa.toStringAsFixed(2)} га', Colors.white70),
              ],
            ),
            if (log.chemicals.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 10),
              ...log.chemicals.map((c) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    const Icon(Icons.science_outlined, color: Colors.white38, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(c.nameSnapshot, style: const TextStyle(color: Colors.white70, fontSize: 15)),
                    ),
                    Text(
                      _formatAmount(c),
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  String _formatAmount(CalculationLogChemical c) {
    final amount = c.amountToAdd;
    final unit = c.rateUnitSnapshot;
    if (unit == 'мл/га') {
      if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(2)} л';
      return '${amount.toStringAsFixed(0)} мл';
    }
    if (unit == 'г/га') {
      if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(2)} кг';
      return '${amount.toStringAsFixed(0)} г';
    }
    if (unit == 'кг/га') return '${amount.toStringAsFixed(2)} кг';
    return '${amount.toStringAsFixed(2)} л';
  }

  Widget _chip(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F33),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _shareCalculation(BuildContext context, CalculationLog log) async {
    try {
      final stamp = DateFormat('yyyyMMdd_HHmm').format(log.createdAt.toLocal());
      await ExportHelper.shareJson(
        context: context,
        data: log.toJson(),
        fileStem: 'raschet_${log.profileNameSnapshot}_$stamp',
        shareSubject: 'Расчёт опрыскивания: ${log.profileNameSnapshot}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _saveCalculationFile(BuildContext context, CalculationLog log) async {
    try {
      final stamp = DateFormat('yyyyMMdd_HHmm').format(log.createdAt.toLocal());
      await ExportHelper.saveJsonCopy(
        context: context,
        data: log.toJson(),
        fileStem: 'raschet_${log.profileNameSnapshot}_$stamp',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context, CalculationLog log) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF162B42),
        title: const Text('Удалить запись?', style: TextStyle(color: Colors.white)),
        content: const Text('Запись будет удалена из журнала.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AppProvider>().deleteLog(log.id!);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
