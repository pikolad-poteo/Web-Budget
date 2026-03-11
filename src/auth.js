// src/auth.js
const bcrypt = require('bcryptjs');
const pool = require('./db');

// ================== РЕГИСТРАЦИЯ ==================
async function registerUser(email, password, name) {
  const conn = await pool.getConnection();

  try {
    await conn.beginTransaction();

    // 1) Проверяем, нет ли уже такого email
    const [userRows] = await conn.execute(
      'SELECT id FROM users WHERE email = ? LIMIT 1',
      [email]
    );

    if (userRows.length > 0) {
      await conn.rollback();
      return 'Пользователь с таким email уже существует.';
    }

    // 2) Хэшируем пароль
    const passwordHash = await bcrypt.hash(password, 10);

    // 3) Создаём пользователя
    const [uRes] = await conn.execute(
      `
        INSERT INTO users (email, password_hash, name)
        VALUES (?, ?, ?)
      `,
      [email, passwordHash, name || null]
    );
    const userId = uRes.insertId;

    // 4) Создаём семью
    const familyName = name || email || 'Наша семья';
    const [fRes] = await conn.execute(
      `
        INSERT INTO families (name)
        VALUES (?)
      `,
      [familyName]
    );
    const familyId = fRes.insertId;

    // Привязываем пользователя к семье
    await conn.execute(
      'UPDATE users SET family_id = ? WHERE id = ?',
      [familyId, userId]
    );

    // 5) Создаём основной счёт для семьи
    const [aRes] = await conn.execute(
      `
        INSERT INTO accounts (family_id, name, is_main)
        VALUES (?, 'Основной счёт', 1)
      `,
      [familyId]
    );
    const accountId = aRes.insertId;

    await conn.commit();

    // Возвращаем подробный результат, чтобы сразу залогинить
    return {
      success: true,
      userId,
      familyId,
      accountId,
    };
  } catch (err) {
    console.error('Error in registerUser:', err);
    await conn.rollback();
    return 'Ошибка при регистрации.';
  } finally {
    conn.release();
  }
}

// ================== ЛОГИН ==================
async function loginUser(email, password) {
  const [rows] = await pool.execute(
    `
      SELECT id, email, password_hash, name
      FROM users
      WHERE email = ?
      LIMIT 1
    `,
    [email]
  );

  if (rows.length === 0) {
    return { error: 'Неверный email или пароль.' };
  }

  const user = rows[0];

  // Сравниваем введённый пароль с хэшем из базы
  const isOk = await bcrypt.compare(password, user.password_hash);
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
}

// ================== СЕМЬЯ / СЧЁТ ==================

// Получить family_id для пользователя
async function getUserFamilyId(userId) {
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
}

// Получить id основного аккаунта семьи
async function getFamilyMainAccountId(familyId) {
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
}

// Гарантировать, что у пользователя есть семья и основной счёт
async function ensureFamilyAndAccountForUser(userId) {
  // читаем пользователя
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

  // если семьи нет — создаём
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

  // ищем основной счёт
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
}

// Получить пользователя по id (для attachUser)
async function getUserById(id) {
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
}

module.exports = {
  registerUser,
  loginUser,
  getUserFamilyId,
  getFamilyMainAccountId,
  ensureFamilyAndAccountForUser,
  getUserById,
};
