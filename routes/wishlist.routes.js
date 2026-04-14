const express = require('express');
const router = express.Router();
const fs = require('fs');
const path = require('path');
const multer = require('multer');

const wishlistUploadDir = path.join(__dirname, '..', 'public', 'uploads', 'wishlist');
fs.mkdirSync(wishlistUploadDir, { recursive: true });

const wishlistStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, wishlistUploadDir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname || '').toLowerCase() || '.jpg';
    const safeExt = ['.jpg', '.jpeg', '.png', '.webp', '.gif'].includes(ext) ? ext : '.jpg';
    cb(null, `${Date.now()}-${Math.round(Math.random() * 1e9)}${safeExt}`);
  }
});

function wishlistFileFilter(req, file, cb) {
  if (!file.mimetype || !file.mimetype.startsWith('image/')) {
    return cb(new Error('Можно загружать только изображения'));
  }

  cb(null, true);
}

const wishlistUpload = multer({
  storage: wishlistStorage,
  fileFilter: wishlistFileFilter,
  limits: {
    fileSize: 5 * 1024 * 1024
  }
});

function buildWishlistImagePublicPath(file) {
  if (!file) return null;
  return `/uploads/wishlist/${file.filename}`;
}

function isLocalWishlistUpload(imageUrl) {
  return typeof imageUrl === 'string' && imageUrl.startsWith('/uploads/wishlist/');
}

function deleteLocalWishlistImage(imageUrl) {
  if (!isLocalWishlistUpload(imageUrl)) return;

  const localPath = path.join(__dirname, '..', 'public', imageUrl.replace(/^\/+/, ''));

  fs.unlink(localPath, (err) => {
    if (err && err.code !== 'ENOENT') {
      console.error('Не удалось удалить локальное изображение wishlist:', err.message);
    }
  });
}

const pool = require('../src/db');
const { requireLogin } = require('../src/middleware');
const { ensureFamilyAndAccountForUser } = require('../src/auth');
const { logError } = require('../src/logger');

function normalizeUrl(value) {
  const url = String(value || '').trim();
  if (!url) return null;

  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }

  return `https://${url}`;
}

function getTodayDateString() {
  return new Date().toISOString().slice(0, 10);
}

function decodeHtmlEntities(value) {
  return String(value || '')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>');
}

function toAbsoluteUrl(candidate, baseUrl) {
  try {
    return new URL(candidate, baseUrl).toString();
  } catch (err) {
    return null;
  }
}

async function ensureWishlistCategory(familyId) {
  const [rows] = await pool.execute(
    `
    SELECT id
    FROM categories
    WHERE family_id = ?
      AND type = 'expense'
      AND LOWER(name) = 'wishlist'
    LIMIT 1
    `,
    [familyId]
  );

  if (rows.length > 0) {
    return rows[0].id;
  }

  const [insertRes] = await pool.execute(
    `
    INSERT INTO categories (family_id, name, type, color, icon)
    VALUES (?, 'WishList', 'expense', '#8E44AD', 'bi-bag-heart')
    `,
    [familyId]
  );

  return insertRes.insertId;
}

async function extractImageFromStoreUrl(storeUrl) {
  if (!storeUrl) return null;

  try {
    const response = await fetch(storeUrl, {
      headers: {
        'User-Agent': 'Mozilla/5.0 Web-Budget Wishlist Preview Bot',
        Accept: 'text/html,application/xhtml+xml'
      }
    });

    if (!response.ok) {
      return null;
    }

    const html = await response.text();
    if (!html) {
      return null;
    }

    const patterns = [
      /<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']/i,
      /<meta[^>]+content=["']([^"']+)["'][^>]+property=["']og:image["']/i,
      /<meta[^>]+name=["']twitter:image["'][^>]+content=["']([^"']+)["']/i,
      /<meta[^>]+content=["']([^"']+)["'][^>]+name=["']twitter:image["']/i,
      /<img[^>]+src=["']([^"']+)["'][^>]*>/i
    ];

    for (const pattern of patterns) {
      const match = html.match(pattern);

      if (!match || !match[1]) {
        continue;
      }

      const cleaned = decodeHtmlEntities(match[1].trim());
      const absolute = toAbsoluteUrl(cleaned, storeUrl);

      if (absolute && /^https?:\/\//i.test(absolute)) {
        return absolute;
      }
    }

    return null;
  } catch (err) {
    return null;
  }
}

async function syncWishlistPurchase({
  familyId,
  accountId,
  userId,
  itemId,
  status
}) {
  const [rows] = await pool.execute(
    `
    SELECT *
    FROM wishlist
    WHERE id = ?
      AND family_id = ?
      AND account_id = ?
    LIMIT 1
    `,
    [itemId, familyId, accountId]
  );

  if (rows.length === 0) {
    return;
  }

  const item = rows[0];

  if (status === 'bought') {
    const wishlistCategoryId = await ensureWishlistCategory(familyId);

    if (item.linked_transaction_id) {
      await pool.execute(
        `
        UPDATE transactions
        SET
          category_id = ?,
          amount = ?,
          date = ?,
          description = ?,
          who = ?
        WHERE id = ?
          AND family_id = ?
          AND account_id = ?
        `,
        [
          wishlistCategoryId,
          -Math.abs(Number(item.amount)),
          item.planned_date || getTodayDateString(),
          item.title,
          item.who || null,
          item.linked_transaction_id,
          familyId,
          accountId
        ]
      );

      await pool.execute(
        `
        UPDATE wishlist
        SET category_id = ?
        WHERE id = ?
          AND family_id = ?
          AND account_id = ?
        `,
        [wishlistCategoryId, itemId, familyId, accountId]
      );

      return;
    }

    const [txRes] = await pool.execute(
      `
      INSERT INTO transactions
        (
          family_id,
          account_id,
          user_id,
          category_id,
          amount,
          date,
          description,
          who
        )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      `,
      [
        familyId,
        accountId,
        userId,
        wishlistCategoryId,
        -Math.abs(Number(item.amount)),
        item.planned_date || getTodayDateString(),
        item.title,
        item.who || null
      ]
    );

    await pool.execute(
      `
      UPDATE wishlist
      SET
        category_id = ?,
        linked_transaction_id = ?
      WHERE id = ?
        AND family_id = ?
        AND account_id = ?
      `,
      [wishlistCategoryId, txRes.insertId, itemId, familyId, accountId]
    );

    return;
  }

  if (item.linked_transaction_id) {
    await pool.execute(
      `
      DELETE FROM transactions
      WHERE id = ?
        AND family_id = ?
        AND account_id = ?
      `,
      [item.linked_transaction_id, familyId, accountId]
    );

    await pool.execute(
      `
      UPDATE wishlist
      SET linked_transaction_id = NULL
      WHERE id = ?
        AND family_id = ?
        AND account_id = ?
      `,
      [itemId, familyId, accountId]
    );
  }
}

router.get('/wishlist/preview-image', requireLogin, async (req, res) => {
  try {
    const storeUrl = normalizeUrl(req.query.store_url);

    if (!storeUrl) {
      return res.json({
        success: false,
        image_url: null
      });
    }

    const imageUrl = await extractImageFromStoreUrl(storeUrl);

    return res.json({
      success: !!imageUrl,
      image_url: imageUrl || null
    });
  } catch (err) {
    logError(err, req, { type: 'wishlist_preview_image' });

    return res.status(500).json({
      success: false,
      image_url: null
    });
  }
});

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

 router.post('/wishlist', requireLogin, wishlistUpload.single('image_file'), async (req, res) => {
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
    store_url = normalizeUrl(store_url);

    if (req.file) {
      image_url = buildWishlistImagePublicPath(req.file);
    } else {
      image_url = normalizeUrl(image_url);
    }

    if (category_id === '' || category_id === 'none') {
      category_id = await ensureWishlistCategory(familyId);
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

router.post('/wishlist/update/:id', requireLogin, wishlistUpload.single('image_file'), async (req, res) => {
  const user = req.user;
  const userId = user.id;

  try {
    const { familyId, accountId } = await ensureFamilyAndAccountForUser(userId);
    const { id } = req.params;
    const [existingRows] = await pool.execute(
      `
      SELECT image_url
      FROM wishlist
      WHERE id = ?
        AND family_id = ?
        AND account_id = ?
      LIMIT 1
      `,
      [id, familyId, accountId]
    );

    if (existingRows.length === 0) {
      return res.redirect('/wishlist');
    }

    const oldImageUrl = existingRows[0].image_url || null;

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
    store_url = normalizeUrl(store_url);

    if (category_id === '' || category_id === 'none') {
      category_id = await ensureWishlistCategory(familyId);
    }

    priority = ['low', 'medium', 'high'].includes(priority) ? priority : 'medium';
    status = ['planned', 'postponed', 'bought', 'cancelled'].includes(status)
      ? status
      : 'planned';

    const parsedAmount = parseFloat(amount);

    if (!title || Number.isNaN(parsedAmount) || parsedAmount <= 0) {
      return res.redirect(`/wishlist/${id}`);
    }
    if (req.file) {
      image_url = buildWishlistImagePublicPath(req.file);
    } else {
      image_url = normalizeUrl(image_url);
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
    if (req.file && oldImageUrl && oldImageUrl !== image_url) {
      deleteLocalWishlistImage(oldImageUrl);
    }

    await syncWishlistPurchase({
      familyId,
      accountId,
      userId,
      itemId: id,
      status
    });

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

    await syncWishlistPurchase({
      familyId,
      accountId,
      userId,
      itemId: id,
      status
    });

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

    const [rows] = await pool.execute(
      `
      SELECT linked_transaction_id, image_url
      FROM wishlist
      WHERE id = ?
        AND family_id = ?
        AND account_id = ?
      LIMIT 1
      `,
      [id, familyId, accountId]
    );

    if (rows.length > 0 && rows[0].linked_transaction_id) {
      await pool.execute(
        `
        DELETE FROM transactions
        WHERE id = ?
          AND family_id = ?
          AND account_id = ?
        `,
        [rows[0].linked_transaction_id, familyId, accountId]
      );
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
    if (rows.length > 0 && rows[0].image_url) {
      deleteLocalWishlistImage(rows[0].image_url);
    }

    res.redirect('/wishlist');
  } catch (err) {
    logError(err, req, { type: 'wishlist_delete' });

    return res.status(500).render('errors/500', {
      user: req.user || null,
    });
  }
});

module.exports = router;