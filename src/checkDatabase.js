const pool = require('./db');

async function checkDatabase(req, res, next) {
  try {
    await pool.query('SELECT 1');
    next();
  } catch (err) {
    console.error('Database connection error:', err);
    return res.status(500).render('errors/db');
  }
}

module.exports = checkDatabase;