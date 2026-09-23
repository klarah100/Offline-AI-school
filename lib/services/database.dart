import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
class AppDatabase {
  AppDatabase._(); static final AppDatabase instance=AppDatabase._(); Database? _db;
  Future<Database> get database async {
    if(_db!=null)return _db!; final root=await getDatabasesPath();
    _db=await openDatabase(join(root,'offline_ai_school.db'),version:6,onCreate:(db,_)=>_createSchema(db),onUpgrade:(db,oldVersion,_) async {
      if(oldVersion<2)await db.execute('ALTER TABLE learners ADD COLUMN goals TEXT NOT NULL DEFAULT ""');
      if(oldVersion<3){await db.execute('ALTER TABLE learners ADD COLUMN learner_id TEXT');await db.execute("UPDATE learners SET learner_id = 'legacy_' || id WHERE learner_id IS NULL");await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_learners_learner_id ON learners(learner_id)');await db.execute('ALTER TABLE attempts ADD COLUMN attempt_type TEXT NOT NULL DEFAULT "practice"');}
      if(oldVersion<4)await db.execute('CREATE INDEX IF NOT EXISTS idx_attempts_topic_type ON attempts(topic_id,attempt_type)');
      if(oldVersion<5){await db.execute('ALTER TABLE attempts ADD COLUMN client_id TEXT');await db.execute('ALTER TABLE attempts ADD COLUMN selected_answer TEXT');await db.execute('ALTER TABLE attempts ADD COLUMN duration_ms INTEGER');await db.execute("UPDATE attempts SET client_id = 'legacy_attempt_' || id WHERE client_id IS NULL");await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_attempts_client_id ON attempts(client_id)');}
      if(oldVersion<6){await db.execute('ALTER TABLE attempts ADD COLUMN learner_id TEXT');final learners=await db.query('learners',orderBy:'id DESC',limit:1);if(learners.isNotEmpty){await db.update('attempts',{'learner_id':learners.first['learner_id']});}await db.execute('CREATE INDEX IF NOT EXISTS idx_attempts_learner_topic ON attempts(learner_id,topic_id,attempt_type)');}
    }); return _db!;
  }
  Future<void> _createSchema(Database db) async {
    await db.execute('''CREATE TABLE learners(id INTEGER PRIMARY KEY AUTOINCREMENT,learner_id TEXT NOT NULL UNIQUE,name TEXT NOT NULL,grade TEXT NOT NULL,language TEXT NOT NULL,goals TEXT NOT NULL DEFAULT "",created_at TEXT NOT NULL,updated_at TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE attempts(id INTEGER PRIMARY KEY AUTOINCREMENT,client_id TEXT NOT NULL UNIQUE,learner_id TEXT NOT NULL,question_id TEXT NOT NULL,topic_id TEXT NOT NULL,correct INTEGER NOT NULL,timestamp TEXT NOT NULL,attempt_type TEXT NOT NULL DEFAULT "practice",selected_answer TEXT,duration_ms INTEGER,synced INTEGER NOT NULL DEFAULT 0)''');
  }
  Future<int> saveLearner({required String name,required String grade,required String language,List<String> goals=const[]}) async {
    final db=await database; final existing=await db.query('learners',orderBy:'id DESC',limit:1); final now=DateTime.now().toIso8601String();
    final learnerId=existing.isNotEmpty?existing.first['learner_id'] as String:'learner_${DateTime.now().microsecondsSinceEpoch}';
    final values={'learner_id':learnerId,'name':name,'grade':grade,'language':language,'goals':goals.join('|'),'updated_at':now};
    if(existing.isNotEmpty){await db.update('learners',values,where:'id = ?',whereArgs:[existing.first['id']]);return existing.first['id'] as int;}
    return db.insert('learners',{...values,'created_at':now});
  }
  Future<Map<String,Object?>?> learner() async {final rows=await (await database).query('learners',orderBy:'id DESC',limit:1);return rows.isEmpty?null:rows.first;}
  Future<void> saveAttempt({String? learnerId,required String questionId,required String topicId,required bool correct,String attemptType='practice',String? selectedAnswer,int? durationMs,String? clientId}) async {
    final stableLearnerId=learnerId??await this.learnerId(); await (await database).insert('attempts',{'learner_id':stableLearnerId,'client_id':clientId??'attempt_${DateTime.now().microsecondsSinceEpoch}','question_id':questionId,'topic_id':topicId,'correct':correct?1:0,'timestamp':DateTime.now().toIso8601String(),'attempt_type':attemptType,'selected_answer':selectedAnswer,'duration_ms':durationMs,'synced':0},conflictAlgorithm:ConflictAlgorithm.ignore);
  }
  Future<List<Map<String,Object?>>> attemptsForTopic(String topicId) async=>(await database).query('attempts',where:'topic_id = ? AND attempt_type = ?',whereArgs:[topicId,'practice'],orderBy:'timestamp ASC');
  Future<String> learnerId() async=>(await learner())?['learner_id'] as String? ?? 'learner_${DateTime.now().microsecondsSinceEpoch}';
  Future<List<Map<String,Object?>>> pendingAttempts() async=>(await database).query('attempts',where:'synced = ?',whereArgs:[0],orderBy:'id ASC',limit:100);
  Future<int> pendingCount() async=>(((await (await database).rawQuery('SELECT COUNT(*) AS count FROM attempts WHERE synced = 0')).first['count']) as int?)??0;
  Future<void> markAttemptsSynced(Iterable<int> ids) async {final db=await database;final batch=db.batch();for(final id in ids)batch.update('attempts',{'synced':1},where:'id = ?',whereArgs:[id]);await batch.commit(noResult:true);}
}
  Future<void> clearForTests() async { final root=await getDatabasesPath(); final path=join(root,'offline_ai_school.db'); await _db?.close(); _db=null; await deleteDatabase(path); }
