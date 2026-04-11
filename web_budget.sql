-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Хост: localhost
-- Время создания: Апр 11 2026 г., 14:39
-- Версия сервера: 10.4.28-MariaDB
-- Версия PHP: 8.2.4

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- База данных: `web_budget`
--

-- --------------------------------------------------------

--
-- Структура таблицы `accounts`
--

CREATE TABLE `accounts` (
  `id` int(10) UNSIGNED NOT NULL,
  `family_id` int(10) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `is_main` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Дамп данных таблицы `accounts`
--

INSERT INTO `accounts` (`id`, `family_id`, `name`, `is_main`, `created_at`) VALUES
(1, 1, 'Основной счёт', 1, '2026-04-11 12:38:46'),
(2, 2, 'Основной счёт', 1, '2026-04-11 12:38:46'),
(3, 3, 'Основной счёт', 1, '2026-04-11 12:38:46');

-- --------------------------------------------------------

--
-- Структура таблицы `calendar_events`
--

CREATE TABLE `calendar_events` (
  `id` int(10) UNSIGNED NOT NULL,
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
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Дамп данных таблицы `calendar_events`
--

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

-- --------------------------------------------------------

--
-- Структура таблицы `categories`
--

CREATE TABLE `categories` (
  `id` int(10) UNSIGNED NOT NULL,
  `family_id` int(10) UNSIGNED DEFAULT NULL,
  `name` varchar(255) NOT NULL,
  `type` enum('income','expense') NOT NULL DEFAULT 'expense',
  `color` varchar(20) NOT NULL DEFAULT '#cccccc',
  `icon` varchar(100) NOT NULL DEFAULT 'bi-tag',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Дамп данных таблицы `categories`
--

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

-- --------------------------------------------------------

--
-- Структура таблицы `families`
--

CREATE TABLE `families` (
  `id` int(10) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Дамп данных таблицы `families`
--

INSERT INTO `families` (`id`, `name`, `created_at`) VALUES
(1, 'Семья администратора', '2026-04-11 12:38:46'),
(2, 'Семья пользователя', '2026-04-11 12:38:46'),
(3, 'Тестовая семья календаря', '2026-04-11 12:38:46');

-- --------------------------------------------------------

--
-- Структура таблицы `family_members`
--

CREATE TABLE `family_members` (
  `id` int(10) UNSIGNED NOT NULL,
  `family_id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `name` varchar(255) NOT NULL,
  `is_owner` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Дамп данных таблицы `family_members`
--

INSERT INTO `family_members` (`id`, `family_id`, `user_id`, `name`, `is_owner`, `created_at`) VALUES
(1, 1, 1, 'Админ', 1, '2026-04-11 12:38:46'),
(2, 1, 1, 'Мария', 0, '2026-04-11 12:38:46'),
(3, 1, 1, 'София', 0, '2026-04-11 12:38:46'),
(4, 2, 2, 'Пользователь', 1, '2026-04-11 12:38:46'),
(5, 2, 2, 'Анна', 0, '2026-04-11 12:38:46'),
(6, 3, 3, 'Пользователь', 1, '2026-04-11 12:38:46');

-- --------------------------------------------------------

--
-- Структура таблицы `hidden_categories`
--

CREATE TABLE `hidden_categories` (
  `family_id` int(10) UNSIGNED NOT NULL,
  `category_id` int(10) UNSIGNED NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Дамп данных таблицы `hidden_categories`
--

INSERT INTO `hidden_categories` (`family_id`, `category_id`, `created_at`) VALUES
(1, 15, '2026-04-11 12:38:46');

-- --------------------------------------------------------

--
-- Структура таблицы `transactions`
--

CREATE TABLE `transactions` (
  `id` int(10) UNSIGNED NOT NULL,
  `family_id` int(10) UNSIGNED NOT NULL,
  `account_id` int(10) UNSIGNED NOT NULL,
  `user_id` int(10) UNSIGNED NOT NULL,
  `category_id` int(10) UNSIGNED NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `date` date NOT NULL,
  `description` varchar(500) DEFAULT NULL,
  `who` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Дамп данных таблицы `transactions`
--

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
(23, 2, 2, 2, 18, 2000.00, '2026-03-09', 'Подарок деньгами', 'Анна', '2026-04-11 12:38:46');

-- --------------------------------------------------------

--
-- Структура таблицы `users`
--

CREATE TABLE `users` (
  `id` int(10) UNSIGNED NOT NULL,
  `email` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `family_id` int(10) UNSIGNED DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Дамп данных таблицы `users`
--

INSERT INTO `users` (`id`, `email`, `password_hash`, `name`, `family_id`, `created_at`) VALUES
(1, 'admin@myshop.local', '$2b$12$pFOZ5wBSN4v0euitgr9yIuclcpFlw2keJMt/MQReIgbhpbIUiXlVa', 'Админ', 1, '2026-04-11 12:38:46'),
(2, 'user@myshop.local', '$2b$12$pFOZ5wBSN4v0euitgr9yIuclcpFlw2keJMt/MQReIgbhpbIUiXlVa', 'Пользователь', 2, '2026-04-11 12:38:46'),
(3, 'calendar@myshop.local', '$2b$12$pFOZ5wBSN4v0euitgr9yIuclcpFlw2keJMt/MQReIgbhpbIUiXlVa', 'Пользователь', 3, '2026-04-11 12:38:46');

-- --------------------------------------------------------

--
-- Структура таблицы `wishlist`
--

CREATE TABLE `wishlist` (
  `id` int(10) UNSIGNED NOT NULL,
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
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Индексы сохранённых таблиц
--

--
-- Индексы таблицы `accounts`
--
ALTER TABLE `accounts`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_accounts_family_id` (`family_id`),
  ADD KEY `idx_accounts_family_main` (`family_id`,`is_main`);

--
-- Индексы таблицы `calendar_events`
--
ALTER TABLE `calendar_events`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_calendar_events_family_date` (`family_id`,`event_date`),
  ADD KEY `idx_calendar_events_user_id` (`user_id`),
  ADD KEY `idx_calendar_events_type` (`event_type`),
  ADD KEY `idx_calendar_events_completed` (`family_id`,`event_date`,`is_completed`);

--
-- Индексы таблицы `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_categories_family_id` (`family_id`),
  ADD KEY `idx_categories_family_type` (`family_id`,`type`),
  ADD KEY `idx_categories_name` (`name`);

--
-- Индексы таблицы `families`
--
ALTER TABLE `families`
  ADD PRIMARY KEY (`id`);

--
-- Индексы таблицы `family_members`
--
ALTER TABLE `family_members`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_family_members_family_id` (`family_id`),
  ADD KEY `idx_family_members_user_id` (`user_id`);

--
-- Индексы таблицы `hidden_categories`
--
ALTER TABLE `hidden_categories`
  ADD PRIMARY KEY (`family_id`,`category_id`),
  ADD KEY `idx_hidden_categories_category_id` (`category_id`);

--
-- Индексы таблицы `transactions`
--
ALTER TABLE `transactions`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_transactions_family_id` (`family_id`),
  ADD KEY `idx_transactions_account_id` (`account_id`),
  ADD KEY `idx_transactions_user_id` (`user_id`),
  ADD KEY `idx_transactions_category_id` (`category_id`),
  ADD KEY `idx_transactions_date` (`date`),
  ADD KEY `idx_transactions_family_account_date` (`family_id`,`account_id`,`date`);

--
-- Индексы таблицы `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `uq_users_email` (`email`),
  ADD KEY `idx_users_family_id` (`family_id`);

--
-- Индексы таблицы `wishlist`
--
ALTER TABLE `wishlist`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_wishlist_family_id` (`family_id`),
  ADD KEY `idx_wishlist_account_id` (`account_id`),
  ADD KEY `idx_wishlist_user_id` (`user_id`),
  ADD KEY `idx_wishlist_category_id` (`category_id`),
  ADD KEY `idx_wishlist_linked_transaction_id` (`linked_transaction_id`),
  ADD KEY `idx_wishlist_status` (`status`),
  ADD KEY `idx_wishlist_planned_date` (`planned_date`),
  ADD KEY `idx_wishlist_family_account_status` (`family_id`,`account_id`,`status`),
  ADD KEY `idx_wishlist_family_account_created` (`family_id`,`account_id`,`created_at`);

--
-- AUTO_INCREMENT для сохранённых таблиц
--

--
-- AUTO_INCREMENT для таблицы `accounts`
--
ALTER TABLE `accounts`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT для таблицы `calendar_events`
--
ALTER TABLE `calendar_events`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT для таблицы `categories`
--
ALTER TABLE `categories`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT для таблицы `families`
--
ALTER TABLE `families`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT для таблицы `family_members`
--
ALTER TABLE `family_members`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT для таблицы `transactions`
--
ALTER TABLE `transactions`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=24;

--
-- AUTO_INCREMENT для таблицы `users`
--
ALTER TABLE `users`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT для таблицы `wishlist`
--
ALTER TABLE `wishlist`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT;

--
-- Ограничения внешнего ключа сохраненных таблиц
--

--
-- Ограничения внешнего ключа таблицы `accounts`
--
ALTER TABLE `accounts`
  ADD CONSTRAINT `fk_accounts_family` FOREIGN KEY (`family_id`) REFERENCES `families` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ограничения внешнего ключа таблицы `calendar_events`
--
ALTER TABLE `calendar_events`
  ADD CONSTRAINT `fk_calendar_events_family` FOREIGN KEY (`family_id`) REFERENCES `families` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_calendar_events_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ограничения внешнего ключа таблицы `categories`
--
ALTER TABLE `categories`
  ADD CONSTRAINT `fk_categories_family` FOREIGN KEY (`family_id`) REFERENCES `families` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ограничения внешнего ключа таблицы `family_members`
--
ALTER TABLE `family_members`
  ADD CONSTRAINT `fk_family_members_family` FOREIGN KEY (`family_id`) REFERENCES `families` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_family_members_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ограничения внешнего ключа таблицы `hidden_categories`
--
ALTER TABLE `hidden_categories`
  ADD CONSTRAINT `fk_hidden_categories_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_hidden_categories_family` FOREIGN KEY (`family_id`) REFERENCES `families` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ограничения внешнего ключа таблицы `transactions`
--
ALTER TABLE `transactions`
  ADD CONSTRAINT `fk_transactions_account` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_transactions_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_transactions_family` FOREIGN KEY (`family_id`) REFERENCES `families` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_transactions_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Ограничения внешнего ключа таблицы `users`
--
ALTER TABLE `users`
  ADD CONSTRAINT `fk_users_family` FOREIGN KEY (`family_id`) REFERENCES `families` (`id`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Ограничения внешнего ключа таблицы `wishlist`
--
ALTER TABLE `wishlist`
  ADD CONSTRAINT `fk_wishlist_account` FOREIGN KEY (`account_id`) REFERENCES `accounts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_wishlist_category` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_wishlist_family` FOREIGN KEY (`family_id`) REFERENCES `families` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_wishlist_linked_transaction` FOREIGN KEY (`linked_transaction_id`) REFERENCES `transactions` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_wishlist_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
