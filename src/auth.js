const bcrypt = require('bcryptjs');
const pool = require('./db');
const { logError } = require('./logger');

// ================== РЕГИСТРАЦИЯ ==================
async function registerUser(email, password, name) {
  let conn;

  try {
    conn = await pool.getConnection();
    await conn.beginTransaction();

    const normalizedEmail = String(email || '').trim().toLowerCase();
    const normalizedName = name ? String(name).trim() : null;

    const [userRows] = await conn.execute(
      'SELECT id FROM users WHERE email = ? LIMIT 1',
      [normalizedEmail]
    );

    if (userRows.length > 0) {
      await conn.rollback();
      return 'Пользователь с таким email уже существует.';
    }

    const passwordHash = await bcrypt.hash(String(password || ''), 10);

    const [uRes] = await conn.execute(
      `
        INSERT INTO users (email, password_hash, name)
        VALUES (?, ?, ?)
      `,
      [normalizedEmail, passwordHash, normalizedName]
    );
    const userId = uRes.insertId;

    const familyName = normalizedName || normalizedEmail || 'Наша семья';
    const [fRes] = await conn.execute(
      `
        INSERT INTO families (name)
        VALUES (?)
      `,
      [familyName]
    );
    const familyId = fRes.insertId;

    await conn.execute(
      'UPDATE users SET family_id = ? WHERE id = ?',
      [familyId, userId]
    );

    const [aRes] = await conn.execute(
      `
        INSERT INTO accounts (family_id, name, is_main)
        VALUES (?, 'Основной счёт', 1)
      `,
      [familyId]
    );
    const accountId = aRes.insertId;

    await conn.commit();

    return {
      success: true,
      userId,
      familyId,
      accountId,
    };
  } catch (err) {
    logError(err, null, { type: 'register_user' });

    if (conn) {
      try {
        await conn.rollback();
      } catch (rollbackErr) {
        logError(rollbackErr, null, { type: 'register_user_rollback' });
      }
    }

    return 'Ошибка при регистрации.';
  } finally {
    if (conn) {
      conn.release();
    }
  }
}

// ================== ЛОГИН ==================
async function loginUser(email, password) {
  try {
    const normalizedEmail = String(email || '').trim().toLowerCase();

    const [rows] = await pool.execute(
      `
        SELECT id, email, password_hash, name
        FROM users
        WHERE email = ?
        LIMIT 1
      `,
      [normalizedEmail]
    );

    if (rows.length === 0) {
      return { error: 'Неверный email или пароль.' };
    }

    const user = rows[0];

    const isOk = await bcrypt.compare(String(password || ''), user.password_hash);
    if (!isOk) {
      return { error: 'Неверный email или пароль.' };
    }

    return {
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
      },
    };
  } catch (err) {
    logError(err, null, { type: 'login_user' });
    return { error: 'Ошибка входа. Попробуйте позже.' };
  }
}

// ================== СЕМЬЯ / СЧЁТ ==================

async function getUserFamilyId(userId) {
  try {
    const [rows] = await pool.execute(
      `
        SELECT family_id
        FROM users
        WHERE id = ?
        LIMIT 1
      `,
      [userId]
    );

    if (rows.length === 0) {
      return null;
    }

    return rows[0].family_id;
  } catch (err) {
    logError(err, null, { type: 'get_user_family_id', userId });
    throw err;
  }
}

async function getFamilyMainAccountId(familyId) {
  try {
    const [rows] = await pool.execute(
      `
        SELECT id
        FROM accounts
        WHERE family_id = ?
          AND is_main = 1
        LIMIT 1
      `,
      [familyId]
    );

    if (rows.length === 0) {
      return null;
    }

    return rows[0].id;
  } catch (err) {
    logError(err, null, { type: 'get_family_main_account_id', familyId });
    throw err;
  }
}

async function ensureFamilyAndAccountForUser(userId) {
  try {
    const [userRows] = await pool.execute(
      `
        SELECT id, email, name, family_id
        FROM users
        WHERE id = ?
        LIMIT 1
      `,
      [userId]
    );

    if (userRows.length === 0) {
      return { familyId: null, accountId: null };
    }

    const user = userRows[0];
    let familyId = user.family_id;

    if (!familyId) {
      const familyName = user.name || user.email || 'Наша семья';
      const [fRes] = await pool.execute(
        `
          INSERT INTO families (name)
          VALUES (?)
        `,
        [familyName]
      );
      familyId = fRes.insertId;

      await pool.execute(
        'UPDATE users SET family_id = ? WHERE id = ?',
        [familyId, userId]
      );
    }

    let accountId = null;

    const [accRows] = await pool.execute(
      `
        SELECT id
        FROM accounts
        WHERE family_id = ?
          AND is_main = 1
        LIMIT 1
      `,
      [familyId]
    );

    if (accRows.length > 0) {
      accountId = accRows[0].id;
    } else {
      const [aRes] = await pool.execute(
        `
          INSERT INTO accounts (family_id, name, is_main)
          VALUES (?, 'Основной счёт', 1)
        `,
        [familyId]
      );
      accountId = aRes.insertId;
    }

    return { familyId, accountId };
  } catch (err) {
    logError(err, null, { type: 'ensure_family_and_account_for_user', userId });
    throw err;
  }
}

async function getUserById(id) {
  try {
    const [rows] = await pool.execute(
      `
        SELECT id, email, name
        FROM users
        WHERE id = ?
        LIMIT 1
      `,
      [id]
    );

    if (rows.length === 0) {
      return null;
    }

    return rows[0];
  } catch (err) {
    logError(err, null, { type: 'get_user_by_id', userId: id });
    throw err;
  }
}

module.exports = {
  registerUser,
  loginUser,
  getUserFamilyId,
  getFamilyMainAccountId,
  ensureFamilyAndAccountForUser,
  getUserById,
};