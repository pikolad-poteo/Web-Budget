const express = require('express');
const router = express.Router();

const pool = require('../src/db');
const { requireLogin } = require('../src/middleware');
const { ensureFamilyAndAccountForUser } = require('../src/auth');
const { logError } = require('../src/logger');

// Сюда переносим все /categories...

router.get('/categories', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;

  const { familyId } = await ensureFamilyAndAccountForUser(userId);

  const [rows] = await pool.execute(
    `
    SELECT *
    FROM categories
    WHERE (family_id IS NULL OR family_id = ?)
      AND id NOT IN (
        SELECT category_id
        FROM hidden_categories
        WHERE family_id = ?
      )
    ORDER BY id ASC
    `,
    [familyId, familyId]
  );

  res.render('categories/index', {
    user,
    categories: rows,
    message: null,
    activePage: 'categories',
  });
});

router.post('/categories', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;
  const { familyId } = await ensureFamilyAndAccountForUser(userId);

  let { name, type, color, icon } = req.body;

  name = (name || '').trim();
  type = type === 'income' ? 'income' : 'expense';
  color = color || '#cccccc';
  icon = icon || 'bi-tag';

  if (!name) {
    return res.redirect('/categories');
  }

  const [existing] = await pool.execute(
    `
    SELECT id FROM categories
    WHERE (family_id IS NULL OR family_id = ?)
      AND name = ?
      AND type = ?
    LIMIT 1
    `,
    [familyId, name, type]
  );

  if (existing.length > 0) {
    const [rows] = await pool.execute(
      `
      SELECT *
      FROM categories
      WHERE family_id IS NULL OR family_id = ?
      ORDER BY id ASC
      `,
      [familyId]
    );

    return res.render('categories/index', {
      user,
      categories: rows,
      message: `Категория "${name}" уже существует.`,
      activePage: 'categories',
    });
  }

  await pool.execute(
    `
    INSERT INTO categories (family_id, name, type, color, icon)
    VALUES (?, ?, ?, ?, ?)
    `,
    [familyId, name, type, color, icon]
  );

  res.redirect('/categories');
});

router.post('/categories/update', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;
  const { familyId } = await ensureFamilyAndAccountForUser(userId);

  let { id, name, type, color, icon } = req.body;

  if (!id) {
    return res.redirect('/categories');
  }

  const [catRows] = await pool.execute(
    'SELECT * FROM categories WHERE id = ? LIMIT 1',
    [id]
  );

  if (catRows.length === 0) {
    return res.redirect('/categories');
  }

  const category = catRows[0];

  name = (name || '').trim();
  type = type === 'income' ? 'income' : 'expense';
  color = color || '#cccccc';
  icon = icon || 'bi-tag';

  if (!name) {
    return res.redirect('/categories');
  }

  const [existing] = await pool.execute(
    `
    SELECT id
    FROM categories
    WHERE (family_id IS NULL OR family_id = ?)
      AND name = ?
      AND type = ?
      AND id <> ?
    LIMIT 1
    `,
    [familyId, name, type, id]
  );

  if (existing.length > 0) {
    const [rows] = await pool.execute(
      `
      SELECT *
      FROM categories
      WHERE (family_id IS NULL OR family_id = ?)
        AND id NOT IN (
          SELECT category_id
          FROM hidden_categories
          WHERE family_id = ?
        )
      ORDER BY id ASC
      `,
      [familyId, familyId]
    );

    return res.render('categories/index', {
      user,
      categories: rows,
      message: `Категория "${name}" с таким типом уже существует.`,
      activePage: 'categories',
    });
  }

  if (category.family_id === null) {
    const [insertRes] = await pool.execute(
      `
      INSERT INTO categories (family_id, name, type, color, icon)
      VALUES (?, ?, ?, ?, ?)
      `,
      [familyId, name, type, color, icon]
    );
    const newId = insertRes.insertId;

    await pool.execute(
      `
      UPDATE transactions
      SET category_id = ?
      WHERE family_id = ? AND category_id = ?
      `,
      [newId, familyId, id]
    );

    await pool.execute(
      `
      INSERT IGNORE INTO hidden_categories (family_id, category_id)
      VALUES (?, ?)
      `,
      [familyId, id]
    );
  } else if (category.family_id === familyId) {
    await pool.execute(
      `
      UPDATE categories
      SET name = ?, type = ?, color = ?, icon = ?
      WHERE id = ? AND family_id = ?
      `,
      [name, type, color, icon, id, familyId]
    );
  } else {
    return res.redirect('/categories');
  }

  res.redirect('/categories');
});

router.post('/categories/delete', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;
  const { familyId } = await ensureFamilyAndAccountForUser(userId);

  const { id } = req.body;
  if (!id) return res.redirect('/categories');

  try {
    const [rows] = await pool.execute(
      'SELECT id, family_id FROM categories WHERE id = ? LIMIT 1',
      [id]
    );

    if (rows.length === 0) {
      return res.redirect('/categories');
    }

    const category = rows[0];

    await pool.execute(
      `
      DELETE FROM transactions
      WHERE family_id = ? AND category_id = ?
      `,
      [familyId, id]
    );

    if (category.family_id === familyId) {
      await pool.execute(
        `
        DELETE FROM categories
        WHERE id = ? AND family_id = ?
        `,
        [id, familyId]
      );
    } else {
      await pool.execute(
        `
        INSERT IGNORE INTO hidden_categories (family_id, category_id)
        VALUES (?, ?)
        `,
        [familyId, id]
      );
    }

    res.redirect('/categories');
  } catch (err) {
    logError(err, req, { type: 'delete_category' });

    return res.status(500).render('errors/500', {
      user: req.user || null,
    });
  }
});

module.exports = router;