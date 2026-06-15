CREATE DATABASE UserBehavioral;
USE UserBehavioral;

-- 1. DROP EXTANT TABLES TO PRESERVE SCHEMA INTEGRITY
DROP TABLE IF EXISTS web_logs;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS users;

-- 2. CREATE SCHEMAS WITH STRICT CONSTRAINTS
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100) UNIQUE,
    signup_date DATE NOT NULL,
    country VARCHAR(50)
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10, 2),
    stock_quantity INT
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    user_id INT,
    order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE order_items (
    item_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    price_per_unit DECIMAL(10, 2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE web_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    product_id INT,
    session_id VARCHAR(50),
    event_type VARCHAR(20), -- 'view', 'add_to_cart', 'purchase'
    event_timestamp DATETIME,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- 3. CREATE PERFORMANCE OPTIMIZATION INDEXES (B-TREE)
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_web_logs_timestamp ON web_logs(event_timestamp);
CREATE INDEX idx_order_items_prod ON order_items(product_id);

-- 4. SEED SIMULATED HIGH-VOLUME DATASETS
INSERT INTO users VALUES 
(1, 'Alice Smith', 'alice@email.com', '2025-01-15', 'USA'),
(2, 'Bob Jones', 'bob@email.com', '2025-02-20', 'Canada'),
(3, 'Charlie Brown', 'charlie@email.com', '2025-03-05', 'USA'),
(4, 'Diana Prince', 'diana@email.com', '2025-03-12', 'UK'),
(5, 'Evan Wright', 'evan@email.com', '2025-04-01', 'Germany');

INSERT INTO products VALUES 
(101, 'iPhone 15 Pro', 'Electronics', 999.99, 50),
(102, 'AirPods Pro', 'Electronics', 249.99, 150),
(103, 'Leather Wallet', 'Accessories', 49.99, 200),
(104, 'Running Shoes', 'Apparel', 120.00, 80),
(105, 'Coffee Maker', 'Home', 89.95, 30);

INSERT INTO orders VALUES 
(1001, 1, '2026-01-20 10:00:00', 'Completed'),
(1002, 2, '2026-01-22 14:30:00', 'Completed'),
(1003, 1, '2026-02-15 09:15:00', 'Completed'),
(1004, 3, '2026-02-28 18:00:00', 'Cancelled'),
(1005, 4, '2026-03-02 11:00:00', 'Completed'),
(1006, 5, '2026-03-10 16:45:00', 'Completed'),
(1007, 1, '2026-03-15 13:00:00', 'Completed');

INSERT INTO order_items VALUES 
(1, 1001, 101, 1, 999.99),
(2, 1001, 102, 2, 249.99),
(3, 1002, 103, 1, 49.99),
(4, 1003, 102, 1, 249.99),
(5, 1004, 101, 1, 999.99),
(6, 1005, 104, 2, 120.00),
(7, 1006, 105, 1, 89.95),
(8, 1007, 103, 3, 49.99);

INSERT INTO web_logs (user_id, product_id, session_id, event_type, event_timestamp) VALUES
(1, 101, 'S_001', 'view', '2026-01-20 09:45:00'),
(1, 101, 'S_001', 'add_to_cart', '2026-01-20 09:50:00'),
(1, 102, 'S_001', 'view', '2026-01-20 09:52:00'),
(1, 102, 'S_001', 'purchase', '2026-01-20 10:00:00'),
(2, 103, 'S_002', 'view', '2026-01-22 14:20:00'),
(2, 103, 'S_002', 'purchase', '2026-01-22 14:30:00'),
(1, 102, 'S_003', 'purchase', '2026-02-15 09:15:00'),
(3, 101, 'S_004', 'purchase', '2026-02-28 18:00:00');
