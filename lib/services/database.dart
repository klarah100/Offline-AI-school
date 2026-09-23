import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final root = await getDatabasesPath();
    _db = await openDatabase(
      join(root, 'offline_ai_school.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE learners (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            grade TEXT NOT NULL,
            language TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE attempts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            question_id TEXT NOT NULL,
            correct INTEGER NOT NULL,
            timestamp TEXT NOT NULL,
            synced INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
    return _db!;
  }

  Future<int> saveLearner({
    required String name,
    required String grade,
    required String language,
  }) async {
    final db = await database;
    return db.insert('learners', {
      'name': name,
      'grade': grade,
      'language': language,
    });
  }

  Future<void> saveAttempt({
    required String questionId,
    required bool correct,
  }) async {
    final db = await database;
    await db.insert('attempts', {
      'question_id': questionId,
      'correct': correct ? 1 : 0,
      'timestamp': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  Future<List<Map<String, Object?>>> pendingAttempts() async {
    final db = await database;
    return db.query('attempts', where: 'synced = ?', whereArgs: [0]);
  }

  Future<void> markAttemptsSynced() async {
    final db = await database;
    await db.update('attempts', {'synced': 1}, where: 'synced = ?', whereArgs: [0]);
  }
}
