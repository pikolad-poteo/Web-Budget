const express = require('express');
const session = require('express-session');
const path = require('path');

const checkDatabase = require('./src/checkDatabase');
const { logError, requestLogger, logInfo } = require('./src/logger');
const { attachUser } = require('./src/middleware');

const dashboardRoutes = require('./routes/dashboard.routes');
const authRoutes = require('./routes/auth.routes');
const familyRoutes = require('./routes/family.routes');
const calendarRoutes = require('./routes/calendar.routes');
const transactionsRoutes = require('./routes/transactions.routes');
const wishlistRoutes = require('./routes/wishlist.routes');
const categoriesRoutes = require('./routes/categories.routes');
const systemRoutes = require('./routes/system.routes');

const app = express();

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

app.use(
  session({
    secret: 'super-secret-key',
    resave: false,
    saveUninitialized: false,
  })
);

app.use(requestLogger);
app.use(checkDatabase);
app.use(attachUser);

app.use(dashboardRoutes);
app.use(authRoutes);
app.use(familyRoutes);
app.use(calendarRoutes);
app.use(transactionsRoutes);
app.use(wishlistRoutes);
app.use(categoriesRoutes);
app.use(systemRoutes);

app.use((req, res) => {
  res.status(404).render('errors/404', {
    user: req.user || null,
  });
});

app.use((err, req, res, next) => {
  logError(err, req, { type: 'global_error_handler' });

  res.status(500).render('errors/500', {
    user: req.user || null,
  });
});

const PORT = 3000;
app.listen(PORT, () => {
  logInfo(`Server started on http://localhost:${PORT}`);
  console.log(`Сервер доступен по адресу -> http://localhost:${PORT}`);
});