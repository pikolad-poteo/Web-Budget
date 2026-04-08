-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Хост: 127.0.0.1
-- Время создания: Мар 11 2026 г., 11:28
-- Версия сервера: 10.4.32-MariaDB
-- Версия PHP: 8.0.30

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
(1, 1, 'Основной счёт', 1, '2026-03-11 10:19:52'),
(2, 2, 'Основной счёт', 1, '2026-03-11 10:23:46'),
(3, 3, 'Основной счёт', 1, '2026-03-11 10:23:46');

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
(1, NULL, 'Продукты', 'expense', '#4CAF50', 'bi-cart', '2026-03-11 10:19:52'),
(2, NULL, 'Кафе и рестораны', 'expense', '#FF9800', 'bi-cup-hot', '2026-03-11 10:19:52'),
(3, NULL, 'Транспорт', 'expense', '#2196F3', 'bi-bus-front', '2026-03-11 10:19:52'),
(4, NULL, 'Топливо', 'expense', '#795548', 'bi-fuel-pump', '2026-03-11 10:19:52'),
(5, NULL, 'Дом и коммуналка', 'expense', '#9C27B0', 'bi-house-door', '2026-03-11 10:19:52'),
(6, NULL, 'Интернет и связь', 'expense', '#3F51B5', 'bi-wifi', '2026-03-11 10:19:52'),
(7, NULL, 'Здоровье', 'expense', '#E91E63', 'bi-heart-pulse', '2026-03-11 10:19:52'),
(8, NULL, 'Одежда', 'expense', '#607D8B', 'bi-bag', '2026-03-11 10:19:52'),
(9, NULL, 'Развлечения', 'expense', '#FFC107', 'bi-controller', '2026-03-11 10:19:52'),
(10, NULL, 'Подарки', 'expense', '#F44336', 'bi-gift', '2026-03-11 10:19:52'),
(11, NULL, 'Путешествия', 'expense', '#00BCD4', 'bi-airplane', '2026-03-11 10:19:52'),
(12, NULL, 'Образование', 'expense', '#8BC34A', 'bi-mortarboard', '2026-03-11 10:19:52'),
(13, NULL, 'Ремонт', 'expense', '#9E9E9E', 'bi-hammer', '2026-03-11 10:19:52'),
(14, NULL, 'Питомцы', 'expense', '#673AB7', 'bi-suit-heart-fill', '2026-03-11 10:19:52'),
(15, NULL, 'Прочее', 'expense', '#BDBDBD', 'bi-tag', '2026-03-11 10:19:52'),
(16, NULL, 'Зарплата', 'income', '#2E7D32', 'bi-cash-coin', '2026-03-11 10:19:52'),
(17, NULL, 'Подработка', 'income', '#388E3C', 'bi-briefcase', '2026-03-11 10:19:52'),
(18, NULL, 'Подарок', 'income', '#7CB342', 'bi-gift', '2026-03-11 10:19:52'),
(19, NULL, 'Возврат', 'income', '#689F38', 'bi-arrow-repeat', '2026-03-11 10:19:52'),
(20, NULL, 'Прочий доход', 'income', '#558B2F', 'bi-piggy-bank', '2026-03-11 10:19:52'),
(21, 1, 'Детские расходы', 'expense', '#FF6F61', 'bi-emoji-smile', '2026-03-11 10:19:52'),
(22, 1, 'Накопления', 'income', '#009688', 'bi-piggy-bank', '2026-03-11 10:19:52');

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
(1, 'Семья Ивановых', '2026-03-11 10:19:52'),
(2, 'Семья администратора', '2026-03-11 10:23:46'),
(3, 'Семья пользователя', '2026-03-11 10:23:46');

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
(1, 1, 1, 'Алексей', 1, '2026-03-11 10:19:52'),
(2, 1, 1, 'Мария', 0, '2026-03-11 10:19:52'),
(3, 1, 1, 'София', 0, '2026-03-11 10:19:52'),
(4, 2, 2, 'Админ', 1, '2026-03-11 10:23:46'),
(5, 3, 3, 'Пользователь', 1, '2026-03-11 10:23:46');

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
(1, 15, '2026-03-11 10:19:52');

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
(1, 1, 1, 1, 16, 120000.00, '2025-03-01', 'Зарплата за март', 'Алексей', '2026-03-11 10:19:52'),
(2, 1, 1, 1, 17, 18000.00, '2025-03-05', 'Фриланс-проект', 'Алексей', '2026-03-11 10:19:52'),
(3, 1, 1, 1, 22, 5000.00, '2025-03-06', 'Перевод в накопления', 'Алексей', '2026-03-11 10:19:52'),
(4, 1, 1, 1, 1, -8500.00, '2025-03-02', 'Покупка продуктов на неделю', 'Мария', '2026-03-11 10:19:52'),
(5, 1, 1, 1, 2, -2300.00, '2025-03-03', 'Семейное кафе', 'Алексей', '2026-03-11 10:19:52'),
(6, 1, 1, 1, 3, -1200.00, '2025-03-04', 'Такси и автобус', 'Мария', '2026-03-11 10:19:52'),
(7, 1, 1, 1, 4, -4000.00, '2025-03-07', 'Заправка авто', 'Алексей', '2026-03-11 10:19:52'),
(8, 1, 1, 1, 5, -14500.00, '2025-03-08', 'Коммунальные платежи', 'Алексей', '2026-03-11 10:19:52'),
(9, 1, 1, 1, 6, -1200.00, '2025-03-08', 'Интернет и мобильная связь', 'Мария', '2026-03-11 10:19:52'),
(10, 1, 1, 1, 7, -3100.00, '2025-03-10', 'Аптека', 'Мария', '2026-03-11 10:19:52'),
(11, 1, 1, 1, 8, -5600.00, '2025-03-11', 'Одежда для ребёнка', 'Мария', '2026-03-11 10:19:52'),
(12, 1, 1, 1, 9, -1800.00, '2025-03-12', 'Кино и мороженое', 'Алексей', '2026-03-11 10:19:52'),
(13, 1, 1, 1, 10, -2500.00, '2025-03-13', 'Подарок другу', 'Алексей', '2026-03-11 10:19:52'),
(14, 1, 1, 1, 21, -4200.00, '2025-03-14', 'Игрушки и школьные товары', 'София', '2026-03-11 10:19:52'),
(15, 1, 1, 1, 1, -9300.00, '2025-03-16', 'Большая закупка в магазине', 'Мария', '2026-03-11 10:19:52'),
(16, 1, 1, 1, 11, -7000.00, '2025-03-18', 'Билеты на выходные', 'Алексей', '2026-03-11 10:19:52'),
(17, 1, 1, 1, 12, -3500.00, '2025-03-19', 'Онлайн-курс', 'Алексей', '2026-03-11 10:19:52'),
(18, 1, 1, 1, 13, -2200.00, '2025-03-21', 'Мелкий ремонт по дому', 'Алексей', '2026-03-11 10:19:52'),
(19, 1, 1, 1, 14, -1700.00, '2025-03-22', 'Корм для питомца', 'Мария', '2026-03-11 10:19:52'),
(20, 1, 1, 1, 18, 3000.00, '2025-03-25', 'Подарок от родителей', 'Мария', '2026-03-11 10:19:52'),
(21, 1, 1, 1, 19, 1500.00, '2025-03-26', 'Возврат за отменённый заказ', 'Алексей', '2026-03-11 10:19:52'),
(22, 1, 1, 1, 1, -4100.00, '2025-03-27', 'Продукты', 'Мария', '2026-03-11 10:19:52'),
(23, 1, 1, 1, 2, -1400.00, '2025-03-28', 'Кофе и десерт', 'Мария', '2026-03-11 10:19:52'),
(24, 1, 1, 1, 3, -900.00, '2025-03-29', 'Метро и автобус', 'Алексей', '2026-03-11 10:19:52'),
(25, 2, 2, 2, 16, 50000.00, '2026-03-11', 'Тестовый доход', 'Админ', '2026-03-11 10:25:10'),
(26, 2, 2, 2, 1, -3500.00, '2026-03-11', 'Покупка продуктов', 'Админ', '2026-03-11 10:25:10'),
(27, 3, 3, 3, 16, 25000.00, '2026-03-11', 'Тестовый доход', 'Пользователь', '2026-03-11 10:25:10'),
(28, 3, 3, 3, 3, -1200.00, '2026-03-11', 'Транспортные расходы', 'Пользователь', '2026-03-11 10:25:10');

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
(1, 'demo@familybudget.local', '$2a$10$7EqJtq98hPqEX7fNZaFWoOHi6m6mKz0z8uqb9qfL6P6rW8sELpG6W', 'Алексей', 1, '2026-03-11 10:19:52'),
(2, 'admin@myshop.local', '$2b$12$pFOZ5wBSN4v0euitgr9yIuclcpFlw2keJMt/MQReIgbhpbIUiXlVa', 'Админ', 2, '2026-03-11 10:23:46'),
(3, 'user@myshop.local', '$2b$12$pFOZ5wBSN4v0euitgr9yIuclcpFlw2keJMt/MQReIgbhpbIUiXlVa', 'Пользователь', 3, '2026-03-11 10:23:46');

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
-- AUTO_INCREMENT для сохранённых таблиц
--

--
-- AUTO_INCREMENT для таблицы `accounts`
--
ALTER TABLE `accounts`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT для таблицы `categories`
--
ALTER TABLE `categories`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=23;

--
-- AUTO_INCREMENT для таблицы `families`
--
ALTER TABLE `families`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT для таблицы `family_members`
--
ALTER TABLE `family_members`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT для таблицы `transactions`
--
ALTER TABLE `transactions`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=29;

--
-- AUTO_INCREMENT для таблицы `users`
--
ALTER TABLE `users`
  MODIFY `id` int(10) UNSIGNED NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Ограничения внешнего ключа сохраненных таблиц
--

--
-- Ограничения внешнего ключа таблицы `accounts`
--
ALTER TABLE `accounts`
  ADD CONSTRAINT `fk_accounts_family` FOREIGN KEY (`family_id`) REFERENCES `families` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

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
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
