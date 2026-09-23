const express = require('express');
const cors = require('cors');
const Database = require('better-sqlite3');

const app = express();
const db = new Database(process.env.DB_PATH || 'offlineai.db');

app.use(cors());
app.use(express.json({limit: '256kb'}));

db.exec(`
  CREATE TABLE IF NOT EXISTS attempts(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    client_id TEXT NOT NULL UNIQUE,
    learner_id TEXT NOT NULL,
    question_id TEXT NOT NULL,
    topic_id TEXT NOT NULL,
    correct INTEGER NOT NULL,
    timestamp TEXT NOT NULL,
    attempt_type TEXT NOT NULL,
    selected_answer TEXT,
    duration_ms INTEGER,
    difficulty INTEGER NOT NULL DEFAULT 1
  )
`);

const columns = db.prepare('PRAGMA table_info(attempts)').all().map((c) => c.name);
if (!columns.includes('difficulty')) {
  db.exec('ALTER TABLE attempts ADD COLUMN difficulty INTEGER NOT NULL DEFAULT 1');
}

app.get('/health', (_req, res) => {
  res.json({ok: true, service: 'offlineai-school-api'});
});

app.post('/v1/sync/attempts', (req, res) => {
  const items = Array.isArray(req.body?.attempts) ? req.body.attempts : [];

  if (items.length === 0) {
    return res.status(400).json({error: 'empty_batch'});
  }
  if (items.length > 100) {
    return res.status(413).json({error: 'batch_too_large'});
  }

  for (const attempt of items) {
    if (!attempt?.client_id || !attempt?.learner_id || !attempt?.question_id || !attempt?.topic_id) {
      return res.status(400).json({error: 'invalid_attempt'});
    }
    const difficulty = Number(attempt.difficulty ?? 1);
    if (![1, 2, 3].includes(difficulty)) {
      return res.status(400).json({error: 'invalid_difficulty'});
    }
  }

  const insert = db.prepare(`
    INSERT OR IGNORE INTO attempts(
      client_id, learner_id, question_id, topic_id, correct, timestamp,
      attempt_type, selected_answer, duration_ms, difficulty
    ) VALUES(?,?,?,?,?,?,?,?,?,?)
  `);

  let inserted = 0;
  const write = db.transaction((rows) => {
    for (const attempt of rows) {
      const result = insert.run(
        String(attempt.client_id),
        String(attempt.learner_id),
        String(attempt.question_id),
        String(attempt.topic_id),
        attempt.correct ? 1 : 0,
        String(attempt.timestamp || new Date().toISOString()),
        String(attempt.attempt_type || 'practice'),
        attempt.selected_answer == null ? null : String(attempt.selected_answer),
        attempt.duration_ms == null ? null : Number(attempt.duration_ms),
        Number(attempt.difficulty ?? 1)
      );
      if (result.changes === 1) inserted += 1;
    }
  });

  write(items);
  return res.json({accepted: inserted, duplicates: items.length - inserted});
});

app.get('/v1/learners/:id/progress', (req, res) => {
  const topics = db.prepare(`
    SELECT topic_id, COUNT(*) attempted, SUM(correct) correct
    FROM attempts
    WHERE learner_id = ? AND attempt_type = 'practice'
    GROUP BY topic_id
  `).all(req.params.id);

  res.json({learner_id: req.params.id, topics});
});

const port = Number(process.env.PORT || 8080);
app.listen(port, () => console.log('OfflineAI School API listening on ' + port));
