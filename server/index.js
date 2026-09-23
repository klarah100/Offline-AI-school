const express = require('express');
const cors = require('cors');
const Database = require('better-sqlite3');

const app = express();
const db = new Database(process.env.DB_PATH || 'offlineai.db');
app.use(cors());
app.use(express.json({ limit: '256kb' }));

db.exec('CREATE TABLE IF NOT EXISTS attempts (id INTEGER PRIMARY KEY AUTOINCREMENT, learner_id TEXT NOT NULL, question_id TEXT NOT NULL, topic_id TEXT NOT NULL, correct INTEGER NOT NULL, timestamp TEXT NOT NULL)');

app.get('/health', (_req, res) => res.json({ ok: true, service: 'offlineai-school-api' }));

app.post('/v1/sync/attempts', (req, res) => {
  const items = Array.isArray(req.body?.attempts) ? req.body.attempts : [];
  if (items.length > 100) return res.status(413).json({ error: 'batch_too_large' });
  if (items.some(a => !a?.learner_id || !a?.question_id || !a?.topic_id)) {
    return res.status(400).json({ error: 'invalid_attempt' });
  }
  const insert = db.prepare('INSERT INTO attempts(learner_id,question_id,topic_id,correct,timestamp) VALUES(?,?,?,?,?)');
  const tx = db.transaction(xs => xs.forEach(a => insert.run(String(a.learner_id), String(a.question_id), String(a.topic_id), a.correct ? 1 : 0, String(a.timestamp || new Date().toISOString()))));
  tx(items);
  res.json({ accepted: items.length });
});

app.get('/v1/learners/:id/progress', (req, res) => {
  const topics = db.prepare('SELECT topic_id,COUNT(*) attempted,SUM(correct) correct FROM attempts WHERE learner_id=? GROUP BY topic_id').all(req.params.id);
  res.json({ learner_id: req.params.id, topics });
});

const port = Number(process.env.PORT || 8080);
app.listen(port, () => console.log('OfflineAI School API listening on ' + port));
