const express = require('express');
const router = express.Router();

const pool = require('../src/db');
const { requireLogin } = require('../src/middleware');
const { ensureFamilyAndAccountForUser } = require('../src/auth');
const { logError } = require('../src/logger');

// Сюда переносим /reset-data и прочие служебные route'ы

router.post('/reset-data', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;

  const { familyId } = await ensureFamilyAndAccountForUser(userId);
  if (!familyId) {
    return res.redirect('/');
  }

  try {
    await pool.execute('DELETE FROM transactions WHERE family_id = ?', [
      familyId,
    ]);

    await pool.execute('DELETE FROM categories WHERE family_id = ?', [
      familyId,
    ]);

    await pool.execute('DELETE FROM hidden_categories WHERE family_id = ?', [
      familyId,
    ]);

    res.redirect('/');
  } catch (err) {
    logError(err, req, { type: 'reset_family_data' });

    return res.status(500).render('errors/500', {
      user: req.user || null,
    });
  }
});

module.exports = router;