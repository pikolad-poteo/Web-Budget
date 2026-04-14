const express = require('express');
const router = express.Router();

const pool = require('../src/db');
const { requireLogin } = require('../src/middleware');
const { ensureFamilyAndAccountForUser } = require('../src/auth');

// Сюда переносим:
// GET /

router.get('/', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;

  const { familyId, accountId } = await ensureFamilyAndAccountForUser(userId);

  if (!familyId || !accountId) {
    return res.redirect('/family');
  }

  const [memberCountRows] = await pool.execute(
    'SELECT COUNT(*) AS cnt FROM family_members WHERE family_id = ?',
    [familyId]
  );

  if (memberCountRows[0].cnt === 0) {
    return res.redirect('/family');
  }

  const [balRows] = await pool.execute(
    `
    SELECT COALESCE(SUM(amount), 0) AS balance
    FROM transactions
    WHERE family_id = ? AND account_id = ?
    `,
    [familyId, accountId]
  );
  const balance = balRows[0].balance;

  const fromDate = new Date();
  fromDate.setDate(1);
  const toDate = new Date(fromDate.getFullYear(), fromDate.getMonth() + 1, 0);

  const fromStr = fromDate.toISOString().slice(0, 10);
  const toStr = toDate.toISOString().slice(0, 10);

  const [incRows] = await pool.execute(
    `
    SELECT COALESCE(SUM(amount), 0) AS income
    FROM transactions
    WHERE family_id = ?
      AND account_id = ?
      AND amount > 0
      AND date BETWEEN ? AND ?
    `,
    [familyId, accountId, fromStr, toStr]
  );
  const income = incRows[0].income;

  const [expRows] = await pool.execute(
    `
    SELECT COALESCE(SUM(amount), 0) AS expense
    FROM transactions
    WHERE family_id = ?
      AND account_id = ?
      AND amount < 0
      AND date BETWEEN ? AND ?
    `,
    [familyId, accountId, fromStr, toStr]
  );
  const expense = expRows[0].expense;

  const [catRows] = await pool.execute(
    `
    SELECT
      c.name AS category_name,
      c.color,
      c.icon,
      COALESCE(SUM(-t.amount), 0) AS total_spent
    FROM transactions t
    JOIN categories c ON c.id = t.category_id
    WHERE t.family_id = ?
      AND t.account_id = ?
      AND t.amount < 0
      AND t.date BETWEEN ? AND ?
    GROUP BY c.id, c.name, c.color, c.icon
    ORDER BY total_spent DESC
    `,
    [familyId, accountId, fromStr, toStr]
  );

  const categoriesSummaryRaw = catRows.map((row) => ({
    name: row.category_name,
    total: Number(row.total_spent || 0),
    color: row.color || '#cccccc',
    icon: row.icon || 'bi-tag',
  }));

  const totalExpensesAbs = categoriesSummaryRaw.reduce(
    (sum, row) => sum + row.total,
    0
  );

  const categoriesSummary = categoriesSummaryRaw.map((row) => ({
    name: row.name,
    total: row.total,
    color: row.color,
    icon: row.icon,
    percent:
      totalExpensesAbs > 0
        ? Math.round((row.total / totalExpensesAbs) * 1000) / 10
        : 0,
  }));

  res.render('dashboard/index', {
    user,
    balance,
    income,
    expense,
    categoriesSummary,
    totalExpensesAbs,
    activePage: 'dashboard',
  });
});

module.exports = router;