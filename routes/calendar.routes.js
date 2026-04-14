const express = require('express');
const router = express.Router();

const pool = require('../src/db');
const { requireLogin } = require('../src/middleware');
const { ensureFamilyAndAccountForUser } = require('../src/auth');
const { logError } = require('../src/logger');

// Сюда переносим все /calendar...

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
  const firstWeekday = (firstDayOfMonth.getDay() + 6) % 7;
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

router.get('/calendar', requireLogin, async (req, res) => {
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

router.post('/calendar', requireLogin, async (req, res) => {
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

router.post('/calendar/complete', requireLogin, async (req, res) => {
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

router.post('/calendar/update', requireLogin, async (req, res) => {
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

router.post('/calendar/delete', requireLogin, async (req, res) => {
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

module.exports = router;