const { getUserById } = require('./auth');
const { logError } = require('./logger');

async function attachUser(req, res, next) {
  try {
    if (!req.session?.userId) {
      req.user = null;
      return next();
    }

    const user = await getUserById(req.session.userId);

    if (!user) {
      req.session.userId = null;
      req.user = null;
      return next();
    }

    req.user = user;
    next();
  } catch (err) {
    logError(err, req, { type: 'attach_user_middleware' });
    next(err);
  }
}

function requireLogin(req, res, next) {
  if (!req.session?.userId) {
    return res.redirect('/login');
  }

  next();
}

module.exports = {
  attachUser,
  requireLogin,
};