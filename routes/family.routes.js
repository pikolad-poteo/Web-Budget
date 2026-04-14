const express = require('express');
const router = express.Router();

const pool = require('../src/db');
const { requireLogin } = require('../src/middleware');
const { ensureFamilyAndAccountForUser } = require('../src/auth');
const { logError } = require('../src/logger');

// Сюда переносим все /family...

router.get('/family', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;

  const { familyId } = await ensureFamilyAndAccountForUser(userId);

  const [famRows] = await pool.execute(
    'SELECT name FROM families WHERE id = ? LIMIT 1',
    [familyId]
  );
  const familyName = famRows.length > 0 ? famRows[0].name : '';

  const [members] = await pool.execute(
    `
    SELECT id, name, is_owner
    FROM family_members
    WHERE family_id = ?
    ORDER BY id ASC
    `,
    [familyId]
  );

  const initialMembers =
    members.length > 0
      ? members
      : [{ id: null, name: user.name || user.email, is_owner: 1 }];

  res.render('family/index', {
    user,
    familyName,
    members: initialMembers,
    activePage: 'family',
  });
});

router.post('/family', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;

  const { familyId } = await ensureFamilyAndAccountForUser(userId);

  let { family_name, names, is_owner } = req.body;

  if (!Array.isArray(names)) {
    names = names ? [names] : [];
  }

  if (!Array.isArray(is_owner)) {
    is_owner = typeof is_owner !== 'undefined' ? [is_owner] : [];
  }

  family_name = (family_name || '').trim();
  if (!family_name) {
    family_name = user.name || user.email || 'Наша семья';
  }

  const members = names
    .map((name, index) => ({
      name: String(name || '').trim(),
      is_owner: String(is_owner[index] || '0') === '1' ? 1 : 0,
    }))
    .filter((m) => m.name.length > 0);

  if (members.length === 0) {
    return res.status(400).render('family/index', {
      user,
      familyName: family_name,
      members: [{ id: null, name: user.name || user.email, is_owner: 1 }],
      activePage: 'family',
      message: 'В семье должен быть хотя бы один участник.',
    });
  }

  const ownerMembers = members.filter((m) => m.is_owner === 1);

  if (ownerMembers.length !== 1) {
    return res.status(400).render('family/index', {
      user,
      familyName: family_name,
      members,
      activePage: 'family',
      message: 'В семье должен быть ровно один владелец.',
    });
  }

  const ownerMember = ownerMembers[0];

  try {
    await pool.execute('UPDATE families SET name = ? WHERE id = ?', [
      family_name,
      familyId,
    ]);

    await pool.execute('UPDATE users SET name = ? WHERE id = ?', [
      ownerMember.name,
      userId,
    ]);

    req.user.name = ownerMember.name;

    await pool.execute('DELETE FROM family_members WHERE family_id = ?', [
      familyId,
    ]);

    for (const member of members) {
      await pool.execute(
        `
        INSERT INTO family_members (family_id, user_id, name, is_owner)
        VALUES (?, ?, ?, ?)
        `,
        [familyId, userId, member.name, member.is_owner]
      );
    }

    res.redirect('/');
  } catch (err) {
    logError(err, req, { type: 'save_family' });

    return res.status(500).render('errors/500', {
      user: req.user || null,
    });
  }
});

router.post('/family/delete', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;

  const { familyId } = await ensureFamilyAndAccountForUser(userId);

  if (!familyId) {
    return res.redirect('/');
  }

  try {
    await pool.execute(
      'UPDATE users SET family_id = NULL WHERE id = ?',
      [userId]
    );

    await pool.execute('DELETE FROM families WHERE id = ?', [familyId]);

    res.redirect('/');
  } catch (err) {
    logError(err, req, { type: 'delete_family' });

    return res.status(500).render('errors/500', {
      user: req.user || null,
    });
  }
});

module.exports = router;