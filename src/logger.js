const fs = require('fs');
const path = require('path');
const util = require('util');

const logsDir = path.join(__dirname, '..', 'logs');
const errorLogPath = path.join(logsDir, 'errors.log');
const appLogPath = path.join(logsDir, 'app.log');

function ensureLogsDir() {
  if (!fs.existsSync(logsDir)) {
    fs.mkdirSync(logsDir, { recursive: true });
  }
}

function formatDate(date = new Date()) {
  const yyyy = date.getFullYear();
  const mm = String(date.getMonth() + 1).padStart(2, '0');
  const dd = String(date.getDate()).padStart(2, '0');
  const hh = String(date.getHours()).padStart(2, '0');
  const mi = String(date.getMinutes()).padStart(2, '0');
  const ss = String(date.getSeconds()).padStart(2, '0');
  return `${yyyy}-${mm}-${dd} ${hh}:${mi}:${ss}`;
}

function safeStringify(value) {
  try {
    return JSON.stringify(value, null, 2);
  } catch (err) {
    return util.inspect(value, { depth: 4, breakLength: 120 });
  }
}

function sanitizeBody(body) {
  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    return body || {};
  }

  const hiddenFields = [
    'password',
    'password_hash',
    'confirmPassword',
    'confirm_password',
    'newPassword',
    'new_password',
  ];

  const sanitized = { ...body };

  for (const key of Object.keys(sanitized)) {
    if (hiddenFields.includes(key)) {
      sanitized[key] = '[HIDDEN]';
    }
  }

  return sanitized;
}

function appendToFile(filePath, text) {
  ensureLogsDir();
  fs.appendFile(filePath, text + '\n', (err) => {
    if (err) {
      console.error(`[${formatDate()}] Ошибка записи в лог-файл:`, err);
    }
  });
}

function logInfo(message, meta = {}) {
  const entry = [
    `[${formatDate()}] INFO`,
    message,
    Object.keys(meta).length ? safeStringify(meta) : '',
    '--------------------------------------------------',
  ]
    .filter(Boolean)
    .join('\n');

  appendToFile(appLogPath, entry);
}

function logError(error, req = null, extra = {}) {
  const err = error instanceof Error ? error : new Error(String(error));

  const entryData = {
    time: formatDate(),
    method: req?.method || null,
    url: req?.originalUrl || req?.url || null,
    ip: req?.ip || req?.headers?.['x-forwarded-for'] || null,
    userId: req?.user?.id || req?.session?.userId || null,
    query: req?.query || {},
    params: req?.params || {},
    body: sanitizeBody(req?.body || {}),
    message: err.message,
    stack: err.stack || null,
    extra,
  };

  const entry = [
    `[${entryData.time}] ERROR`,
    `Method: ${entryData.method || '-'}`,
    `URL: ${entryData.url || '-'}`,
    `IP: ${entryData.ip || '-'}`,
    `User ID: ${entryData.userId || '-'}`,
    `Query: ${safeStringify(entryData.query)}`,
    `Params: ${safeStringify(entryData.params)}`,
    `Body: ${safeStringify(entryData.body)}`,
    `Message: ${entryData.message}`,
    `Stack: ${entryData.stack || '-'}`,
    `Extra: ${safeStringify(entryData.extra)}`,
    '--------------------------------------------------',
  ].join('\n');

  appendToFile(errorLogPath, entry);

  console.error(
    `[${entryData.time}] ERROR ${entryData.method || '-'} ${entryData.url || '-'}`,
    {
      message: entryData.message,
      userId: entryData.userId,
      extra: entryData.extra,
    }
  );

  if (entryData.stack) {
    console.error(entryData.stack);
  }
}

function requestLogger(req, res, next) {
  const start = Date.now();

  res.on('finish', () => {
    logInfo('HTTP request', {
      method: req.method,
      url: req.originalUrl || req.url,
      statusCode: res.statusCode,
      durationMs: Date.now() - start,
      userId: req.user?.id || req.session?.userId || null,
      ip: req.ip || req.headers?.['x-forwarded-for'] || null,
    });
  });

  next();
}

module.exports = {
  logInfo,
  logError,
  requestLogger,
};