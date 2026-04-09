-- =========================================================
-- WEB BUDGET — FULL RESET SQL
-- Полный сброс и пересоздание базы данных с расширенными тестовыми данными
-- Включены тестовые данные по всем разделам, кроме дополнительных аккаунтов
-- Пароль для всех пользователей: 123
-- =========================================================

DROP DATABASE IF EXISTS web_budget;
CREATE DATABASE web_budget
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE web_budget;

SET NAMES utf8mb4;
SET time_zone = '+00:00';

-- =========================================================
-- 1. TABLES
-- =========================================================

CREATE TABLE families (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE users (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  email VARCHAR(255) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  name VARCHAR(255) DEFAULT NULL,
  family_id INT UNSIGNED DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email),
  KEY idx_users_family_id (family_id),
  CONSTRAINT fk_users_family
    FOREIGN KEY (family_id) REFERENCES families(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE accounts (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  family_id INT UNSIGNED NOT NULL,
  name VARCHAR(255) NOT NULL,
  is_main TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_accounts_family_id (family_id),
  KEY idx_accounts_family_main (family_id, is_main),
  CONSTRAINT fk_accounts_family
    FOREIGN KEY (family_id) REFERENCES families(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE calendar_events (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  family_id INT UNSIGNED NOT NULL,
  user_id INT UNSIGNED NOT NULL,
  member_name VARCHAR(255) DEFAULT NULL,
  title VARCHAR(255) NOT NULL,
  description VARCHAR(1000) DEFAULT NULL,
  event_type ENUM('event','birthday','reminder','task','wishlist_placeholder') NOT NULL DEFAULT 'event',
  event_date DATE NOT NULL,
  start_time TIME DEFAULT NULL,
  end_time TIME DEFAULT NULL,
  is_all_day TINYINT(1) NOT NULL DEFAULT 0,
  is_recurring TINYINT(1) NOT NULL DEFAULT 0,
  recurring_type ENUM('none','daily','weekly','monthly','yearly') NOT NULL DEFAULT 'none',
  color VARCHAR(20) NOT NULL DEFAULT '#0d6efd',
  is_completed TINYINT(1) NOT NULL DEFAULT 0,
  completed_at DATETIME DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_calendar_events_family_date (family_id, event_date),
  KEY idx_calendar_events_user_id (user_id),
  KEY idx_calendar_events_type (event_type),
  KEY idx_calendar_events_completed (family_id, event_date, is_completed),
  CONSTRAINT fk_calendar_events_family
    FOREIGN KEY (family_id) REFERENCES families(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_calendar_events_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE categories (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  family_id INT UNSIGNED DEFAULT NULL,
  name VARCHAR(255) NOT NULL,
  type ENUM('income','expense') NOT NULL DEFAULT 'expense',
  color VARCHAR(20) NOT NULL DEFAULT '#cccccc',
  icon VARCHAR(100) NOT NULL DEFAULT 'bi-tag',
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_categories_family_id (family_id),
  KEY idx_categories_family_type (family_id, type),
  KEY idx_categories_name (name),
  CONSTRAINT fk_categories_family
    FOREIGN KEY (family_id) REFERENCES families(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE family_members (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  family_id INT UNSIGNED NOT NULL,
  user_id INT UNSIGNED NOT NULL,
  name VARCHAR(255) NOT NULL,
  is_owner TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_family_members_family_id (family_id),
  KEY idx_family_members_user_id (user_id),
  CONSTRAINT fk_family_members_family
    FOREIGN KEY (family_id) REFERENCES families(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_family_members_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE hidden_categories (
  family_id INT UNSIGNED NOT NULL,
  category_id INT UNSIGNED NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (family_id, category_id),
  KEY idx_hidden_categories_category_id (category_id),
  CONSTRAINT fk_hidden_categories_category
    FOREIGN KEY (category_id) REFERENCES categories(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_hidden_categories_family
    FOREIGN KEY (family_id) REFERENCES families(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE transactions (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  family_id INT UNSIGNED NOT NULL,
  account_id INT UNSIGNED NOT NULL,
  user_id INT UNSIGNED NOT NULL,
  category_id INT UNSIGNED NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  date DATE NOT NULL,
  description VARCHAR(500) DEFAULT NULL,
  who VARCHAR(255) DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_transactions_family_id (family_id),
  KEY idx_transactions_account_id (account_id),
  KEY idx_transactions_user_id (user_id),
  KEY idx_transactions_category_id (category_id),
  KEY idx_transactions_date (date),
  KEY idx_transactions_family_account_date (family_id, account_id, date),
  CONSTRAINT fk_transactions_account
    FOREIGN KEY (account_id) REFERENCES accounts(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_transactions_category
    FOREIGN KEY (category_id) REFERENCES categories(id)
    ON UPDATE CASCADE,
  CONSTRAINT fk_transactions_family
    FOREIGN KEY (family_id) REFERENCES families(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_transactions_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE wishlist (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  family_id INT UNSIGNED NOT NULL,
  account_id INT UNSIGNED NOT NULL,
  user_id INT UNSIGNED NOT NULL,
  category_id INT UNSIGNED NOT NULL,
  title VARCHAR(255) NOT NULL,
  description VARCHAR(500) DEFAULT NULL,
  amount DECIMAL(12,2) NOT NULL,
  planned_date DATE DEFAULT NULL,
  priority ENUM('low','medium','high') NOT NULL DEFAULT 'medium',
  status ENUM('planned','postponed','bought','cancelled') NOT NULL DEFAULT 'planned',
  who VARCHAR(255) DEFAULT NULL,
  linked_transaction_id INT UNSIGNED DEFAULT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_wishlist_family_id (family_id),
  KEY idx_wishlist_account_id (account_id),
  KEY idx_wishlist_user_id (user_id),
  KEY idx_wishlist_category_id (category_id),
  KEY idx_wishlist_planned_date (planned_date),
  KEY idx_wishlist_status (status),
  KEY fk_wishlist_transaction (linked_transaction_id),
  CONSTRAINT fk_wishlist_account
    FOREIGN KEY (account_id) REFERENCES accounts(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_wishlist_category
    FOREIGN KEY (category_id) REFERENCES categories(id)
    ON UPDATE CASCADE,
  CONSTRAINT fk_wishlist_family
    FOREIGN KEY (family_id) REFERENCES families(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_wishlist_transaction
    FOREIGN KEY (linked_transaction_id) REFERENCES transactions(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT fk_wishlist_user
    FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =========================================================
-- 2. BASE DATA
-- =========================================================

INSERT INTO families (id, name, created_at) VALUES
  (1, 'Семья администратора', '2026-04-09 09:40:56'),
  (2, 'Семья пользователя', '2026-04-09 09:40:56'),
  (3, 'Тестовая семья календаря', '2026-04-09 09:40:56');

INSERT INTO users (id, email, password_hash, name, family_id, created_at) VALUES
  (1, 'admin@myshop.local', '$2b$12$pFOZ5wBSN4v0euitgr9yIuclcpFlw2keJMt/MQReIgbhpbIUiXlVa', 'Админ', 1, '2026-04-09 09:40:56'),
  (2, 'user@myshop.local', '$2b$12$pFOZ5wBSN4v0euitgr9yIuclcpFlw2keJMt/MQReIgbhpbIUiXlVa', 'Пользователь', 2, '2026-04-09 09:40:56'),
  (3, 'calendar@myshop.local', '$2b$12$pFOZ5wBSN4v0euitgr9yIuclcpFlw2keJMt/MQReIgbhpbIUiXlVa', 'Пользователь', 3, '2026-04-09 09:40:56');

-- Оставляем по одному основному счёту на семью, без доп. тестовых аккаунтов
INSERT INTO accounts (id, family_id, name, is_main, created_at) VALUES
  (1, 1, 'Основной счёт', 1, '2026-04-09 09:40:56'),
  (2, 2, 'Основной счёт', 1, '2026-04-09 09:40:56'),
  (3, 3, 'Основной счёт', 1, '2026-04-09 09:40:56');

INSERT INTO family_members (id, family_id, user_id, name, is_owner, created_at) VALUES
  (1, 1, 1, 'Админ', 1, '2026-04-09 09:40:56'),
  (2, 1, 1, 'Мария', 0, '2026-04-09 09:40:56'),
  (3, 1, 1, 'София', 0, '2026-04-09 09:40:56'),
  (4, 2, 2, 'Пользователь', 1, '2026-04-09 09:40:56'),
  (5, 2, 2, 'Анна', 0, '2026-04-09 09:40:56'),
  (6, 3, 3, 'Пользователь', 1, '2026-04-09 09:40:56'),
  (7, 3, 3, 'Илья', 0, '2026-04-09 09:40:56');

INSERT INTO categories (id, family_id, name, type, color, icon, created_at) VALUES
  (1, NULL, 'Продукты', 'expense', '#4CAF50', 'bi-cart', '2026-04-09 09:40:56'),
  (2, NULL, 'Кафе и рестораны', 'expense', '#FF9800', 'bi-cup-hot', '2026-04-09 09:40:56'),
  (3, NULL, 'Транспорт', 'expense', '#2196F3', 'bi-bus-front', '2026-04-09 09:40:56'),
  (4, NULL, 'Топливо', 'expense', '#795548', 'bi-fuel-pump', '2026-04-09 09:40:56'),
  (5, NULL, 'Дом и коммуналка', 'expense', '#9C27B0', 'bi-house-door', '2026-04-09 09:40:56'),
  (6, NULL, 'Интернет и связь', 'expense', '#3F51B5', 'bi-wifi', '2026-04-09 09:40:56'),
  (7, NULL, 'Здоровье', 'expense', '#E91E63', 'bi-heart-pulse', '2026-04-09 09:40:56'),
  (8, NULL, 'Одежда', 'expense', '#607D8B', 'bi-bag', '2026-04-09 09:40:56'),
  (9, NULL, 'Развлечения', 'expense', '#FFC107', 'bi-controller', '2026-04-09 09:40:56'),
  (10, NULL, 'Подарки', 'expense', '#F44336', 'bi-gift', '2026-04-09 09:40:56'),
  (11, NULL, 'Путешествия', 'expense', '#00BCD4', 'bi-airplane', '2026-04-09 09:40:56'),
  (12, NULL, 'Образование', 'expense', '#8BC34A', 'bi-mortarboard', '2026-04-09 09:40:56'),
  (13, NULL, 'Ремонт', 'expense', '#9E9E9E', 'bi-hammer', '2026-04-09 09:40:56'),
  (14, NULL, 'Питомцы', 'expense', '#673AB7', 'bi-suit-heart-fill', '2026-04-09 09:40:56'),
  (15, NULL, 'Прочее', 'expense', '#BDBDBD', 'bi-tag', '2026-04-09 09:40:56'),
  (16, NULL, 'Зарплата', 'income', '#2E7D32', 'bi-cash-coin', '2026-04-09 09:40:56'),
  (17, NULL, 'Подработка', 'income', '#388E3C', 'bi-briefcase', '2026-04-09 09:40:56'),
  (18, NULL, 'Подарок', 'income', '#7CB342', 'bi-gift', '2026-04-09 09:40:56'),
  (19, NULL, 'Возврат', 'income', '#689F38', 'bi-arrow-repeat', '2026-04-09 09:40:56'),
  (20, NULL, 'Прочий доход', 'income', '#558B2F', 'bi-piggy-bank', '2026-04-09 09:40:56'),
  (21, 1, 'Детские расходы', 'expense', '#FF6F61', 'bi-emoji-smile', '2026-04-09 09:40:56'),
  (22, 1, 'Накопления', 'income', '#009688', 'bi-piggy-bank', '2026-04-09 09:40:56'),
  (23, 2, 'Домашние покупки', 'expense', '#FF7043', 'bi-basket', '2026-04-09 09:40:56'),
  (24, 2, 'Фриланс', 'income', '#26A69A', 'bi-laptop', '2026-04-09 09:40:56'),
  (25, 3, 'Учёба ребёнка', 'expense', '#AB47BC', 'bi-journal-bookmark', '2026-04-09 09:40:56'),
  (26, 3, 'Семейные накопления', 'income', '#26C6DA', 'bi-safe', '2026-04-09 09:40:56');

INSERT INTO hidden_categories (family_id, category_id, created_at) VALUES
  (1, 15, '2026-04-09 09:40:56'),
  (2, 9, '2026-04-09 09:40:56'),
  (3, 25, '2026-04-09 09:40:56');

-- =========================================================
-- 3. TRANSACTIONS
-- Покрыты все основные категории и семейные категории
-- =========================================================

INSERT INTO transactions (id, family_id, account_id, user_id, category_id, amount, date, description, who, created_at) VALUES
  (1, 1, 1, 1, 16, 75000.00, '2026-03-01', 'Зарплата за март', 'Админ', '2026-04-09 09:40:56'),
  (2, 1, 1, 1, 17, 12000.00, '2026-03-03', 'Подработка по сайту', 'Админ', '2026-04-09 09:40:56'),
  (3, 1, 1, 1, 22, 5000.00, '2026-03-04', 'Перевод в накопления', 'Админ', '2026-04-09 09:40:56'),
  (4, 1, 1, 1, 1, -6500.00, '2026-03-02', 'Закупка продуктов', 'Мария', '2026-04-09 09:40:56'),
  (5, 1, 1, 1, 2, -2100.00, '2026-03-04', 'Семейное кафе', 'Админ', '2026-04-09 09:40:56'),
  (6, 1, 1, 1, 3, -1200.00, '2026-03-05', 'Метро и автобус', 'Мария', '2026-04-09 09:40:56'),
  (7, 1, 1, 1, 4, -3000.00, '2026-03-06', 'Заправка машины', 'Админ', '2026-04-09 09:40:56'),
  (8, 1, 1, 1, 5, -9500.00, '2026-03-07', 'Коммунальные услуги', 'Админ', '2026-04-09 09:40:56'),
  (9, 1, 1, 1, 6, -1400.00, '2026-03-08', 'Интернет и мобильная связь', 'Мария', '2026-04-09 09:40:56'),
  (10, 1, 1, 1, 7, -2200.00, '2026-03-09', 'Аптека', 'Мария', '2026-04-09 09:40:56'),
  (11, 1, 1, 1, 8, -4800.00, '2026-03-10', 'Одежда', 'Мария', '2026-04-09 09:40:56'),
  (12, 1, 1, 1, 9, -1600.00, '2026-03-11', 'Кино и игры', 'Админ', '2026-04-09 09:40:56'),
  (13, 1, 1, 1, 10, -2500.00, '2026-03-12', 'Подарок бабушке', 'Админ', '2026-04-09 09:40:56'),
  (14, 1, 1, 1, 21, -3900.00, '2026-03-13', 'Товары для ребёнка', 'София', '2026-04-09 09:40:56'),
  (15, 1, 1, 1, 11, -14000.00, '2026-03-14', 'Бронь загородного отеля', 'Админ', '2026-04-09 09:40:56'),
  (16, 1, 1, 1, 12, -3200.00, '2026-03-15', 'Курсы английского', 'Мария', '2026-04-09 09:40:56'),
  (17, 1, 1, 1, 13, -8900.00, '2026-03-16', 'Инструменты и краска', 'Админ', '2026-04-09 09:40:56'),
  (18, 1, 1, 1, 14, -1700.00, '2026-03-17', 'Корм и наполнитель', 'Мария', '2026-04-09 09:40:56'),
  (19, 1, 1, 1, 15, -950.00, '2026-03-18', 'Непредвиденные мелочи', 'Админ', '2026-04-09 09:40:56'),
  (20, 1, 1, 1, 18, 5000.00, '2026-03-20', 'Подарок деньгами на праздник', 'Мария', '2026-04-09 09:40:56'),
  (21, 1, 1, 1, 19, 1350.00, '2026-03-21', 'Возврат за отменённый заказ', 'Админ', '2026-04-09 09:40:56'),
  (22, 1, 1, 1, 20, 2700.00, '2026-03-22', 'Продажа старого кресла', 'Админ', '2026-04-09 09:40:56'),

  (23, 2, 2, 2, 16, 42000.00, '2026-03-01', 'Основной доход', 'Пользователь', '2026-04-09 09:40:56'),
  (24, 2, 2, 2, 24, 8000.00, '2026-03-02', 'Фриланс заказ', 'Пользователь', '2026-04-09 09:40:56'),
  (25, 2, 2, 2, 1, -4300.00, '2026-03-03', 'Продукты домой', 'Анна', '2026-04-09 09:40:56'),
  (26, 2, 2, 2, 23, -2700.00, '2026-03-04', 'Домашние мелочи', 'Пользователь', '2026-04-09 09:40:56'),
  (27, 2, 2, 2, 3, -900.00, '2026-03-05', 'Транспорт', 'Пользователь', '2026-04-09 09:40:56'),
  (28, 2, 2, 2, 2, -1100.00, '2026-03-06', 'Кафе', 'Анна', '2026-04-09 09:40:56'),
  (29, 2, 2, 2, 7, -1500.00, '2026-03-07', 'Лекарства', 'Анна', '2026-04-09 09:40:56'),
  (30, 2, 2, 2, 9, -800.00, '2026-03-08', 'Подписки и развлечения', 'Пользователь', '2026-04-09 09:40:56'),
  (31, 2, 2, 2, 18, 2000.00, '2026-03-09', 'Подарок деньгами', 'Анна', '2026-04-09 09:40:56'),
  (32, 2, 2, 2, 5, -6100.00, '2026-03-10', 'Коммунальные услуги', 'Пользователь', '2026-04-09 09:40:56'),
  (33, 2, 2, 2, 6, -850.00, '2026-03-11', 'Мобильная связь', 'Пользователь', '2026-04-09 09:40:56'),
  (34, 2, 2, 2, 8, -2600.00, '2026-03-12', 'Обувь', 'Анна', '2026-04-09 09:40:56'),
  (35, 2, 2, 2, 19, 650.00, '2026-03-13', 'Возврат за подписку', 'Пользователь', '2026-04-09 09:40:56'),
  (36, 2, 2, 2, 20, 1200.00, '2026-03-14', 'Продажа ненужных вещей', 'Пользователь', '2026-04-09 09:40:56'),

  (37, 3, 3, 3, 16, 35000.00, '2026-03-01', 'Зарплата', 'Пользователь', '2026-04-09 09:40:56'),
  (38, 3, 3, 3, 26, 4000.00, '2026-03-02', 'Откладывание в семейные накопления', 'Пользователь', '2026-04-09 09:40:56'),
  (39, 3, 3, 3, 1, -2800.00, '2026-03-03', 'Продукты на неделю', 'Илья', '2026-04-09 09:40:56'),
  (40, 3, 3, 3, 25, -5400.00, '2026-03-04', 'Оплата кружка робототехники', 'Пользователь', '2026-04-09 09:40:56'),
  (41, 3, 3, 3, 12, -1900.00, '2026-03-05', 'Учебные материалы', 'Илья', '2026-04-09 09:40:56'),
  (42, 3, 3, 3, 15, -700.00, '2026-03-06', 'Прочие траты', 'Пользователь', '2026-04-09 09:40:56');

-- =========================================================
-- 4. WISHLIST
-- Покрыты все статусы wishlist
-- =========================================================

INSERT INTO wishlist (id, family_id, account_id, user_id, category_id, title, description, amount, planned_date, priority, status, who, linked_transaction_id, created_at, updated_at) VALUES
  (1, 1, 1, 1, 11, 'Семейная поездка на выходные', 'Небольшое путешествие за город с бронированием жилья.', 15000.00, '2026-04-15', 'high', 'planned', 'Админ', NULL, '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (2, 1, 1, 1, 8, 'Новая куртка для Софии', 'Покупка демисезонной куртки к весне.', 5200.00, '2026-04-10', 'medium', 'planned', 'Мария', NULL, '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (3, 1, 1, 1, 5, 'Робот-пылесос', 'Покупка техники для дома.', 18990.00, '2026-05-01', 'medium', 'postponed', 'Админ', NULL, '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (4, 1, 1, 1, 10, 'Подарок бабушке', 'Подарок ко дню рождения.', 2500.00, '2026-03-12', 'low', 'bought', 'Мария', 13, '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (5, 1, 1, 1, 14, 'Переноска для кота', 'Удобная переноска для поездок к ветеринару.', 3400.00, '2026-04-25', 'medium', 'planned', 'Мария', NULL, '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (6, 2, 2, 2, 23, 'Набор кухонных контейнеров', 'Для хранения продуктов дома.', 1800.00, '2026-04-08', 'low', 'planned', 'Анна', NULL, '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (7, 2, 2, 2, 3, 'Самокат', 'Покупка самоката для города.', 7600.00, '2026-04-20', 'high', 'planned', 'Пользователь', NULL, '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (8, 2, 2, 2, 9, 'Подписка на семейный сервис', 'Годовая семейная подписка.', 2990.00, '2026-03-08', 'medium', 'cancelled', 'Пользователь', NULL, '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (9, 2, 2, 2, 13, 'Стеллаж в кладовку', 'Хотим организовать хранение вещей.', 8900.00, '2026-05-10', 'medium', 'postponed', 'Анна', NULL, '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (10, 3, 3, 3, 15, 'План покупок для недели', 'Тестовая wish-позиция для семьи календаря.', 1000.00, '2026-04-12', 'medium', 'planned', 'Пользователь', NULL, '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (11, 3, 3, 3, 25, 'Ноутбук для учёбы', 'Нужен к началу следующего семестра.', 42000.00, '2026-06-01', 'high', 'planned', 'Илья', NULL, '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (12, 3, 3, 3, 12, 'Курс по математике', 'Онлайн-обучение на 3 месяца.', 6900.00, '2026-04-18', 'low', 'bought', 'Пользователь', 41, '2026-04-09 09:40:56', '2026-04-09 09:40:56');

-- =========================================================
-- 5. CALENDAR EVENTS
-- Покрыты все типы событий + completed / recurring
-- =========================================================

INSERT INTO calendar_events (id, family_id, user_id, member_name, title, description, event_type, event_date, start_time, end_time, is_all_day, is_recurring, recurring_type, color, is_completed, completed_at, created_at, updated_at) VALUES
  (1, 1, 1, 'Алексей', 'Оплатить интернет', 'Ежемесячная оплата домашнего интернета.', 'reminder', '2026-03-19', '10:00:00', '10:30:00', 0, 1, 'monthly', '#0d6efd', 1, '2026-03-19 09:20:00', '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (2, 1, 1, 'Мария', 'Приём у стоматолога', 'Клиника SmileCare, кабинет 12.', 'event', '2026-03-19', '15:30:00', '16:30:00', 0, 0, 'none', '#dc3545', 0, NULL, '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (3, 1, 1, 'София', 'Подготовить школьную форму', 'Проверить одежду и собрать рюкзак.', 'task', '2026-03-19', '19:00:00', '19:30:00', 0, 0, 'none', '#fd7e14', 0, NULL, '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (4, 1, 1, 'Мария', 'День рождения мамы', 'Не забыть позвонить и отправить подарок.', 'birthday', '2026-03-20', NULL, NULL, 1, 1, 'yearly', '#e83e8c', 0, NULL, '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (5, 1, 1, 'Алексей', 'Семейный ужин', 'Бронь столика на 18:00.', 'event', '2026-03-20', '18:00:00', '20:00:00', 0, 0, 'none', '#198754', 0, NULL, '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (6, 1, 1, 'Алексей', 'Тренировка', 'Спортивный зал у дома.', 'task', '2026-03-21', '08:00:00', '09:00:00', 0, 1, 'weekly', '#20c997', 1, '2026-03-21 07:15:00', '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (7, 1, 1, 'Мария', 'Купить подарок', 'Выбрать подарок ко дню рождения.', 'task', '2026-03-21', '13:00:00', '14:00:00', 0, 0, 'none', '#6f42c1', 0, NULL, '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (8, 1, 1, 'София', 'Школьный концерт', 'Прийти немного заранее.', 'event', '2026-03-21', '17:00:00', '18:30:00', 0, 0, 'none', '#ffc107', 0, NULL, '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (9, 1, 1, 'Алексей', 'Семейная прогулка', 'Парк и горячий шоколад.', 'event', '2026-03-22', '12:00:00', '14:00:00', 0, 0, 'none', '#0dcaf0', 0, NULL, '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (10, 1, 1, NULL, 'Записать идеи для WishList', 'Пока просто заметка под будущую интеграцию.', 'wishlist_placeholder', '2026-03-22', NULL, NULL, 1, 0, 'none', '#6c757d', 0, NULL, '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (11, 1, 1, 'Мария', 'Оплатить кружок', 'Оплата до конца дня.', 'reminder', '2026-03-23', '09:00:00', '09:15:00', 0, 0, 'none', '#6610f2', 0, NULL, '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (12, 1, 1, 'София', 'Подготовка к контрольной', 'Повторить математику и английский.', 'task', '2026-03-23', '17:30:00', '19:00:00', 0, 0, 'none', '#198754', 0, NULL, '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (13, 2, 2, 'Админ', 'Встреча с банком', 'Обсудить семейный счёт.', 'event', '2026-03-19', '11:00:00', '12:00:00', 0, 0, 'none', '#0d6efd', 0, NULL, '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (14, 2, 2, 'Админ', 'Позвонить родителям', 'Спросить про выходные.', 'reminder', '2026-03-20', '20:00:00', '20:15:00', 0, 0, 'none', '#fd7e14', 1, '2026-03-20 18:50:00', '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (15, 2, 2, 'Анна', 'Сделать заказ для дома', 'Нужно заказать расходники и бытовую химию.', 'task', '2026-03-22', '18:00:00', '19:00:00', 0, 0, 'none', '#198754', 0, NULL, '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (16, 2, 2, 'Пользователь', 'Годовщина знакомства', 'Ужин без детей.', 'birthday', '2026-03-24', NULL, NULL, 1, 1, 'yearly', '#e83e8c', 0, NULL, '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (17, 2, 2, NULL, 'Идеи для будущих покупок', 'Черновик для wishlist товаров.', 'wishlist_placeholder', '2026-03-25', NULL, NULL, 1, 0, 'none', '#6c757d', 0, NULL, '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (18, 3, 3, 'Пользователь', 'Составить план недели', 'Заполнить дневник на ближайшие дни.', 'task', '2026-03-19', '08:30:00', '09:00:00', 0, 0, 'none', '#198754', 0, NULL, '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (19, 3, 3, 'Пользователь', 'День рождения брата', 'Купить торт.', 'birthday', '2026-03-24', NULL, NULL, 1, 1, 'yearly', '#e83e8c', 0, NULL, '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (20, 3, 3, 'Илья', 'Оплатить курс', 'Проверить скидку на обучение.', 'reminder', '2026-03-26', '09:30:00', '10:00:00', 0, 0, 'none', '#0d6efd', 0, NULL, '2026-04-09 09:40:56', '2026-04-09 09:40:56'),
  (21, 3, 3, 'Пользователь', 'Собрание в школе', 'Обсуждение мероприятий на месяц.', 'event', '2026-03-27', '18:30:00', '20:00:00', 0, 0, 'none', '#ff9800', 0, NULL, '2026-04-09 09:40:56', '2026-04-09 09:40:56');

-- =========================================================
-- 6. AUTO_INCREMENT FIX
-- =========================================================

ALTER TABLE families AUTO_INCREMENT = 4;
ALTER TABLE users AUTO_INCREMENT = 4;
ALTER TABLE accounts AUTO_INCREMENT = 4;
ALTER TABLE calendar_events AUTO_INCREMENT = 22;
ALTER TABLE categories AUTO_INCREMENT = 27;
ALTER TABLE family_members AUTO_INCREMENT = 8;
ALTER TABLE transactions AUTO_INCREMENT = 43;
ALTER TABLE wishlist AUTO_INCREMENT = 13;

-- =========================================================
-- DONE
-- =========================================================
