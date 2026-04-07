import 'package:flutter/foundation.dart';
import '../db/database_helper.dart';
import '../models/profile.dart';
import '../models/calculation_log.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Profile> _profiles = [];
  List<CalculationLog> _logs = [];
  bool _loading = false;

  List<Profile> get profiles => _profiles;
  List<CalculationLog> get logs => _logs;
  bool get loading => _loading;

  Future<void> loadProfiles() async {
    _loading = true;
    notifyListeners();
    _profiles = await _db.getAllProfiles();
    _loading = false;
    notifyListeners();
  }

  Future<void> loadLogs() async {
    _logs = await _db.getAllLogs();
    notifyListeners();
  }

  Future<Profile> createProfile(Profile profile) async {
    final id = await _db.insertProfile(profile);
    await _db.saveChemicalsForProfile(id, profile.chemicals);
    await loadProfiles();
    return (await _db.getProfile(id))!;
  }

  Future<void> updateProfile(Profile profile) async {
    await _db.updateProfile(profile);
    await _db.saveChemicalsForProfile(profile.id!, profile.chemicals);
    await loadProfiles();
  }

  Future<void> deleteProfile(int id) async {
    await _db.deleteProfile(id);
    await loadProfiles();
  }

  Future<Profile> duplicateProfile(Profile profile) async {
    final copy = profile.copyWith(
      id: null,
      name: '${profile.name} (копия)',
      chemicals: profile.chemicals
          .map((c) => c.copyWith(id: null, profileId: 0))
          .toList(),
    );
    return await createProfile(copy);
  }

  Future<void> saveLog(CalculationLog log) async {
    await _db.insertLog(log);
    await loadLogs();
  }

  Future<void> deleteLog(int id) async {
    await _db.deleteLog(id);
    await loadLogs();
  }
}
