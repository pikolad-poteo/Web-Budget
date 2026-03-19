const express = require('express');
const session = require('express-session');
const path = require('path');
const checkDatabase = require('./src/checkDatabase');
const { logError, requestLogger, logInfo } = require('./src/logger');
const {
  registerUser,
  loginUser,
  getUserFamilyId,
  getFamilyMainAccountId,
  ensureFamilyAndAccountForUser,
} = require('./src/auth');
const { attachUser, requireLogin } = require('./src/middleware');
const pool = require('./src/db');

const app = express();

// ================== НАСТРОЙКИ ==================

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

app.use(
  session({
    secret: 'super-secret-key', // в реале вынести в env
    resave: false,
    saveUninitialized: false,
  })
);

// навешиваем текущего пользователя
app.use(requestLogger);
app.use(checkDatabase);
app.use(attachUser);

// ================== РОУТЫ ==================

// ---------- Дашборд ----------
app.get('/', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;

  // гарантируем, что у пользователя есть семья и основной счёт
  const { familyId, accountId } = await ensureFamilyAndAccountForUser(userId);

  // если по каким-то причинам всё равно не получилось — просто отправим на /family
  if (!familyId || !accountId) {
    return res.redirect('/family');
  }

  // 👉 если у семьи ещё нет участников — отправляем на настройку семьи
  const [memberCountRows] = await pool.execute(
    'SELECT COUNT(*) AS cnt FROM family_members WHERE family_id = ?',
    [familyId]
  );
  if (memberCountRows[0].cnt === 0) {
    return res.redirect('/family');
  }

  // Баланс (все транзакции по счёту)
  const [balRows] = await pool.execute(
    `
    SELECT COALESCE(SUM(amount), 0) AS balance
    FROM transactions
    WHERE family_id = ? AND account_id = ?
    `,
    [familyId, accountId]
  );
  const balance = balRows[0].balance;

  // Текущий месяц
  const fromDate = new Date();
  fromDate.setDate(1);
  const toDate = new Date(fromDate.getFullYear(), fromDate.getMonth() + 1, 0);

  const fromStr = fromDate.toISOString().slice(0, 10);
  const toStr = toDate.toISOString().slice(0, 10);

  // Доходы за месяц
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

  // Расходы за месяц (сумма отрицательных)
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
  const expense = expRows[0].expense; // это отрицательное число

  // Расходы по категориям (суммы положительные через -amount)
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

// ---------- Регистрация ----------
app.get('/register', (req, res) => {
  res.render('register', { message: null });
});

app.post('/register', async (req, res) => {
  const { email, password, name } = req.body;
  const result = await registerUser(email, password, name);

  // успешная регистрация
  if (result && result.success) {
    // сразу логиним пользователя
    req.session.userId = result.userId;
    // и отправляем на страницу настройки семьи
    return res.redirect('/family');
  }

  // если result — строка с ошибкой, показываем её
  return res.render('register', {
    message: typeof result === 'string' ? result : 'Ошибка при регистрации.',
  });
});

// ---------- Логин ----------
app.get('/login', (req, res) => {
  res.render('login', { message: null });
});

app.post('/login', async (req, res) => {
  const { email, password } = req.body;

  const result = await loginUser(email, password);
  if (result.error) {
    return res.render('login', { message: result.error });
  }

  req.session.userId = result.user.id;
  res.redirect('/');
});

// ---------- Логаут ----------
app.get('/logout', (req, res) => {
  req.session.destroy(() => {
    res.redirect('/login');
  });
});

// ============ СЕМЬЯ ============

// Страница редактирования семьи (название + участники)
app.get('/family', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;

  // гарантируем наличие семьи и счёта
  const { familyId } = await ensureFamilyAndAccountForUser(userId);

  // имя семьи
  const [famRows] = await pool.execute(
    'SELECT name FROM families WHERE id = ? LIMIT 1',
    [familyId]
  );
  const familyName = famRows.length > 0 ? famRows[0].name : '';

  // участники семьи
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

// Сохранение состава семьи + имени семьи
app.post('/family', requireLogin, async (req, res) => {
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

    // Переименовываем самого пользователя-владельца
    await pool.execute('UPDATE users SET name = ? WHERE id = ?', [
      ownerMember.name,
      userId,
    ]);

    // Обновим req.user в текущем запросе
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

app.post('/family/delete', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;

  const { familyId } = await ensureFamilyAndAccountForUser(userId);

  if (!familyId) {
    return res.redirect('/');
  }

  try {
    // Удаляем ссылку у пользователя на семью
    await pool.execute(
      'UPDATE users SET family_id = NULL WHERE id = ?',
      [userId]
    );

    // Удаляем семью.
    // По внешним ключам каскадно удалятся:
    // family_members, accounts, transactions, семейные categories, hidden_categories
    await pool.execute('DELETE FROM families WHERE id = ?', [familyId]);

    res.redirect('/');
  } catch (err) {
    logError(err, req, { type: 'delete_family' });

    return res.status(500).render('errors/500', {
      user: req.user || null,
    });
  }
});

// ============ КАЛЕНДАРЬ =============

// ============ КАЛЕНДАРЬ ============

function pad2(value) {
  return String(value).padStart(2, '0');
}

function formatDateLocal(date) {
  return `${date.getFullYear()}-${pad2(date.getMonth() + 1)}-${pad2(date.getDate())}`;
}

function formatMonthTitle(date) {
  const months = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
  ];
  return `${months[date.getMonth()]} ${date.getFullYear()}`;
}

function formatHumanDate(dateInput) {
  const date = new Date(`${dateInput}T00:00:00`);
  const monthsGenitive = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
  ];

  return `${date.getDate()} ${monthsGenitive[date.getMonth()]} ${date.getFullYear()}`;
}

function buildMonthMatrix(baseDate, events) {
  const year = baseDate.getFullYear();
  const month = baseDate.getMonth();

  const firstDayOfMonth = new Date(year, month, 1);
  const lastDayOfMonth = new Date(year, month + 1, 0);

  const firstWeekday = (firstDayOfMonth.getDay() + 6) % 7; // Пн=0 ... Вс=6
  const daysInMonth = lastDayOfMonth.getDate();

  const startDate = new Date(year, month, 1 - firstWeekday);

  const eventsMap = {};
  for (const event of events) {
    const key = formatDateLocal(new Date(event.event_date));
    if (!eventsMap[key]) {
      eventsMap[key] = [];
    }
    eventsMap[key].push(event);
  }

  const weeks = [];

  for (let weekIndex = 0; weekIndex < 6; weekIndex++) {
    const week = [];

    for (let dayIndex = 0; dayIndex < 7; dayIndex++) {
      const current = new Date(startDate);
      current.setDate(startDate.getDate() + weekIndex * 7 + dayIndex);

      const dateStr = formatDateLocal(current);

      week.push({
        date: dateStr,
        dayNumber: current.getDate(),
        isCurrentMonth: current.getMonth() === month,
        isToday: dateStr === formatDateLocal(new Date()),
        events: (eventsMap[dateStr] || []).sort((a, b) => {
          if (Number(a.is_completed) !== Number(b.is_completed)) {
            return Number(a.is_completed) - Number(b.is_completed);
          }
          if (Number(a.is_all_day) !== Number(b.is_all_day)) {
            return Number(b.is_all_day) - Number(a.is_all_day);
          }
          return String(a.start_time || '').localeCompare(String(b.start_time || ''));
        }),
      });
    }

    weeks.push(week);
  }

  return weeks;
}

function getEventTypeLabel(type) {
  switch (type) {
    case 'birthday':
      return 'День рождения';
    case 'reminder':
      return 'Напоминание';
    case 'task':
      return 'Задача';
    case 'wishlist_placeholder':
      return 'WishList';
    default:
      return 'Событие';
  }
}

app.get('/calendar', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;

  try {
    const { familyId } = await ensureFamilyAndAccountForUser(userId);

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

    const today = new Date();
    const selectedDateStr = req.query.date || formatDateLocal(today);
    const selectedDate = new Date(`${selectedDateStr}T00:00:00`);
    const view = req.query.view === 'day' ? 'day' : 'month';

    const monthBaseDate = new Date(selectedDate.getFullYear(), selectedDate.getMonth(), 1);
    const monthStart = new Date(monthBaseDate.getFullYear(), monthBaseDate.getMonth(), 1);
    const monthEnd = new Date(monthBaseDate.getFullYear(), monthBaseDate.getMonth() + 1, 0);

    const monthStartStr = formatDateLocal(monthStart);
    const monthEndStr = formatDateLocal(monthEnd);

    const [monthEvents] = await pool.execute(
      `
      SELECT *
      FROM calendar_events
      WHERE family_id = ?
        AND event_date BETWEEN ? AND ?
      ORDER BY event_date ASC, is_completed ASC, is_all_day DESC, start_time ASC, id ASC
      `,
      [familyId, monthStartStr, monthEndStr]
    );

    const [dayEvents] = await pool.execute(
      `
      SELECT *
      FROM calendar_events
      WHERE family_id = ?
        AND event_date = ?
      ORDER BY is_completed ASC, is_all_day DESC, start_time ASC, id ASC
      `,
      [familyId, selectedDateStr]
    );

    const monthMatrix = buildMonthMatrix(monthBaseDate, monthEvents);

    const prevMonthDate = new Date(monthBaseDate.getFullYear(), monthBaseDate.getMonth() - 1, 1);
    const nextMonthDate = new Date(monthBaseDate.getFullYear(), monthBaseDate.getMonth() + 1, 1);

    const prevDayDate = new Date(selectedDate);
    prevDayDate.setDate(prevDayDate.getDate() - 1);

    const nextDayDate = new Date(selectedDate);
    nextDayDate.setDate(nextDayDate.getDate() + 1);

    res.render('calendar/index', {
      user,
      members: memberRows,
      activePage: 'calendar',
      calendarView: view,
      selectedDate: selectedDateStr,
      formattedSelectedDate: formatHumanDate(selectedDateStr),
      monthTitle: formatMonthTitle(monthBaseDate),
      monthMatrix,
      monthEvents,
      dayEvents: dayEvents.map((event) => ({
        ...event,
        event_type_label: getEventTypeLabel(event.event_type),
        is_completed: Number(event.is_completed) === 1,
      })),
      nav: {
        today: formatDateLocal(today),
        prevMonth: formatDateLocal(prevMonthDate),
        nextMonth: formatDateLocal(nextMonthDate),
        prevDay: formatDateLocal(prevDayDate),
        nextDay: formatDateLocal(nextDayDate),
      },
    });
  } catch (err) {
    logError(err, req, { type: 'calendar_index' });

    return res.status(500).render('errors/500', {
      user: req.user || null,
    });
  }
});

app.post('/calendar', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;

  try {
    const { familyId } = await ensureFamilyAndAccountForUser(userId);

    let {
      title,
      description,
      event_type,
      event_date,
      start_time,
      end_time,
      member_name,
      is_all_day,
      is_recurring,
      recurring_type,
      color,
      redirect_view,
    } = req.body;

    title = String(title || '').trim();
    description = String(description || '').trim() || null;
    event_type = String(event_type || 'event').trim();
    event_date = String(event_date || '').trim();
    member_name = String(member_name || '').trim() || null;
    start_time = String(start_time || '').trim() || null;
    end_time = String(end_time || '').trim() || null;
    color = String(color || '#0d6efd').trim() || '#0d6efd';
    redirect_view = redirect_view === 'day' ? 'day' : 'month';

    const allowedTypes = ['event', 'birthday', 'reminder', 'task', 'wishlist_placeholder'];
    const allowedRecurring = ['none', 'daily', 'weekly', 'monthly', 'yearly'];

    if (!title || !event_date) {
      return res.redirect(`/calendar?view=${redirect_view}&date=${encodeURIComponent(event_date || formatDateLocal(new Date()))}`);
    }

    if (!allowedTypes.includes(event_type)) {
      event_type = 'event';
    }

    const allDayValue = String(is_all_day || '0') === '1' ? 1 : 0;
    const recurringValue = String(is_recurring || '0') === '1' ? 1 : 0;

    if (!allowedRecurring.includes(recurring_type)) {
      recurring_type = 'none';
    }

    if (allDayValue) {
      start_time = null;
      end_time = null;
    }

    if (!recurringValue) {
      recurring_type = 'none';
    }

    await pool.execute(
      `
      INSERT INTO calendar_events
        (
          family_id,
          user_id,
          member_name,
          title,
          description,
          event_type,
          event_date,
          start_time,
          end_time,
          is_all_day,
          is_recurring,
          recurring_type,
          color
        )
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `,
      [
        familyId,
        userId,
        member_name,
        title,
        description,
        event_type,
        event_date,
        start_time,
        end_time,
        allDayValue,
        recurringValue,
        recurring_type,
        color,
      ]
    );

    res.redirect(`/calendar?view=${redirect_view}&date=${encodeURIComponent(event_date)}`);
  } catch (err) {
    logError(err, req, { type: 'calendar_create' });

    return res.status(500).render('errors/500', {
      user: req.user || null,
    });
  }
});

app.post('/calendar/complete', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;

  try {
    const { familyId } = await ensureFamilyAndAccountForUser(userId);
    const { id, redirect_view, redirect_date } = req.body;

    if (!id) {
      return res.redirect('/calendar');
    }

    await pool.execute(
      `
      UPDATE calendar_events
      SET
        is_completed = CASE WHEN is_completed = 1 THEN 0 ELSE 1 END,
        completed_at = CASE
          WHEN is_completed = 1 THEN NULL
          ELSE NOW()
        END
      WHERE id = ? AND family_id = ?
      `,
      [id, familyId]
    );

    const safeView = redirect_view === 'day' ? 'day' : 'month';
    const safeDate = redirect_date || formatDateLocal(new Date());

    res.redirect(`/calendar?view=${safeView}&date=${encodeURIComponent(safeDate)}`);
  } catch (err) {
    logError(err, req, { type: 'calendar_complete' });

    return res.status(500).render('errors/500', {
      user: req.user || null,
    });
  }
});

app.post('/calendar/update', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;

  try {
    const { familyId } = await ensureFamilyAndAccountForUser(userId);

    let {
      id,
      title,
      description,
      event_type,
      event_date,
      start_time,
      end_time,
      member_name,
      is_all_day,
      is_recurring,
      recurring_type,
      color,
      redirect_view,
    } = req.body;

    if (!id) {
      return res.redirect('/calendar');
    }

    title = String(title || '').trim();
    description = String(description || '').trim() || null;
    event_type = String(event_type || 'event').trim();
    event_date = String(event_date || '').trim();
    member_name = String(member_name || '').trim() || null;
    start_time = String(start_time || '').trim() || null;
    end_time = String(end_time || '').trim() || null;
    color = String(color || '#0d6efd').trim() || '#0d6efd';
    redirect_view = redirect_view === 'day' ? 'day' : 'month';

    const allowedTypes = ['event', 'birthday', 'reminder', 'task', 'wishlist_placeholder'];
    const allowedRecurring = ['none', 'daily', 'weekly', 'monthly', 'yearly'];

    if (!title || !event_date) {
      return res.redirect(`/calendar?view=${redirect_view}&date=${encodeURIComponent(event_date || formatDateLocal(new Date()))}`);
    }

    if (!allowedTypes.includes(event_type)) {
      event_type = 'event';
    }

    const allDayValue = String(is_all_day || '0') === '1' ? 1 : 0;
    const recurringValue = String(is_recurring || '0') === '1' ? 1 : 0;

    if (!allowedRecurring.includes(recurring_type)) {
      recurring_type = 'none';
    }

    if (allDayValue) {
      start_time = null;
      end_time = null;
    }

    if (!recurringValue) {
      recurring_type = 'none';
    }

    await pool.execute(
      `
      UPDATE calendar_events
      SET
        member_name = ?,
        title = ?,
        description = ?,
        event_type = ?,
        event_date = ?,
        start_time = ?,
        end_time = ?,
        is_all_day = ?,
        is_recurring = ?,
        recurring_type = ?,
        color = ?
      WHERE id = ? AND family_id = ?
      `,
      [
        member_name,
        title,
        description,
        event_type,
        event_date,
        start_time,
        end_time,
        allDayValue,
        recurringValue,
        recurring_type,
        color,
        id,
        familyId,
      ]
    );

    res.redirect(`/calendar?view=${redirect_view}&date=${encodeURIComponent(event_date)}`);
  } catch (err) {
    logError(err, req, { type: 'calendar_update' });

    return res.status(500).render('errors/500', {
      user: req.user || null,
    });
  }
});

app.post('/calendar/delete', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;

  try {
    const { familyId } = await ensureFamilyAndAccountForUser(userId);
    const { id, redirect_view, redirect_date } = req.body;

    if (!id) {
      return res.redirect('/calendar');
    }

    await pool.execute(
      `
      DELETE FROM calendar_events
      WHERE id = ? AND family_id = ?
      `,
      [id, familyId]
    );

    const safeView = redirect_view === 'day' ? 'day' : 'month';
    const safeDate = redirect_date || formatDateLocal(new Date());

    res.redirect(`/calendar?view=${safeView}&date=${encodeURIComponent(safeDate)}`);
  } catch (err) {
    logError(err, req, { type: 'calendar_delete' });

    return res.status(500).render('errors/500', {
      user: req.user || null,
    });
  }
});

// ============ ТРАНЗАКЦИИ ============

// Страница со списком и формой
app.get('/transactions', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;

  const { familyId, accountId } = await ensureFamilyAndAccountForUser(userId);

  // участники семьи
  const [memberRows] = await pool.execute(
    `
    SELECT id, name
    FROM family_members
    WHERE family_id = ?
    ORDER BY id ASC
    `,
    [familyId]
  );

  // если нет участников, отправляем на /family
  if (memberRows.length === 0) {
    return res.redirect('/family');
  }

  const { from, to, category_id } = req.query;

  let fromDate = from || null;
  let toDate = to || null;

  // по умолчанию текущий месяц
  if (!fromDate || !toDate) {
    const d = new Date();
    const first = new Date(d.getFullYear(), d.getMonth(), 1);
    const last = new Date(d.getFullYear(), d.getMonth() + 1, 0);
    fromDate = fromDate || first.toISOString().slice(0, 10);
    toDate = toDate || last.toISOString().slice(0, 10);
  }

  // категории семьи (и общие)
  const [catRows] = await pool.execute(
    `
    SELECT *
    FROM categories
    WHERE family_id = ? OR family_id IS NULL
    ORDER BY name ASC
    `,
    [familyId]
  );

  // транзакции
  let query = `
    SELECT
      t.*,
      c.name  AS category_name,
      c.color AS category_color,
      c.icon  AS category_icon
    FROM transactions t
    JOIN categories c ON c.id = t.category_id
    WHERE t.family_id = ?
      AND t.account_id = ?
      AND t.date BETWEEN ? AND ?
  `;
  const params = [familyId, accountId, fromDate, toDate];

  if (category_id && category_id !== 'all') {
    query += ' AND t.category_id = ?';
    params.push(category_id);
  }

  query += ' ORDER BY t.date DESC, t.id DESC';

  const [txRows] = await pool.execute(query, params);

  res.render('transactions/index', {
    user,
    transactions: txRows,
    categories: catRows,
    members: memberRows,
    filters: {
      from: fromDate,
      to: toDate,
      category_id: category_id || 'all',
    },
    activePage: 'transactions',
  });
});

// Добавление новой транзакции
app.post('/transactions', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;

  const { familyId, accountId } = await ensureFamilyAndAccountForUser(userId);

  const { date, amount, category_id, description, type, who } = req.body;

  let value = parseFloat(amount);
  if (type === 'expense' && value > 0) {
    value = -value;
  }

  const whoValue = (who || '').trim() || null;

  await pool.execute(
    `
    INSERT INTO transactions
      (family_id, account_id, user_id, category_id, amount, date, description, who)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `,
    [familyId, accountId, userId, category_id, value, date, description || null, whoValue]
  );

  res.redirect('/transactions');
});

// ============ КАТЕГОРИИ ============

// Страница категорий
app.get('/categories', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;

  const { familyId } = await ensureFamilyAndAccountForUser(userId);

  // Берём общие категории (family_id IS NULL) и категории этой семьи,
  // но исключаем те базовые, которые семья "спрятала" в hidden_categories
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

// Добавление новой категории
app.post('/categories', requireLogin, async (req, res) => {
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

  // Проверяем, существует ли уже категория
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
    // Загружаем категории, чтобы отрисовать страницу корректно
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

  // Создание категории
  await pool.execute(
    `
    INSERT INTO categories (family_id, name, type, color, icon)
    VALUES (?, ?, ?, ?, ?)
    `,
    [familyId, name, type, color, icon]
  );

  res.redirect('/categories');
});

// ---------- КАТЕГОРИИ: обновление ----------
app.post('/categories/update', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;
  const { familyId } = await ensureFamilyAndAccountForUser(userId);

  let { id, name, type, color, icon } = req.body;

  if (!id) {
    return res.redirect('/categories');
  }

  // Загружаем текущую категорию
  const [catRows] = await pool.execute(
    'SELECT * FROM categories WHERE id = ? LIMIT 1',
    [id]
  );

  if (catRows.length === 0) {
    return res.redirect('/categories');
  }

  const category = catRows[0];

  // Нормализуем поля
  name = (name || '').trim();
  type = type === 'income' ? 'income' : 'expense';
  color = color || '#cccccc';
  icon = icon || 'bi-tag';

  if (!name) {
    return res.redirect('/categories');
  }

  // Проверяем, не превращаем ли в дубль другой категории (имя+тип)
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
    // Загружаем список категорий (с учётом скрытых) и показываем сообщение
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

  // Если категория базовая (общая) -> делаем "свою" копию
  if (category.family_id === null) {
    // 1) создаём новую категорию для этой семьи
    const [insertRes] = await pool.execute(
      `
      INSERT INTO categories (family_id, name, type, color, icon)
      VALUES (?, ?, ?, ?, ?)
      `,
      [familyId, name, type, color, icon]
    );
    const newId = insertRes.insertId;

    // 2) все транзакции этой семьи переводим на новую категорию
    await pool.execute(
      `
      UPDATE transactions
      SET category_id = ?
      WHERE family_id = ? AND category_id = ?
      `,
      [newId, familyId, id]
    );

    // 3) прячем базовую категорию для этой семьи
    await pool.execute(
      `
      INSERT IGNORE INTO hidden_categories (family_id, category_id)
      VALUES (?, ?)
      `,
      [familyId, id]
    );
  } else if (category.family_id === familyId) {
    // Обычное обновление своей категории
    await pool.execute(
      `
      UPDATE categories
      SET name = ?, type = ?, color = ?, icon = ?
      WHERE id = ? AND family_id = ?
      `,
      [name, type, color, icon, id, familyId]
    );
  } else {
    // На всякий случай: чужие семейные категории редактировать нельзя
    return res.redirect('/categories');
  }

  res.redirect('/categories');
});

// ---------- КАТЕГОРИИ: удаление ----------
app.post('/categories/delete', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;
  const { familyId } = await ensureFamilyAndAccountForUser(userId);

  const { id } = req.body;
  if (!id) return res.redirect('/categories');

  try {
    // Узнаём, чья это категория
    const [rows] = await pool.execute(
      'SELECT id, family_id FROM categories WHERE id = ? LIMIT 1',
      [id]
    );

    if (rows.length === 0) {
      // Ничего не нашли — просто назад
      return res.redirect('/categories');
    }

    const category = rows[0];

    // Сначала ВСЕГДА чистим транзакции этой семьи по этой категории
    await pool.execute(
      `
      DELETE FROM transactions
      WHERE family_id = ? AND category_id = ?
      `,
      [familyId, id]
    );

    if (category.family_id === familyId) {
      // Своя семейная категория — реально удаляем из categories
      await pool.execute(
        `
        DELETE FROM categories
        WHERE id = ? AND family_id = ?
        `,
        [id, familyId]
      );
    } else {
      // Базовая (общая) категория — просто "прячем" для этой семьи
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

// ============ ОЧИСТКА ДАННЫХ СЕМЬИ ============

app.post('/reset-data', requireLogin, async (req, res) => {
  const user = req.user;
  const userId = user.id;

  const { familyId } = await ensureFamilyAndAccountForUser(userId);
  if (!familyId) {
    return res.redirect('/');
  }

  try {
    // 1) Удаляем ВСЕ транзакции семьи
    await pool.execute('DELETE FROM transactions WHERE family_id = ?', [
      familyId,
    ]);

    // 2) Удаляем пользовательские категории семьи
    await pool.execute('DELETE FROM categories WHERE family_id = ?', [
      familyId,
    ]);

    // 3) Сбрасываем скрытые базовые категории — после ресета они снова будут видны
    await pool.execute('DELETE FROM hidden_categories WHERE family_id = ?', [
      familyId,
    ]);

    res.redirect('/');
    } catch (err) {
    logError(err, req, { type: 'reset_family_data' });

    return res.status(500).render('errors/500', {
      user: req.user || null,
    });
  }
});

// ==================== ОБРАБОТЧИКИ ===========================

// 404 — если ни один маршрут не подошёл
app.use((req, res) => {
  res.status(404).render('errors/404', {
    user: req.user || null,
  });
});

// глобальный обработчик ошибок
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
