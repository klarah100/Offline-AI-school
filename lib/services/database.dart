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
      version: 2,
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE learners ADD COLUMN goals TEXT NOT NULL DEFAULT ""');
        }
      },
    );
    return _db!;
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE learners (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        grade TEXT NOT NULL,
        language TEXT NOT NULL,
        goals TEXT NOT NULL DEFAULT ""
      )
    ''');
    await db.execute('''
      CREATE TABLE attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id TEXT NOT NULL,
        topic_id TEXT NOT NULL,
        correct INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  Future<int> saveLearner({
    required String name,
    required String grade,
    required String language,
    List<String> goals = const [],
  }) async {
    final db = await database;
    final existing = await db.query('learners', orderBy: 'id DESC', limit: 1);
    final values = {
      'name': name,
      'grade': grade,
      'language': language,
      'goals': goals.join('|'),
    };
    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      await db.update('learners', values, where: 'id = ?', whereArgs: [id]);
      return id;
    }
    return db.insert('learners', values);
  }

  Future<Map<String, Object?>?> learner() async {
    final db = await database;
    final rows = await db.query('learners', orderBy: 'id DESC', limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> saveAttempt({
    required String questionId,
    required String topicId,
    required bool correct,
  }) async {
    final db = await database;
    await db.insert('attempts', {
      'question_id': questionId,
      'topic_id': topicId,
      'correct': correct ? 1 : 0,
      'timestamp': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  Future<List<Map<String, Object?>>> attemptsForTopic(String topicId) async {
    final db = await database;
    return db.query('attempts', where: 'topic_id = ?', whereArgs: [topicId], orderBy: 'timestamp ASC');
  }

  Future<List<Map<String, Object?>>> pendingAttempts() async {
    final db = await database;
    return db.query('attempts', where: 'synced = ?', whereArgs: [0]);
  }

  Future<int> pendingCount() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS count FROM attempts WHERE synced = 0');
    return (rows.first['count'] as int?) ?? 0;
  }

  Future<void> markAttemptsSynced(Iterable<int> ids) async {
    final db = await database;
    final batch = db.batch();
    for (final id in ids) {
      batch.update('attempts', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }
}
