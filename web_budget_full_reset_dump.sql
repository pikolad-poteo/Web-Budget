-- =====================================================================
-- FULL RESET + TEST DATA DUMP FOR `web_budget`
-- Generated from the uploaded database dump and extended with wishlist
-- test data so the database can be recreated from scratch in one run.
-- =====================================================================

SET SQL_MODE = 'NO_AUTO_VALUE_ON_ZERO';
SET time_zone = '+00:00';
SET NAMES utf8mb4;

CREATE DATABASE IF NOT EXISTS `web_budget`
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE `web_budget`;

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS `wishlist`;
DROP TABLE IF EXISTS `calendar_events`;
DROP TABLE IF EXISTS `transactions`;
DROP TABLE IF EXISTS `hidden_categories`;
DROP TABLE IF EXISTS `family_members`;
DROP TABLE IF EXISTS `accounts`;
DROP TABLE IF EXISTS `users`;
DROP TABLE IF EXISTS `categories`;
DROP TABLE IF EXISTS `families`;

SET FOREIGN_KEY_CHECKS = 1;

START TRANSACTION;

CREATE TABLE `families` (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `users` (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `family_id` int(10) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_users_email` (`email`),
  KEY `idx_users_family_id` (`family_id`),
  CONSTRAINT `fk_users_family` FOREIGN KEY (`family_id`) REFERENCES `families` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `accounts` (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `family_id` int(10) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `is_main` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_accounts_family_id` (`family_id`),
  KEY `idx_accounts_family_main` (`family_id`,`is_main`),
  CONSTRAINT `fk_accounts_family` FOREIGN KEY (`family_id`) REFERENCES `families` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `categories` (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `family_id` int(10) UNSIGNED DEFAULT NULL,
  `name` varchar(255) NOT NULL,
  `type` enum('income','expense') NOT NULL DEFAULT 'expense',
  `color` varchar(20) NOT NULL DEFAULT '#cccccc',
  `icon` varchar(100) NOT NULL DEFAULT 'bi-tag',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_categories_family_id` (`family_id`),
  KEY `idx_categories_family_type` (`family_id`,`type`),
  KEY `idx_categories_name` (`name`),
  CONSTRAINT `fk_categories_family` FOREIGN KEY (`family_id`) REFERENCES `families` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `family_members` (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `family_id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `is_owner` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_family_members_family_id` (`family_id`),
  KEY `idx_family_members_user_id` (`user_id`),
  CONSTRAINT `fk_family_members_family` FOREIGN KEY (`family_id`) REFERENCES `families` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_family_members_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `hidden_categories` (
  `family_id` int(10) UNSIGNED NOT NULL,
  `category_id` int(10) UNSIGNED NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`family_id`,`category_id`),
  KEY `idx_hidden_categories_category_id` (`category_id`),
  CONSTRAINT `fk_hidden_categories_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_hidden_categories_family` FOREIGN KEY (`family_id`) REFERENCES `families` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `transactions` (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `family_id` int(10) UNSIGNED NOT NULL,
  `account_id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `category_id` int(10) UNSIGNED NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `date` date NOT NULL,
  `description` varchar(500) DEFAULT NULL,
  `who` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_transactions_family_id` (`family_id`),
  KEY `idx_transactions_account_id` (`account_id`),
  KEY `idx_transactions_user_id` (`user_id`),
  KEY `idx_transactions_category_id` (`category_id`),
  KEY `idx_transactions_date` (`date`),
  KEY `idx_transactions_family_account_date` (`family_id`,`account_id`,`date`),
  CONSTRAINT `fk_transactions_account` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_transactions_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_transactions_family` FOREIGN KEY (`family_id`) REFERENCES `families` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_transactions_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `calendar_events` (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `family_id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `member_name` varchar(255) DEFAULT NULL,
  `title` varchar(255) NOT NULL,
  `description` varchar(1000) DEFAULT NULL,
  `event_type` enum('event','birthday','reminder','task','wishlist_placeholder') NOT NULL DEFAULT 'event',
  `event_date` date NOT NULL,
  `start_time` time DEFAULT NULL,
  `end_time` time DEFAULT NULL,
  `is_all_day` tinyint(1) NOT NULL DEFAULT 0,
  `is_recurring` tinyint(1) NOT NULL DEFAULT 0,
  `recurring_type` enum('none','daily','weekly','monthly','yearly') NOT NULL DEFAULT 'none',
  `color` varchar(20) NOT NULL DEFAULT '#0d6efd',
  `is_completed` tinyint(1) NOT NULL DEFAULT 0,
  `completed_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_calendar_events_family_date` (`family_id`,`event_date`),
  KEY `idx_calendar_events_user_id` (`user_id`),
  KEY `idx_calendar_events_type` (`event_type`),
  KEY `idx_calendar_events_completed` (`family_id`,`event_date`,`is_completed`),
  CONSTRAINT `fk_calendar_events_family` FOREIGN KEY (`family_id`) REFERENCES `families` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_calendar_events_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `wishlist` (
  `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT,
  `family_id` int(10) UNSIGNED NOT NULL,
  `account_id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `category_id` int(10) UNSIGNED DEFAULT NULL,
  `title` varchar(255) NOT NULL,
  `description` varchar(1000) DEFAULT NULL,
  `amount` decimal(12,2) NOT NULL,
  `planned_date` date DEFAULT NULL,
  `priority` enum('low','medium','high') NOT NULL DEFAULT 'medium',
  `status` enum('planned','postponed','bought','cancelled') NOT NULL DEFAULT 'planned',
  `who` varchar(255) DEFAULT NULL,
  `store_url` varchar(1000) DEFAULT NULL,
  `image_url` varchar(1000) DEFAULT NULL,
  `linked_transaction_id` int(10) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_wishlist_family_id` (`family_id`),
  KEY `idx_wishlist_account_id` (`account_id`),
  KEY `idx_wishlist_user_id` (`user_id`),
  KEY `idx_wishlist_category_id` (`category_id`),
  KEY `idx_wishlist_linked_transaction_id` (`linked_transaction_id`),
  KEY `idx_wishlist_status` (`status`),
  KEY `idx_wishlist_planned_date` (`planned_date`),
  KEY `idx_wishlist_family_account_status` (`family_id`,`account_id`,`status`),
  KEY `idx_wishlist_family_account_created` (`family_id`,`account_id`,`created_at`),
  CONSTRAINT `fk_wishlist_account` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_wishlist_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_wishlist_family` FOREIGN KEY (`family_id`) REFERENCES `families` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_wishlist_linked_transaction` FOREIGN KEY (`linked_transaction_id`) REFERENCES `transactions` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_wishlist_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `families` (`id`, `name`, `created_at`) VALUES
(1, 'Семья администратора', '2026-04-11 12:38:46'),
(2, 'Семья пользователя', '2026-04-11 12:38:46'),
(3, 'Тестовая семья календаря', '2026-04-11 12:38:46');

INSERT INTO `users` (`id`, `email`, `password_hash`, `name`, `family_id`, `created_at`) VALUES
(1, 'admin@myshop.local', '$2b$12$pFOZ5wBSN4v0euitgr9yIuclcpFlw2keJMt/MQReIgbhpbIUiXlVa', 'Админ', 1, '2026-04-11 12:38:46'),
(2, 'user@myshop.local', '$2b$12$pFOZ5wBSN4v0euitgr9yIuclcpFlw2keJMt/MQReIgbhpbIUiXlVa', 'Пользователь', 2, '2026-04-11 12:38:46'),
(3, 'calendar@myshop.local', '$2b$12$pFOZ5wBSN4v0euitgr9yIuclcpFlw2keJMt/MQReIgbhpbIUiXlVa', 'Пользователь', 3, '2026-04-11 12:38:46');

INSERT INTO `accounts` (`id`, `family_id`, `name`, `is_main`, `created_at`) VALUES
(1, 1, 'Основной счёт', 1, '2026-04-11 12:38:46'),
(2, 2, 'Основной счёт', 1, '2026-04-11 12:38:46'),
(3, 3, 'Основной счёт', 1, '2026-04-11 12:38:46');

INSERT INTO `categories` (`id`, `family_id`, `name`, `type`, `color`, `icon`, `created_at`) VALUES
(1, NULL, 'Продукты', 'expense', '#4CAF50', 'bi-cart', '2026-04-11 12:38:46'),
(2, NULL, 'Кафе и рестораны', 'expense', '#FF9800', 'bi-cup-hot', '2026-04-11 12:38:46'),
(3, NULL, 'Транспорт', 'expense', '#2196F3', 'bi-bus-front', '2026-04-11 12:38:46'),
(4, NULL, 'Топливо', 'expense', '#795548', 'bi-fuel-pump', '2026-04-11 12:38:46'),
(5, NULL, 'Дом и коммуналка', 'expense', '#9C27B0', 'bi-house-door', '2026-04-11 12:38:46'),
(6, NULL, 'Интернет и связь', 'expense', '#3F51B5', 'bi-wifi', '2026-04-11 12:38:46'),
(7, NULL, 'Здоровье', 'expense', '#E91E63', 'bi-heart-pulse', '2026-04-11 12:38:46'),
(8, NULL, 'Одежда', 'expense', '#607D8B', 'bi-bag', '2026-04-11 12:38:46'),
(9, NULL, 'Развлечения', 'expense', '#FFC107', 'bi-controller', '2026-04-11 12:38:46'),
(10, NULL, 'Подарки', 'expense', '#F44336', 'bi-gift', '2026-04-11 12:38:46'),
(11, NULL, 'Путешествия', 'expense', '#00BCD4', 'bi-airplane', '2026-04-11 12:38:46'),
(12, NULL, 'Образование', 'expense', '#8BC34A', 'bi-mortarboard', '2026-04-11 12:38:46'),
(13, NULL, 'Ремонт', 'expense', '#9E9E9E', 'bi-hammer', '2026-04-11 12:38:46'),
(14, NULL, 'Питомцы', 'expense', '#673AB7', 'bi-suit-heart-fill', '2026-04-11 12:38:46'),
(15, NULL, 'Прочее', 'expense', '#BDBDBD', 'bi-tag', '2026-04-11 12:38:46'),
(16, NULL, 'Зарплата', 'income', '#2E7D32', 'bi-cash-coin', '2026-04-11 12:38:46'),
(17, NULL, 'Подработка', 'income', '#388E3C', 'bi-briefcase', '2026-04-11 12:38:46'),
(18, NULL, 'Подарок', 'income', '#7CB342', 'bi-gift', '2026-04-11 12:38:46'),
(19, NULL, 'Возврат', 'income', '#689F38', 'bi-arrow-repeat', '2026-04-11 12:38:46'),
(20, NULL, 'Прочий доход', 'income', '#558B2F', 'bi-piggy-bank', '2026-04-11 12:38:46'),
(21, 1, 'Детские расходы', 'expense', '#FF6F61', 'bi-emoji-smile', '2026-04-11 12:38:46'),
(22, 1, 'Накопления', 'income', '#009688', 'bi-piggy-bank', '2026-04-11 12:38:46'),
(23, 2, 'Домашние покупки', 'expense', '#FF7043', 'bi-basket', '2026-04-11 12:38:46'),
(24, 2, 'Фриланс', 'income', '#26A69A', 'bi-laptop', '2026-04-11 12:38:46');

INSERT INTO `family_members` (`id`, `family_id`, `user_id`, `name`, `is_owner`, `created_at`) VALUES
(1, 1, 1, 'Админ', 1, '2026-04-11 12:38:46'),
(2, 1, 1, 'Мария', 0, '2026-04-11 12:38:46'),
(3, 1, 1, 'София', 0, '2026-04-11 12:38:46'),
(4, 2, 2, 'Пользователь', 1, '2026-04-11 12:38:46'),
(5, 2, 2, 'Анна', 0, '2026-04-11 12:38:46'),
(6, 3, 3, 'Пользователь', 1, '2026-04-11 12:38:46');

INSERT INTO `hidden_categories` (`family_id`, `category_id`, `created_at`) VALUES
(1, 15, '2026-04-11 12:38:46');

INSERT INTO `transactions` (`id`, `family_id`, `account_id`, `user_id`, `category_id`, `amount`, `date`, `description`, `who`, `created_at`) VALUES
(1, 1, 1, 1, 16, 75000.00, '2026-03-01', 'Зарплата за март', 'Админ', '2026-04-11 12:38:46'),
(2, 1, 1, 1, 17, 12000.00, '2026-03-03', 'Подработка', 'Админ', '2026-04-11 12:38:46'),
(3, 1, 1, 1, 22, 5000.00, '2026-03-04', 'Перевод в накопления', 'Админ', '2026-04-11 12:38:46'),
(4, 1, 1, 1, 1, -6500.00, '2026-03-02', 'Закупка продуктов', 'Мария', '2026-04-11 12:38:46'),
(5, 1, 1, 1, 2, -2100.00, '2026-03-04', 'Семейное кафе', 'Админ', '2026-04-11 12:38:46'),
(6, 1, 1, 1, 3, -1200.00, '2026-03-05', 'Метро и автобус', 'Мария', '2026-04-11 12:38:46'),
(7, 1, 1, 1, 4, -3000.00, '2026-03-06', 'Заправка машины', 'Админ', '2026-04-11 12:38:46'),
(8, 1, 1, 1, 5, -9500.00, '2026-03-07', 'Коммунальные услуги', 'Админ', '2026-04-11 12:38:46'),
(9, 1, 1, 1, 6, -1400.00, '2026-03-08', 'Интернет и мобильная связь', 'Мария', '2026-04-11 12:38:46'),
(10, 1, 1, 1, 7, -2200.00, '2026-03-09', 'Аптека', 'Мария', '2026-04-11 12:38:46'),
(11, 1, 1, 1, 8, -4800.00, '2026-03-10', 'Одежда', 'Мария', '2026-04-11 12:38:46'),
(12, 1, 1, 1, 9, -1600.00, '2026-03-11', 'Развлечения', 'Админ', '2026-04-11 12:38:46'),
(13, 1, 1, 1, 10, -2500.00, '2026-03-12', 'Подарок', 'Админ', '2026-04-11 12:38:46'),
(14, 1, 1, 1, 21, -3900.00, '2026-03-13', 'Товары для ребёнка', 'София', '2026-04-11 12:38:46'),
(15, 2, 2, 2, 16, 42000.00, '2026-03-01', 'Основной доход', 'Пользователь', '2026-04-11 12:38:46'),
(16, 2, 2, 2, 24, 8000.00, '2026-03-02', 'Фриланс заказ', 'Пользователь', '2026-04-11 12:38:46'),
(17, 2, 2, 2, 1, -4300.00, '2026-03-03', 'Продукты домой', 'Анна', '2026-04-11 12:38:46'),
(18, 2, 2, 2, 23, -2700.00, '2026-03-04', 'Домашние мелочи', 'Пользователь', '2026-04-11 12:38:46'),
(19, 2, 2, 2, 3, -900.00, '2026-03-05', 'Транспорт', 'Пользователь', '2026-04-11 12:38:46'),
(20, 2, 2, 2, 2, -1100.00, '2026-03-06', 'Кафе', 'Анна', '2026-04-11 12:38:46'),
(21, 2, 2, 2, 7, -1500.00, '2026-03-07', 'Лекарства', 'Анна', '2026-04-11 12:38:46'),
(22, 2, 2, 2, 9, -800.00, '2026-03-08', 'Подписки и развлечения', 'Пользователь', '2026-04-11 12:38:46'),
(23, 2, 2, 2, 18, 2000.00, '2026-03-09', 'Подарок деньгами', 'Анна', '2026-04-11 12:38:46'),
(24, 1, 1, 1, 12, -15500.00, '2026-03-15', 'Планшет для учёбы куплен', 'Админ', '2026-04-11 12:38:46'),
(25, 2, 2, 2, 23, -12900.00, '2026-03-18', 'Робот-пылесос куплен', 'Пользователь', '2026-04-11 12:38:46');

INSERT INTO `calendar_events` (`id`, `family_id`, `user_id`, `member_name`, `title`, `description`, `event_type`, `event_date`, `start_time`, `end_time`, `is_all_day`, `is_recurring`, `recurring_type`, `color`, `is_completed`, `completed_at`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 'Алексей', 'Оплатить интернет', 'Ежемесячная оплата домашнего интернета.', 'reminder', '2026-03-19', '10:00:00', '10:30:00', 0, 1, 'monthly', '#0d6efd', 1, '2026-03-19 09:20:00', '2026-04-11 12:38:46', '2026-04-11 12:38:46'),
(2, 1, 1, 'Мария', 'Приём у стоматолога', 'Клиника SmileCare, кабинет 12.', 'event', '2026-03-19', '15:30:00', '16:30:00', 0, 0, 'none', '#dc3545', 0, NULL, '2026-04-11 12:38:46', '2026-04-11 12:38:46'),
(3, 1, 1, 'София', 'Подготовить школьную форму', 'Проверить одежду и собрать рюкзак.', 'task', '2026-03-19', '19:00:00', '19:30:00', 0, 0, 'none', '#fd7e14', 0, NULL, '2026-04-11 12:38:46', '2026-04-11 12:38:46'),
(4, 1, 1, 'Мария', 'День рождения мамы', 'Не забыть позвонить и отправить подарок.', 'birthday', '2026-03-20', NULL, NULL, 1, 1, 'yearly', '#e83e8c', 0, NULL, '2026-04-11 12:38:46', '2026-04-11 12:38:46'),
(5, 1, 1, 'Алексей', 'Семейный ужин', 'Бронь столика на 18:00.', 'event', '2026-03-20', '18:00:00', '20:00:00', 0, 0, 'none', '#198754', 0, NULL, '2026-04-11 12:38:46', '2026-04-11 12:38:46'),
(6, 1, 1, 'Алексей', 'Тренировка', 'Спортивный зал у дома.', 'task', '2026-03-21', '08:00:00', '09:00:00', 0, 1, 'weekly', '#20c997', 1, '2026-03-21 07:15:00', '2026-04-11 12:38:46', '2026-04-11 12:38:46'),
(7, 1, 1, 'Мария', 'Купить подарок', 'Выбрать подарок ко дню рождения.', 'task', '2026-03-21', '13:00:00', '14:00:00', 0, 0, 'none', '#6f42c1', 0, NULL, '2026-04-11 12:38:46', '2026-04-11 12:38:46'),
(8, 1, 1, 'София', 'Школьный концерт', 'Прийти немного заранее.', 'event', '2026-03-21', '17:00:00', '18:30:00', 0, 0, 'none', '#ffc107', 0, NULL, '2026-04-11 12:38:46', '2026-04-11 12:38:46'),
(9, 1, 1, 'Алексей', 'Семейная прогулка', 'Парк и горячий шоколад.', 'event', '2026-03-22', '12:00:00', '14:00:00', 0, 0, 'none', '#0dcaf0', 0, NULL, '2026-04-11 12:38:46', '2026-04-11 12:38:46'),
(10, 1, 1, NULL, 'Записать идеи для WishList', 'Пока просто заметка под будущую интеграцию.', 'wishlist_placeholder', '2026-03-22', NULL, NULL, 1, 0, 'none', '#6c757d', 0, NULL, '2026-04-11 12:38:46', '2026-04-11 12:38:46'),
(11, 1, 1, 'Мария', 'Оплатить кружок', 'Оплата до конца дня.', 'reminder', '2026-03-23', '09:00:00', '09:15:00', 0, 0, 'none', '#6610f2', 0, NULL, '2026-04-11 12:38:46', '2026-04-11 12:38:46'),
(12, 1, 1, 'София', 'Подготовка к контрольной', 'Повторить математику и английский.', 'task', '2026-03-23', '17:30:00', '19:00:00', 0, 0, 'none', '#198754', 0, NULL, '2026-04-11 12:38:46', '2026-04-11 12:38:46'),
(13, 2, 2, 'Админ', 'Встреча с банком', 'Обсудить семейный счёт.', 'event', '2026-03-19', '11:00:00', '12:00:00', 0, 0, 'none', '#0d6efd', 0, NULL, '2026-04-11 12:38:46', '2026-04-11 12:38:46'),
(14, 2, 2, 'Админ', 'Позвонить родителям', 'Спросить про выходные.', 'reminder', '2026-03-20', '20:00:00', '20:15:00', 0, 0, 'none', '#fd7e14', 1, '2026-03-20 18:50:00', '2026-04-11 12:38:46', '2026-04-11 12:38:46'),
(15, 3, 3, 'Пользователь', 'Составить план недели', 'Заполнить дневник на ближайшие дни.', 'task', '2026-03-19', '08:30:00', '09:00:00', 0, 0, 'none', '#198754', 0, NULL, '2026-04-11 12:38:46', '2026-04-11 12:38:46'),
(16, 3, 3, 'Пользователь', 'День рождения брата', 'Купить торт.', 'birthday', '2026-03-24', NULL, NULL, 1, 1, 'yearly', '#e83e8c', 0, NULL, '2026-04-11 12:38:46', '2026-04-11 12:38:46');

INSERT INTO `wishlist` (`id`, `family_id`, `account_id`, `user_id`, `category_id`, `title`, `description`, `amount`, `planned_date`, `priority`, `status`, `who`, `store_url`, `image_url`, `linked_transaction_id`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 1, 11, 'Семейная поездка на выходные', 'Небольшая поездка всей семьёй за город.', 18000.00, '2026-04-15', 'high', 'planned', 'Админ', NULL, NULL, NULL, '2026-04-11 12:38:46', '2026-04-11 12:38:46'),
(2, 1, 1, 1, 12, 'Планшет для учёбы', 'Планшет для ребёнка с чехлом и стилусом.', 15500.00, '2026-03-15', 'high', 'bought', 'Мария', NULL, NULL, 24, '2026-04-11 12:38:46', '2026-04-11 12:38:46'),
(3, 2, 2, 2, 23, 'Робот-пылесос', 'Покупка отложена до следующего месяца.', 12900.00, '2026-04-10', 'medium', 'postponed', 'Пользователь', NULL, NULL, NULL, '2026-04-11 12:38:46', '2026-04-11 12:38:46'),
(4, 2, 2, 2, 23, 'Кофемашина', 'Для кухни и семейных завтраков.', 8900.00, '2026-04-22', 'low', 'planned', 'Анна', NULL, NULL, NULL, '2026-04-11 12:38:46', '2026-04-11 12:38:46'),
(5, 3, 3, 3, 10, 'Подарок брату', 'Идея подарка отменена, выбрали другой вариант.', 3500.00, '2026-03-24', 'medium', 'cancelled', 'Пользователь', NULL, NULL, NULL, '2026-04-11 12:38:46', '2026-04-11 12:38:46');

ALTER TABLE `families` AUTO_INCREMENT = 4;
ALTER TABLE `users` AUTO_INCREMENT = 4;
ALTER TABLE `accounts` AUTO_INCREMENT = 4;
ALTER TABLE `categories` AUTO_INCREMENT = 25;
ALTER TABLE `family_members` AUTO_INCREMENT = 7;
ALTER TABLE `transactions` AUTO_INCREMENT = 26;
ALTER TABLE `calendar_events` AUTO_INCREMENT = 17;
ALTER TABLE `wishlist` AUTO_INCREMENT = 6;

COMMIT;

SET FOREIGN_KEY_CHECKS = 1;
