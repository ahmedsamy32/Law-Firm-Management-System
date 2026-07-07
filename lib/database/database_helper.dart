import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/client.dart';
import '../models/case.dart';
import '../models/session.dart';
import '../models/power_of_attorney.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('law_firm.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // تهيئة sqflite لبيئة الديسكتوب (Windows / Linux / macOS)
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getApplicationSupportDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onConfigure: _onConfigure,
      onUpgrade: _onUpgrade,
    );
  }

  // تفعيل مفاتيح الربط الخارجية (Foreign Keys) لضمان سلامة العلاقات
  static Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    // 1. جدول الموكلين (Clients)
    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        national_id TEXT UNIQUE NOT NULL,
        phone TEXT,
        address TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 2. جدول القضايا (Cases)
    await db.execute('''
      CREATE TABLE cases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        case_number TEXT NOT NULL,
        case_type TEXT NOT NULL,
        court TEXT NOT NULL,
        circle TEXT NOT NULL,
        client_id INTEGER NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (client_id) REFERENCES clients (id) ON DELETE CASCADE
      )
    ''');

    // 3. جدول الجلسات (Sessions)
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_date TEXT NOT NULL,
        decision TEXT,
        next_requirements TEXT,
        case_id INTEGER NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (case_id) REFERENCES cases (id) ON DELETE CASCADE
      )
    ''');

    // 4. جدول التوكيلات (Power of Attorney)
    await db.execute('''
      CREATE TABLE power_of_attorneys (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        poa_number TEXT NOT NULL,
        documentation_office TEXT NOT NULL,
        file_path TEXT,
        client_id INTEGER NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (client_id) REFERENCES clients (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createAuthAndSettingsTables(db);
    }
  }

  Future _createAuthAndSettingsTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        value TEXT
      )
    ''');

    // إدراج مستخدم مدير افتراضي
    await db.insert('users', {
      'username': 'admin',
      'password': 'admin',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // ==========================================
  // العمليات البرمجية لجدول الموكلين (Clients CRUD)
  // ==========================================

  Future<Client> createClient(Client client) async {
    final db = await instance.database;
    final id = await db.insert('clients', client.toJson());
    return client.copyWith(id: id);
  }

  Future<Client?> getClient(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Client.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<List<Client>> getAllClients() async {
    final db = await instance.database;
    final result = await db.query('clients', orderBy: 'name ASC');
    return result.map((json) => Client.fromJson(json)).toList();
  }

  Future<int> updateClient(Client client) async {
    final db = await instance.database;
    return db.update(
      'clients',
      client.toJson(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<int> deleteClient(int id) async {
    final db = await instance.database;
    return await db.delete(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // العمليات البرمجية لجدول القضايا (Cases CRUD)
  // ==========================================

  Future<Case> createCase(Case caseModel) async {
    final db = await instance.database;
    final id = await db.insert('cases', caseModel.toJson());
    return caseModel.copyWith(id: id);
  }

  Future<Case?> getCase(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'cases',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Case.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<List<Case>> getAllCases() async {
    final db = await instance.database;
    final result = await db.query('cases', orderBy: 'created_at DESC');
    return result.map((json) => Case.fromJson(json)).toList();
  }

  Future<List<Case>> getCasesByClientId(int clientId) async {
    final db = await instance.database;
    final result = await db.query(
      'cases',
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'created_at DESC',
    );
    return result.map((json) => Case.fromJson(json)).toList();
  }

  Future<int> updateCase(Case caseModel) async {
    final db = await instance.database;
    return db.update(
      'cases',
      caseModel.toJson(),
      where: 'id = ?',
      whereArgs: [caseModel.id],
    );
  }

  Future<int> deleteCase(int id) async {
    final db = await instance.database;
    return await db.delete(
      'cases',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==========================================
  // العمليات البرمجية لجدول الجلسات (Sessions CRUD)
  // ==========================================

  Future<Session> createSession(Session session) async {
    final db = await instance.database;
    final id = await db.insert('sessions', session.toJson());
    return session.copyWith(id: id);
  }

  Future<Session?> getSession(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Session.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<List<Session>> getSessionsByCaseId(int caseId) async {
    final db = await instance.database;
    final result = await db.query(
      'sessions',
      where: 'case_id = ?',
      whereArgs: [caseId],
      orderBy: 'session_date ASC',
    );
    return result.map((json) => Session.fromJson(json)).toList();
  }

  Future<int> updateSession(Session session) async {
    final db = await instance.database;
    return db.update(
      'sessions',
      session.toJson(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<int> deleteSession(int id) async {
    final db = await instance.database;
    return await db.delete(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================================================
  // العمليات البرمجية لجدول التوكيلات (Power of Attorneys CRUD)
  // ==================================================

  Future<PowerOfAttorney> createPowerOfAttorney(PowerOfAttorney poa) async {
    final db = await instance.database;
    final id = await db.insert('power_of_attorneys', poa.toJson());
    return poa.copyWith(id: id);
  }

  Future<PowerOfAttorney?> getPowerOfAttorney(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'power_of_attorneys',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return PowerOfAttorney.fromJson(maps.first);
    } else {
      return null;
    }
  }

  Future<List<PowerOfAttorney>> getPowerOfAttorneysByClientId(int clientId) async {
    final db = await instance.database;
    final result = await db.query(
      'power_of_attorneys',
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'created_at DESC',
    );
    return result.map((json) => PowerOfAttorney.fromJson(json)).toList();
  }

  Future<int> updatePowerOfAttorney(PowerOfAttorney poa) async {
    final db = await instance.database;
    return db.update(
      'power_of_attorneys',
      poa.toJson(),
      where: 'id = ?',
      whereArgs: [poa.id],
    );
  }

  Future<int> deletePowerOfAttorney(int id) async {
    final db = await instance.database;
    return await db.delete(
      'power_of_attorneys',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // إغلاق قاعدة البيانات عند الانتهاء
  Future close() async {
    final db = await instance.database;
    db.close();
  }

  // ==========================================
  // العمليات البرمجية لجدول المستخدمين (Users CRUD)
  // ==========================================

  Future<int> createUser(String username, String password) async {
    final db = await instance.database;
    return await db.insert('users', {
      'username': username,
      'password': password,
    });
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await instance.database;
    return await db.query('users', orderBy: 'id ASC');
  }

  Future<int> updateUser(int id, String username, String password) async {
    final db = await instance.database;
    return await db.update(
      'users',
      {
        'username': username,
        'password': password,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await instance.database;
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Map<String, dynamic>?> validateUser(String username, String password) async {
    final db = await instance.database;
    final results = await db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  // ==========================================
  // العمليات البرمجية لجدول الإعدادات (Settings CRUD)
  // ==========================================

  Future<void> saveSetting(String key, String value) async {
    final db = await instance.database;
    await db.insert(
      'settings',
      {
        'key': key,
        'value': value,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await instance.database;
    final results = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (results.isNotEmpty) {
      return results.first['value'] as String?;
    }
    return null;
  }
}
