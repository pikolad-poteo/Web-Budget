const express = require('express');
const router = express.Router();

const {
  registerUser,
  loginUser,
} = require('../src/auth');

// GET /login
router.get('/login', (req, res) => {
  res.render('login', { message: null });
});

// POST /login
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  const result = await loginUser(email, password);
  if (result.error) {
    return res.render('login', { message: result.error });
  }

  req.session.userId = result.user.id;
  return res.redirect('/');
});

// GET /register
router.get('/register', (req, res) => {
  res.render('register', { message: null });
});

// POST /register
router.post('/register', async (req, res) => {
  const { email, password, name } = req.body;
  const result = await registerUser(email, password, name);

  if (result && result.success) {
    req.session.userId = result.userId;
    return res.redirect('/family');
  }

  return res.render('register', {
    message: typeof result === 'string' ? result : 'Ошибка при регистрации.',
  });
});

// GET /logout
router.get('/logout', (req, res) => {
  req.session.destroy(() => {
    res.redirect('/login');
  });
});

module.exports = router;