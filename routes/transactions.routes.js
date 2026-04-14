const express = require('express');
const router = express.Router();

const pool = require('../src/db');
const { requireLogin } = require('../src/middleware');
const { ensureFamilyAndAccountForUser } = require('../src/auth');

// Сюда переносим все /transactions...

router.get('/transactions', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;

  const { familyId, accountId } = await ensureFamilyAndAccountForUser(userId);

  const [memberRows] = await pool.execute(
    `
    SELECT id, name
    FROM family_members
    WHERE family_id = ?
    ORDER BY id ASC
    `,
    [familyId]
  );

  if (memberRows.length === 0) {
    return res.redirect('/family');
  }

  const { from, to, category_id } = req.query;

  let fromDate = from || null;
  let toDate = to || null;

  if (!fromDate || !toDate) {
    const d = new Date();
    const first = new Date(d.getFullYear(), d.getMonth(), 1);
    const last = new Date(d.getFullYear(), d.getMonth() + 1, 0);
    fromDate = fromDate || first.toISOString().slice(0, 10);
    toDate = toDate || last.toISOString().slice(0, 10);
  }

  const [catRows] = await pool.execute(
    `
    SELECT *
    FROM categories
    WHERE family_id = ? OR family_id IS NULL
    ORDER BY name ASC
    `,
    [familyId]
  );

  let query = `
    SELECT
      t.*,
      c.name  AS category_name,
      c.color AS category_color,
      c.icon  AS category_icon
    FROM transactions t
    JOIN categories c ON c.id = t.category_id
    WHERE t.family_id = ?
      AND t.account_id = ?
      AND t.date BETWEEN ? AND ?
  `;
  const params = [familyId, accountId, fromDate, toDate];

  if (category_id && category_id !== 'all') {
    query += ' AND t.category_id = ?';
    params.push(category_id);
  }

  query += ' ORDER BY t.date DESC, t.id DESC';

  const [txRows] = await pool.execute(query, params);

  res.render('transactions/index', {
    user,
    transactions: txRows,
    categories: catRows,
    members: memberRows,
    filters: {
      from: fromDate,
      to: toDate,
      category_id: category_id || 'all',
    },
    activePage: 'transactions',
  });
});

router.post('/transactions', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;

  const { familyId, accountId } = await ensureFamilyAndAccountForUser(userId);

  const { date, amount, category_id, description, type, who } = req.body;

  let value = parseFloat(amount);
  if (type === 'expense' && value > 0) {
    value = -value;
  }

  const whoValue = (who || '').trim() || null;

  await pool.execute(
    `
    INSERT INTO transactions
      (family_id, account_id, user_id, category_id, amount, date, description, who)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `,
    [familyId, accountId, userId, category_id, value, date, description || null, whoValue]
  );

  res.redirect('/transactions');
});

module.exports = router;