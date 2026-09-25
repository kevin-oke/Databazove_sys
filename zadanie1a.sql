-- Active: 1790324121799@@127.0.0.1@5432@superstore
CREATE DATABASE superstore;

CREATE TABLE customers (
    customer_id VARCHAR(20) PRIMARY KEY,
    customer_name VARCHAR(100),
    segment VARCHAR(50),
    country VARCHAR(50),
    region VARCHAR(50)
);

CREATE TABLE products (
    product_id VARCHAR(20) PRIMARY KEY,
    category VARCHAR(50),
    sub_category VARCHAR(50),
    product_name VARCHAR(100)
);

CREATE TABLE orders (
    order_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20),
    FOREIGN KEY (customer_id)
     REFERENCES customers (customer_id),
    product_id VARCHAR(20),
    FOREIGN KEY (product_id)
     REFERENCES products (product_id),
    order_date DATE,
    ship_date DATE,
    sales NUMERIC(10,2),
    quantity INT,
    discount NUMERIC(10,2),
    profit NUMERIC(10,2)
);

SELECT * FROM customers;

SELECT * FROM products;

SELECT * FROM orders;

SELECT o.order_id, c.customer_name, o.sales FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
WHERE o.sales > 500
ORDER BY o.sales DESC;

SELECT o.order_id, c.customer_name, p.category, o.sales FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN products p ON o.product_id = p.product_id;

SELECT c.region, SUM(o.sales) AS celkova_hodnota FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.region;

SELECT p.product_name, SUM(o.sales) AS celkova_hodnota FROM products p
LEFT JOIN orders o ON p.product_id = o.product_id
GROUP BY p.product_name;

SELECT c.customer_name, o.order_id, o.sales FROM orders o
FULL OUTER JOIN customers c ON o.customer_id = c.customer_id;

SELECT c.region, SUM(o.sales) AS pocet FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.region;

SELECT c.customer_name, COUNT(o.order_id) AS pocet FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_name;