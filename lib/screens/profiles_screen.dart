import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../export_helper.dart';
import '../import_bridge.dart';
import '../models/profile.dart';
import '../providers/app_provider.dart';
import 'calc_screen.dart';
import 'edit_profile_screen.dart';

class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({super.key});

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadProfiles();
      ImportBridge.tryConsumePendingImport(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: const Text(
          'Профили опрыскивания',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Colors.white, size: 26),
            tooltip: 'Импорт профиля',
            onPressed: () => _importProfile(context),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 30),
            onPressed: () => _openEditProfile(context, null),
          ),
        ],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2)))
          : provider.profiles.isEmpty
              ? _buildEmpty(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: provider.profiles.length,
                  itemBuilder: (ctx, i) => _buildProfileCard(ctx, provider.profiles[i]),
                ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.agriculture, size: 80, color: Color(0xFF1976D2)),
          const SizedBox(height: 16),
          const Text(
            'Нет профилей',
            style: TextStyle(color: Colors.white70, fontSize: 22),
          ),
          const SizedBox(height: 8),
          const Text(
            'Создайте профиль опрыскивания',
            style: TextStyle(color: Colors.white38, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Создать профиль', style: TextStyle(color: Colors.white, fontSize: 18)),
            onPressed: () => _openEditProfile(context, null),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, Profile profile) {
    final enabledChemicals = profile.chemicals.where((c) => c.isEnabled).toList();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF162B42),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openCalc(context, profile),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (profile.isFavorite)
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                  if (profile.isFavorite) const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      profile.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    color: const Color(0xFF162B42),
                    icon: const Icon(Icons.more_vert, color: Colors.white70),
                    onSelected: (val) => _onMenuAction(context, val, profile),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Редактировать', style: TextStyle(color: Colors.white))),
                      const PopupMenuItem(value: 'share', child: Text('Поделиться профилем', style: TextStyle(color: Colors.white))),
                      const PopupMenuItem(value: 'save', child: Text('Сохранить файл', style: TextStyle(color: Colors.white))),
                      const PopupMenuItem(value: 'duplicate', child: Text('Дублировать', style: TextStyle(color: Colors.white))),
                      const PopupMenuItem(value: 'delete', child: Text('Удалить', style: TextStyle(color: Colors.redAccent))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _infoChip(Icons.water_drop, '${profile.tankVolumeLiters.toStringAsFixed(0)} л'),
                  const SizedBox(width: 8),
                  _infoChip(Icons.grass, '${profile.waterRateLitersPerHa.toStringAsFixed(0)} л/га'),
                  const SizedBox(width: 8),
                  _infoChip(Icons.science, '${enabledChemicals.length} препар.'),
                ],
              ),
              if (enabledChemicals.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: enabledChemicals.map((c) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1F33),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${c.name} ${c.rateValue} ${c.rateUnit}',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  )).toList(),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _openCalc(context, profile),
                  child: const Text(
                    'РАССЧИТАТЬ',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F33),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF90CAF9)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _shareProfile(BuildContext context, Profile profile) async {
    try {
      await ExportHelper.shareJson(
        context: context,
        data: profile.toJson(),
        fileStem: profile.name,
        shareSubject: 'Профиль опрыскивания: ${profile.name}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _saveProfileFile(BuildContext context, Profile profile) async {
    try {
      await ExportHelper.saveJsonCopy(
        context: context,
        data: profile.toJson(),
        fileStem: profile.name,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _importProfile(BuildContext context) async {
    try {
      final text = await ImportBridge.pickFileUtf8();
      if (text == null) return;
      if (!context.mounted) return;
      await ImportBridge.importProfileFromJsonString(context, text);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Файл: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _openCalc(BuildContext context, Profile profile) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => CalcScreen(profile: profile)));
  }

  void _openEditProfile(BuildContext context, Profile? profile) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profile)),
    );
  }

  void _onMenuAction(BuildContext context, String action, Profile profile) async {
    final provider = context.read<AppProvider>();
    switch (action) {
      case 'edit':
        _openEditProfile(context, profile);
        break;
      case 'share':
        await _shareProfile(context, profile);
        break;
      case 'save':
        await _saveProfileFile(context, profile);
        break;
      case 'duplicate':
        await provider.duplicateProfile(profile);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Профиль скопирован'), backgroundColor: Color(0xFF1976D2)),
          );
        }
        break;
      case 'delete':
        _confirmDelete(context, profile);
        break;
    }
  }

  void _confirmDelete(BuildContext context, Profile profile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF162B42),
        title: const Text('Удалить профиль?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Профиль "${profile.name}" будет удалён безвозвратно.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AppProvider>().deleteProfile(profile.id!);
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
