-- Active: 1790324121799@@127.0.0.1@5432@superstore
WITH pomoc AS (
    SELECT c.customer_name, o.order_id, o.order_date, ROW_NUMBER() OVER (
        PARTITION BY c.customer_id
        ORDER BY o.order_date DESC
    ) AS num_row
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
)
SELECT * FROM pomoc
WHERE num_row < 3
ORDER BY customer_name, num_row;

WITH pomoc AS (
    SELECT customer_id, SUM(profit) AS total_profit
    FROM orders
    GROUP BY customer_id
),
pomoc2 AS(
    SELECT c.region, c.customer_name, p.customer_id, p.total_profit, RANK() OVER(
        PARTITION BY c.region
        ORDER BY p.total_profit DESC
    ) AS rank, DENSE_RANK() OVER(
        PARTITION BY c.region
        ORDER BY p.total_profit DESC
    ) AS dense_profit_rank
    FROM pomoc p
    INNER JOIN customers c ON p.customer_id = c.customer_id
)
SELECT * FROM pomoc2;

WITH pomoc AS (
    SELECT customer_id, SUM(sales) AS total_sales
    FROM orders
    GROUP BY customer_id
)
SELECT c.customer_name, p.total_sales, NTILE(4) OVER (
    ORDER BY p.total_sales DESC
    ) AS quartile
FROM pomoc p
INNER JOIN customers c ON p.customer_id = c.customer_id;

WITH pomoc AS (
    SELECT DATE_TRUNC('month', order_date) AS month, SUM(sales) AS monthly_sales
    FROM orders
    GROUP BY DATE_TRUNC('month', order_date)
),
pomoc2 AS (
     SELECT month, monthly_sales, LAG(monthly_sales, 1) OVER (
        ORDER BY month
     ) AS prev_month_sales, LEAD(monthly_sales, 1) OVER(
        ORDER BY month
     ) AS next_month_sales
     FROM pomoc
)
SELECT * FROM pomoc2
ORDER BY month ASC;

WITH product_totals AS (
    SELECT p.category, p.product_name, SUM(o.sales) AS product_sales
    FROM orders o
    INNER JOIN products p ON o.product_id = p.product_id
    GROUP BY p.category, p.product_name
)
SELECT category, product_name, product_sales, SUM(product_sales) OVER (
    PARTITION BY category
    ) AS category_total, ROUND(
        product_sales * 100.0 / SUM(product_sales) OVER (
            PARTITION BY category
        ),2
    ) AS pct_of_category
FROM product_totals
ORDER BY category, product_name;

WITH pomoc AS (
    SELECT c.customer_id, c.customer_name, MAX(o.order_date) OVER (
        PARTITION BY c.customer_id
        ) AS last_order_date, MAX(o.order_date) OVER () AS latest_order_date
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
)
SELECT DISTINCT customer_id, customer_name, last_order_date
FROM pomoc
WHERE last_order_date < latest_order_date - INTERVAL '90 days'
ORDER BY last_order_date ASC;