import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/profile.dart';
import '../models/calculation_log.dart';
import '../providers/app_provider.dart';

class CalcScreen extends StatefulWidget {
  final Profile profile;
  const CalcScreen({super.key, required this.profile});

  @override
  State<CalcScreen> createState() => _CalcScreenState();
}

class _CalcScreenState extends State<CalcScreen> {
  final _remainderCtrl = TextEditingController();
  final _remainderFocus = FocusNode();
  double _remainder = 0.0;
  bool _hasRemainder = false;
  String? _errorText;

  late Profile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
    _remainderCtrl.addListener(_onRemainderChanged);
  }

  @override
  void dispose() {
    _remainderCtrl.removeListener(_onRemainderChanged);
    _remainderCtrl.dispose();
    _remainderFocus.dispose();
    super.dispose();
  }

  void _onRemainderChanged() {
    final text = _remainderCtrl.text.replaceAll(',', '.');
    if (text.isEmpty) {
      setState(() {
        _remainder = 0.0;
        _hasRemainder = false;
        _errorText = null;
      });
      return;
    }
    final val = double.tryParse(text);
    if (val == null) {
      setState(() => _errorText = 'Введите число');
      return;
    }
    if (val < 0) {
      setState(() => _errorText = 'Не может быть < 0');
      return;
    }
    if (val >= _profile.tankVolumeLiters) {
      setState(() => _errorText = 'Не может быть \u2265 объёма бака');
      return;
    }
    setState(() {
      _remainder = val;
      _hasRemainder = val > 0;
      _errorText = null;
    });
  }

  double get _refillWater => _profile.tankVolumeLiters - _remainder;
  double get _coveredAreaHa => _refillWater / _profile.waterRateLitersPerHa;

  double _chemAmount(ProfileChemical chem) => _coveredAreaHa * chem.rateValue;

  String _formatL(double val) {
    if (val >= 1) {
      return '${val.toStringAsFixed(1)} л';
    }
    return '${(val * 1000).toStringAsFixed(0)} мл';
  }

  String _formatAmount(ProfileChemical chem) {
    final amount = _chemAmount(chem);
    final unit = chem.rateUnit;
    if (unit == 'мл/га') {
      if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(2)} л';
      return '${amount.toStringAsFixed(0)} мл';
    }
    if (unit == 'г/га') {
      if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(2)} кг';
      return '${amount.toStringAsFixed(0)} г';
    }
    if (unit == 'кг/га') {
      return '${amount.toStringAsFixed(2)} кг';
    }
    return '${amount.toStringAsFixed(2)} л';
  }

  List<ProfileChemical> get _activeChemicals =>
      _profile.chemicals.where((c) => c.isEnabled).toList();

  Future<void> _saveToJournal() async {
    final provider = context.read<AppProvider>();
    final logChemicals = _activeChemicals.map((c) => CalculationLogChemical(
      calculationLogId: 0,
      nameSnapshot: c.name,
      rateValueSnapshot: c.rateValue,
      rateUnitSnapshot: c.rateUnit,
      amountToAdd: _chemAmount(c),
    )).toList();

    final log = CalculationLog(
      profileId: _profile.id!,
      profileNameSnapshot: _profile.name,
      tankVolumeSnapshot: _profile.tankVolumeLiters,
      waterRateSnapshot: _profile.waterRateLitersPerHa,
      remainderLiters: _remainder,
      refillVolumeLiters: _refillWater,
      coveredAreaHa: _coveredAreaHa,
      chemicals: logChemicals,
    );

    await provider.saveLog(log);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Расчёт сохранён в журнал'),
          backgroundColor: Color(0xFF1976D2),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeChems = _activeChemicals;
    final isFullTank = !_hasRemainder || _remainder == 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _profile.name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Бак ${_profile.tankVolumeLiters.toStringAsFixed(0)} л \u00B7 ${_profile.waterRateLitersPerHa.toStringAsFixed(0)} л/га',
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionCard(
            title: 'Остаток раствора в баке',
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _remainderCtrl,
                        focusNode: _remainderFocus,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        onTap: () => _remainderFocus.requestFocus(),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: const TextStyle(color: Colors.white30, fontSize: 32),
                          suffixText: 'л',
                          suffixStyle: const TextStyle(color: Colors.white60, fontSize: 20),
                          filled: true,
                          fillColor: const Color(0xFF0D1F33),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFF1976D2), width: 2),
                          ),
                          errorText: _errorText,
                          errorStyle: const TextStyle(color: Colors.orangeAccent, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('0%', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF1976D2),
                          inactiveTrackColor: const Color(0xFF0D1F33),
                          thumbColor: const Color(0xFF42A5F5),
                          overlayColor: const Color(0x291976D2),
                          valueIndicatorColor: const Color(0xFF1565C0),
                          valueIndicatorTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
                          showValueIndicator: ShowValueIndicator.always,
                        ),
                        child: Slider(
                          min: 0,
                          max: _profile.tankVolumeLiters,
                          divisions: 100,
                          value: _remainder,
                          label: '${_remainder.toStringAsFixed(0)} л  (${(_remainder / _profile.tankVolumeLiters * 100).toStringAsFixed(0)}%)',
                          onChanged: (val) {
                            _remainderCtrl.text = val == 0 ? '' : val.toStringAsFixed(0);
                          },
                        ),
                      ),
                    ),
                    const Text('100%', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (_errorText == null) ...[
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0D2744),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isFullTank ? const Color(0xFF1976D2) : const Color(0xFF42A5F5),
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isFullTank ? Icons.water_drop : Icons.add_circle,
                        color: isFullTank ? const Color(0xFF1976D2) : const Color(0xFF42A5F5),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isFullTank ? 'ПОЛНАЯ ЗАПРАВКА' : 'ДОЗАПРАВКА',
                        style: const TextStyle(
                          color: Color(0xFF90CAF9),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _bigResult(
                    label: 'Долить воды',
                    value: _formatL(_refillWater),
                    color: isFullTank ? const Color(0xFF1976D2) : const Color(0xFF42A5F5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Площадь обработки: ${_coveredAreaHa.toStringAsFixed(2)} га',
                    style: const TextStyle(color: Colors.white60, fontSize: 15),
                  ),
                  if (activeChems.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 8),
                    ...activeChems.map((c) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.science_outlined, color: Colors.white54, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              c.name,
                              style: const TextStyle(color: Colors.white70, fontSize: 17),
                            ),
                          ),
                          Text(
                            _formatAmount(c),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Сбросить', style: TextStyle(fontSize: 15)),
                    onPressed: () {
                      _remainderCtrl.clear();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.save_outlined, color: Colors.white),
                    label: const Text(
                      'Сохранить в журнал',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _saveToJournal,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162B42),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF90CAF9), fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }


  Widget _bigResult({required String label, required String value, required Color color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
        ),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 38, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
