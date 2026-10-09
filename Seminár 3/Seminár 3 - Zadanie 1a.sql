CREATE VIEW high_value_customers AS
SELECT c.customer_id, c.customer_name, SUM(o.sales) AS total_sales
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING SUM(o.sales) > 2000;

SELECT *
FROM high_value_customers;

CREATE VIEW regional_monthly_sales AS
SELECT c.region, DATE_TRUNC('month', o.order_date) AS month, SUM(o.sales) AS monthly_sales
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.region, DATE_TRUNC('month', o.order_date);

SELECT * FROM regional_monthly_sales
WHERE region = 'West';

CREATE VIEW analyst_orders AS
SELECT order_id, customer_id, product_id, sales, quantity, discount
FROM orders;

SELECT *
FROM analyst_orders;

CREATE INDEX idx_orders_customer_id
ON orders(customer_id);

SELECT * FROM orders
WHERE customer_id = 'C001';

CREATE INDEX idx_orders_order_date
ON orders(order_date);

SELECT DATE_TRUNC('month', order_date) AS month, SUM(sales) AS sum_month
FROM orders
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY DATE_TRUNC('month', order_date) ASC;

CREATE INDEX idx_orders_region_category
ON orders(customer_id, order_date);

SELECT o.order_id, c.customer_name ,c.region, o.profit
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
WHERE c.region = 'West' AND o.order_date >= '2024-01-01';

EXPLAIN ANALYZE
SELECT *
FROM orders
WHERE customer_id = 'C001';