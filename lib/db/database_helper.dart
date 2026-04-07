import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/profile.dart';
import '../models/calculation_log.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    _database ??= await _initDB('agronom.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);
    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE profiles ADD COLUMN notes TEXT NOT NULL DEFAULT ''");
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        tank_volume_liters REAL NOT NULL,
        water_rate_liters_per_ha REAL NOT NULL,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE profile_chemicals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        rate_value REAL NOT NULL,
        rate_unit TEXT NOT NULL DEFAULT 'л/га',
        sort_order INTEGER NOT NULL DEFAULT 0,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (profile_id) REFERENCES profiles (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE calculation_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id INTEGER NOT NULL,
        profile_name_snapshot TEXT NOT NULL,
        tank_volume_snapshot REAL NOT NULL,
        water_rate_snapshot REAL NOT NULL,
        remainder_liters REAL NOT NULL,
        refill_volume_liters REAL NOT NULL,
        covered_area_ha REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE calculation_log_chemicals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        calculation_log_id INTEGER NOT NULL,
        name_snapshot TEXT NOT NULL,
        rate_value_snapshot REAL NOT NULL,
        rate_unit_snapshot TEXT NOT NULL,
        amount_to_add REAL NOT NULL,
        FOREIGN KEY (calculation_log_id) REFERENCES calculation_logs (id) ON DELETE CASCADE
      )
    ''');
  }

  // --- PROFILES ---

  Future<int> insertProfile(Profile profile) async {
    final db = await database;
    return await db.insert('profiles', profile.toMap());
  }

  Future<List<Profile>> getAllProfiles() async {
    final db = await database;
    final profileMaps = await db.query('profiles', orderBy: 'is_favorite DESC, updated_at DESC');
    final profiles = <Profile>[];
    for (final map in profileMaps) {
      final profile = Profile.fromMap(map);
      profile.chemicals = await getChemicalsForProfile(profile.id!);
      profiles.add(profile);
    }
    return profiles;
  }

  Future<Profile?> getProfile(int id) async {
    final db = await database;
    final maps = await db.query('profiles', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    final profile = Profile.fromMap(maps.first);
    profile.chemicals = await getChemicalsForProfile(id);
    return profile;
  }

  Future<void> updateProfile(Profile profile) async {
    final db = await database;
    await db.update('profiles', profile.toMap(), where: 'id = ?', whereArgs: [profile.id]);
  }

  Future<void> deleteProfile(int id) async {
    final db = await database;
    await db.delete('profiles', where: 'id = ?', whereArgs: [id]);
    await db.delete('profile_chemicals', where: 'profile_id = ?', whereArgs: [id]);
  }

  // --- CHEMICALS ---

  Future<List<ProfileChemical>> getChemicalsForProfile(int profileId) async {
    final db = await database;
    final maps = await db.query(
      'profile_chemicals',
      where: 'profile_id = ?',
      whereArgs: [profileId],
      orderBy: 'sort_order ASC',
    );
    return maps.map((m) => ProfileChemical.fromMap(m)).toList();
  }

  Future<void> saveChemicalsForProfile(int profileId, List<ProfileChemical> chemicals) async {
    final db = await database;
    await db.delete('profile_chemicals', where: 'profile_id = ?', whereArgs: [profileId]);
    for (int i = 0; i < chemicals.length; i++) {
      final chem = chemicals[i].copyWith(profileId: profileId, sortOrder: i);
      await db.insert('profile_chemicals', chem.toMap());
    }
  }

  // --- LOGS ---

  Future<int> insertLog(CalculationLog log) async {
    final db = await database;
    final logId = await db.insert('calculation_logs', log.toMap());
    for (final chem in log.chemicals) {
      final c = CalculationLogChemical(
        calculationLogId: logId,
        nameSnapshot: chem.nameSnapshot,
        rateValueSnapshot: chem.rateValueSnapshot,
        rateUnitSnapshot: chem.rateUnitSnapshot,
        amountToAdd: chem.amountToAdd,
      );
      await db.insert('calculation_log_chemicals', c.toMap());
    }
    return logId;
  }

  Future<List<CalculationLog>> getAllLogs() async {
    final db = await database;
    final logMaps = await db.query('calculation_logs', orderBy: 'created_at DESC');
    final logs = <CalculationLog>[];
    for (final map in logMaps) {
      final log = CalculationLog.fromMap(map);
      final chemMaps = await db.query(
        'calculation_log_chemicals',
        where: 'calculation_log_id = ?',
        whereArgs: [log.id],
      );
      log.chemicals = chemMaps.map((m) => CalculationLogChemical.fromMap(m)).toList();
      logs.add(log);
    }
    return logs;
  }

  Future<void> deleteLog(int id) async {
    final db = await database;
    await db.delete('calculation_logs', where: 'id = ?', whereArgs: [id]);
    await db.delete('calculation_log_chemicals', where: 'calculation_log_id = ?', whereArgs: [id]);
  }
}
