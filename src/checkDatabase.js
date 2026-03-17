const pool = require('./db');
const { logError } = require('./logger');

async function checkDatabase(req, res, next) {
  try {
    await pool.query('SELECT 1');
    return next();
  } catch (err) {
    logError(err, req, { type: 'database_connection_check' });

    if (res.headersSent) {
      return next(err);
    }

    return res.status(500).render('errors/database', {
      user: null,
    });
  }
}

module.exports = checkDatabase;