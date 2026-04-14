const express = require('express');
const router = express.Router();

const pool = require('../src/db');
const { requireLogin } = require('../src/middleware');
const { ensureFamilyAndAccountForUser } = require('../src/auth');
const { logError } = require('../src/logger');

// Если есть upload middleware или helper-функции для wishlist,
// их тоже подключим сюда.

// Сюда переносим все /wishlist...

function normalizeUrl(value) {
  const url = String(value || '').trim();
  if (!url) return null;

  if (
    url.startsWith('http://') ||
    url.startsWith('https://')
  ) {
    return url;
  }

  return `https://${url}`;
}

router.get('/wishlist', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;

  try {
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

    let { status, category_id, q } = req.query;
    status = String(status || 'all').trim();
    category_id = String(category_id || 'all').trim();
    q = String(q || '').trim();

    const [categories] = await pool.execute(
      `
      SELECT *
      FROM categories
      WHERE (family_id = ? OR family_id IS NULL)
        AND type = 'expense'
      ORDER BY name ASC
      `,
      [familyId]
    );

    let query = `
      SELECT
        w.*,
        c.name AS category_name,
        c.color AS category_color,
        c.icon AS category_icon
      FROM wishlist w
      LEFT JOIN categories c ON c.id = w.category_id
      WHERE w.family_id = ?
        AND w.account_id = ?
    `;
    const params = [familyId, accountId];

    if (status !== 'all') {
      query += ' AND w.status = ?';
      params.push(status);
    }

    if (category_id !== 'all') {
      query += ' AND w.category_id = ?';
      params.push(category_id);
    }

    if (q) {
      query += ' AND (w.title LIKE ? OR w.description LIKE ?)';
      params.push(`%${q}%`, `%${q}%`);
    }

    query += `
      ORDER BY
        CASE w.status
          WHEN 'planned' THEN 1
          WHEN 'postponed' THEN 2
          WHEN 'bought' THEN 3
          WHEN 'cancelled' THEN 4
          ELSE 5
        END,
        w.created_at DESC
    `;

    const [wishlist] = await pool.execute(query, params);

    const [balanceRows] = await pool.execute(
      `
      SELECT COALESCE(SUM(amount), 0) AS balance
      FROM transactions
      WHERE family_id = ? AND account_id = ?
      `,
      [familyId, accountId]
    );

    const balance = Number(balanceRows[0].balance || 0);

    const [summaryRows] = await pool.execute(
      `
      SELECT
        COUNT(*) AS total_items,
        COALESCE(SUM(CASE WHEN status = 'planned' THEN amount ELSE 0 END), 0) AS planned_total,
        COALESCE(SUM(CASE WHEN status = 'bought' THEN amount ELSE 0 END), 0) AS bought_total,
        COALESCE(SUM(CASE WHEN status = 'postponed' THEN amount ELSE 0 END), 0) AS postponed_total
      FROM wishlist
      WHERE family_id = ? AND account_id = ?
      `,
      [familyId, accountId]
    );

    const summary = {
      totalItems: Number(summaryRows[0].total_items || 0),
      plannedTotal: Number(summaryRows[0].planned_total || 0),
      boughtTotal: Number(summaryRows[0].bought_total || 0),
      postponedTotal: Number(summaryRows[0].postponed_total || 0),
      balance,
      freeAfterPlanned:
        balance - Number(summaryRows[0].planned_total || 0),
    };

    res.render('wishlist/index', {
      user,
      members: memberRows,
      categories,
      wishlist,
      summary,
      filters: {
        status,
        category_id,
        q,
      },
      activePage: 'wishlist',
    });
  } catch (err) {
    logError(err, req, { type: 'wishlist_index' });

    return res.status(500).render('errors/500', {
      user: req.user || null,
    });
  }
});

router.get('/wishlist/:id', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;

  try {
    const { familyId, accountId } = await ensureFamilyAndAccountForUser(userId);
    const { id } = req.params;

    const [members] = await pool.execute(
      `
      SELECT id, name
      FROM family_members
      WHERE family_id = ?
      ORDER BY id ASC
      `,
      [familyId]
    );

    const [categories] = await pool.execute(
      `
      SELECT *
      FROM categories
      WHERE (family_id = ? OR family_id IS NULL)
        AND type = 'expense'
      ORDER BY name ASC
      `,
      [familyId]
    );

    const [rows] = await pool.execute(
      `
      SELECT
        w.*,
        c.name AS category_name,
        c.color AS category_color,
        c.icon AS category_icon
      FROM wishlist w
      LEFT JOIN categories c ON c.id = w.category_id
      WHERE w.id = ?
        AND w.family_id = ?
        AND w.account_id = ?
      LIMIT 1
      `,
      [id, familyId, accountId]
    );

    if (rows.length === 0) {
      return res.status(404).render('errors/404', {
        user: req.user || null,
      });
    }

    const item = rows[0];

    res.render('wishlist/show', {
      user,
      item,
      members,
      categories,
      activePage: 'wishlist',
    });
  } catch (err) {
    logError(err, req, { type: 'wishlist_show' });

    return res.status(500).render('errors/500', {
      user: req.user || null,
    });
  }
});

router.post('/wishlist', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;

  try {
    const { familyId, accountId } = await ensureFamilyAndAccountForUser(userId);

    let {
      title,
      amount,
      image_url,
      store_url,
      category_id,
      description,
      planned_date,
      who,
      priority,
    } = req.body;

    title = String(title || '').trim();
    description = String(description || '').trim() || null;
    planned_date = String(planned_date || '').trim() || null;
    who = String(who || '').trim() || null;
    image_url = normalizeUrl(image_url);
    store_url = normalizeUrl(store_url);

    if (category_id === '' || category_id === 'none') {
      category_id = null;
    }

    priority = ['low', 'medium', 'high'].includes(priority) ? priority : 'medium';

    const parsedAmount = parseFloat(amount);

    if (!title || Number.isNaN(parsedAmount) || parsedAmount <= 0) {
      return res.redirect('/wishlist');
    }

    await pool.execute(
      `
      INSERT INTO wishlist
        (
          family_id,
          account_id,
          user_id,
          category_id,
          title,
          description,
          amount,
          planned_date,
          priority,
          status,
          who,
          store_url,
          image_url
        )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 'planned', ?, ?, ?)
      `,
      [
        familyId,
        accountId,
        userId,
        category_id,
        title,
        description,
        parsedAmount,
        planned_date,
        priority,
        who,
        store_url,
        image_url,
      ]
    );

    res.redirect('/wishlist');
  } catch (err) {
    logError(err, req, { type: 'wishlist_create' });

    return res.status(500).render('errors/500', {
      user: req.user || null,
    });
  }
});

router.post('/wishlist/update/:id', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;

  try {
    const { familyId, accountId } = await ensureFamilyAndAccountForUser(userId);
    const { id } = req.params;

    let {
      title,
      amount,
      image_url,
      store_url,
      category_id,
      description,
      planned_date,
      who,
      priority,
      status,
    } = req.body;

    title = String(title || '').trim();
    description = String(description || '').trim() || null;
    planned_date = String(planned_date || '').trim() || null;
    who = String(who || '').trim() || null;
    image_url = normalizeUrl(image_url);
    store_url = normalizeUrl(store_url);

    if (category_id === '' || category_id === 'none') {
      category_id = null;
    }

    priority = ['low', 'medium', 'high'].includes(priority) ? priority : 'medium';
    status = ['planned', 'postponed', 'bought', 'cancelled'].includes(status)
      ? status
      : 'planned';

    const parsedAmount = parseFloat(amount);

    if (!title || Number.isNaN(parsedAmount) || parsedAmount <= 0) {
      return res.redirect(`/wishlist/${id}`);
    }

    await pool.execute(
      `
      UPDATE wishlist
      SET
        category_id = ?,
        title = ?,
        description = ?,
        amount = ?,
        planned_date = ?,
        priority = ?,
        status = ?,
        who = ?,
        store_url = ?,
        image_url = ?
      WHERE id = ?
        AND family_id = ?
        AND account_id = ?
      `,
      [
        category_id,
        title,
        description,
        parsedAmount,
        planned_date,
        priority,
        status,
        who,
        store_url,
        image_url,
        id,
        familyId,
        accountId,
      ]
    );

    res.redirect(`/wishlist/${id}`);
  } catch (err) {
    logError(err, req, { type: 'wishlist_update' });

    return res.status(500).render('errors/500', {
      user: req.user || null,
    });
  }
});

router.post('/wishlist/status', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;

  try {
    const { familyId, accountId } = await ensureFamilyAndAccountForUser(userId);
    const { id, status } = req.body;

    const allowedStatuses = ['planned', 'postponed', 'bought', 'cancelled'];

    if (!id || !allowedStatuses.includes(status)) {
      return res.redirect('/wishlist');
    }

    await pool.execute(
      `
      UPDATE wishlist
      SET status = ?
      WHERE id = ?
        AND family_id = ?
        AND account_id = ?
      `,
      [status, id, familyId, accountId]
    );

    res.redirect(`/wishlist/${id}`);
  } catch (err) {
    logError(err, req, { type: 'wishlist_status_update' });

    return res.status(500).render('errors/500', {
      user: req.user || null,
    });
  }
});

router.post('/wishlist/delete', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;

  try {
    const { familyId, accountId } = await ensureFamilyAndAccountForUser(userId);
    const { id } = req.body;

    if (!id) {
      return res.redirect('/wishlist');
    }

    await pool.execute(
      `
      DELETE FROM wishlist
      WHERE id = ?
        AND family_id = ?
        AND account_id = ?
      `,
      [id, familyId, accountId]
    );

    res.redirect('/wishlist');
  } catch (err) {
    logError(err, req, { type: 'wishlist_delete' });

    return res.status(500).render('errors/500', {
      user: req.user || null,
    });
  }
});

module.exports = router;