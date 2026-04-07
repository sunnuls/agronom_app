import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../export_helper.dart';
import '../providers/app_provider.dart';
import '../models/profile.dart';

const List<String> kRateUnits = ['л/га', 'мл/га', 'кг/га', 'г/га'];

class EditProfileScreen extends StatefulWidget {
  final Profile? profile;
  const EditProfileScreen({super.key, this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _tankCtrl;
  late TextEditingController _waterRateCtrl;
  late TextEditingController _notesCtrl;
  late List<_ChemicalRow> _chemicals;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _tankCtrl = TextEditingController(text: p?.tankVolumeLiters.toStringAsFixed(0) ?? '');
    _waterRateCtrl = TextEditingController(text: p?.waterRateLitersPerHa.toStringAsFixed(0) ?? '');
    _notesCtrl = TextEditingController(text: p?.notes ?? '');
    _isFavorite = p?.isFavorite ?? false;
    _chemicals = (p?.chemicals ?? []).map((c) => _ChemicalRow.fromModel(c)).toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _tankCtrl.dispose();
    _waterRateCtrl.dispose();
    _notesCtrl.dispose();
    for (final c in _chemicals) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.profile != null;
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: Text(
          isEdit ? 'Редактировать профиль' : 'Новый профиль',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.star : Icons.star_border, color: Colors.amber),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
          if (isEdit) ...[
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              tooltip: 'Поделиться профилем',
              onPressed: _exportProfileShare,
            ),
            IconButton(
              icon: const Icon(Icons.download_outlined, color: Colors.white),
              tooltip: 'Сохранить файл',
              onPressed: _exportProfileSave,
            ),
          ],
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('Основные параметры'),
            const SizedBox(height: 12),
            _field(
              controller: _nameCtrl,
              label: 'Название профиля',
              hint: 'Например: Амазонка 3200 л',
              validator: (v) => v!.trim().isEmpty ? 'Введите название' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _field(
                    controller: _tankCtrl,
                    label: 'Объём бака (л)',
                    hint: '3200',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final n = double.tryParse(v?.replaceAll(',', '.') ?? '');
                      if (n == null || n <= 0) return 'Введите > 0';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    controller: _waterRateCtrl,
                    label: 'Норма воды (л/га)',
                    hint: '300',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final n = double.tryParse(v?.replaceAll(',', '.') ?? '');
                      if (n == null || n <= 0) return 'Введите > 0';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                labelText: 'Заметки (необязательно)',
                hintText: 'Культура, поле, особые указания...',
                labelStyle: const TextStyle(color: Colors.white60),
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF162B42),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _section('Препараты'),
            const SizedBox(height: 12),
            ..._chemicals.asMap().entries.map((e) => _buildChemicalRow(e.key, e.value)),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF90CAF9),
                side: const BorderSide(color: Color(0xFF1976D2)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Добавить препарат', style: TextStyle(fontSize: 16)),
              onPressed: _addChemical,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _save,
              child: Text(
                isEdit ? 'СОХРАНИТЬ' : 'СОЗДАТЬ ПРОФИЛЬ',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportProfileShare() async {
    if (!_formKey.currentState!.validate()) return;
    final profile = _buildProfile();
    if (!mounted) return;
    try {
      await ExportHelper.shareJson(
        context: context,
        data: profile.toJson(),
        fileStem: profile.name,
        shareSubject: 'Профиль опрыскивания: ${profile.name}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _exportProfileSave() async {
    if (!_formKey.currentState!.validate()) return;
    final profile = _buildProfile();
    if (!mounted) return;
    try {
      await ExportHelper.saveJsonCopy(
        context: context,
        data: profile.toJson(),
        fileStem: profile.name,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Widget _section(String title) {
    return Text(
      title,
      style: const TextStyle(color: Color(0xFF90CAF9), fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: keyboardType != null ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))] : null,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      showCursor: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white60),
        hintStyle: const TextStyle(color: Colors.white30),
        filled: true,
        fillColor: const Color(0xFF162B42),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
        ),
        errorStyle: const TextStyle(color: Colors.orangeAccent),
      ),
      validator: validator,
    );
  }

  Widget _buildChemicalRow(int index, _ChemicalRow row) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF162B42),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Switch(
                value: row.isEnabled,
                onChanged: (v) => setState(() => row.isEnabled = v),
                activeColor: const Color(0xFF1976D2),
              ),
              Expanded(
                child: TextFormField(
                  controller: row.nameCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Название препарата',
                    hintStyle: const TextStyle(color: Colors.white30),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: const Color(0xFF0D1F33),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1976D2)),
                    ),
                  ),
                  validator: (v) => v!.trim().isEmpty ? 'Введите название' : null,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => setState(() {
                  row.dispose();
                  _chemicals.removeAt(index);
                }),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: row.rateCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: InputDecoration(
                    hintText: 'Норма',
                    hintStyle: const TextStyle(color: Colors.white30),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    filled: true,
                    fillColor: const Color(0xFF0D1F33),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1976D2)),
                    ),
                  ),
                  validator: (v) {
                    final n = double.tryParse(v?.replaceAll(',', '.') ?? '');
                    if (n == null || n < 0) return 'Введите число';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1F33),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: row.unit,
                    dropdownColor: const Color(0xFF162B42),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    items: kRateUnits
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => row.unit = v!),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addChemical() {
    setState(() {
      _chemicals.add(_ChemicalRow());
    });
  }

  Profile _buildProfile() {
    final chemicals = _chemicals.asMap().entries.map((e) => ProfileChemical(
      profileId: widget.profile?.id ?? 0,
      name: e.value.nameCtrl.text.trim(),
      rateValue: double.parse(e.value.rateCtrl.text.replaceAll(',', '.')),
      rateUnit: e.value.unit,
      sortOrder: e.key,
      isEnabled: e.value.isEnabled,
    )).toList();

    return Profile(
      id: widget.profile?.id,
      name: _nameCtrl.text.trim(),
      tankVolumeLiters: double.parse(_tankCtrl.text.replaceAll(',', '.')),
      waterRateLitersPerHa: double.parse(_waterRateCtrl.text.replaceAll(',', '.')),
      isFavorite: _isFavorite,
      notes: _notesCtrl.text.trim(),
      chemicals: chemicals,
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<AppProvider>();
    final profile = _buildProfile();

    if (widget.profile == null) {
      await provider.createProfile(profile);
    } else {
      await provider.updateProfile(profile);
    }

    if (mounted) Navigator.pop(context);
  }
}

class _ChemicalRow {
  final TextEditingController nameCtrl;
  final TextEditingController rateCtrl;
  String unit;
  bool isEnabled;

  _ChemicalRow({
    String name = '',
    String rate = '',
    this.unit = 'л/га',
    this.isEnabled = true,
  })  : nameCtrl = TextEditingController(text: name),
        rateCtrl = TextEditingController(text: rate);

  factory _ChemicalRow.fromModel(ProfileChemical c) {
    return _ChemicalRow(
      name: c.name,
      rate: c.rateValue.toString(),
      unit: c.rateUnit,
      isEnabled: c.isEnabled,
    );
  }

  void dispose() {
    nameCtrl.dispose();
    rateCtrl.dispose();
  }
}
