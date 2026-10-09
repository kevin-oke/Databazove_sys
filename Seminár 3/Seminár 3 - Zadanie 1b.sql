-- Active: 1790324121799@@127.0.0.1@5432@datacrafttinglab_db
WITH daily_sales AS (
    SELECT EXTRACT(DAY FROM sale_date) AS days, SUM(total_amount) AS total, sale_date
    FROM flourmills_sales
    GROUP BY sale_date
)
SELECT sale_date, total
FROM daily_sales
WHERE total > 3000000
ORDER BY total DESC;

WITH category_sales AS (
    SELECT product_category, SUM(total_amount) AS total
    FROM flourmills_sales
    GROUP BY product_category
)
SELECT product_category, total
FROM category_sales
ORDER BY total DESC;

WITH total_product_sales AS (
    SELECT product_category, product_name, SUM(total_amount) AS total
    FROM flourmills_sales
    GROUP BY product_category, product_name
),
category_rank AS (
    SELECT product_category, total, RANK() OVER (PARTITION BY product_category ORDER BY total DESC) AS c_rank
    FROM total_product_sales
)
SELECT * FROM category_rank
WHERE c_rank = 1 OR c_rank = 2 OR c_rank = 3
ORDER BY product_category, c_rank;

WITH CTE1 AS (
    SELECT customer_type, SUM(total_amount) AS revenue
    FROM flourmills_sales
    GROUP BY customer_type
),
CTE2 AS (
    SELECT customer_type, revenue, SUM(revenue) OVER () AS total_revenue,
    ROUND(revenue * 100.0 / SUM(revenue) OVER (), 2) AS revenue_percentage
    FROM CTE1
)
SELECT customer_type, revenue, total_revenue, revenue_percentage
FROM CTE2
ORDER BY revenue DESC;

WITH CTE1 AS(
    SELECT customer_id, product_name, sale_date, total_amount, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY sale_date DESC) AS poradie
    FROM flourmills_sales
)
SELECT * FROM CTE1
WHERE poradie = 1
ORDER BY customer_id ASC;

WITH RECURSIVE date_range AS (
    SELECT MIN(sale_date) AS start_date, MAX(sale_date) AS end_date
    FROM flourmills_sales
),
dates AS (
    SELECT start_date AS sale_date
    FROM date_range

    UNION ALL

    SELECT sale_date + 1
    FROM dates
    CROSS JOIN date_range
    WHERE sale_date < end_date
)
SELECT sale_date
FROM dates
ORDER BY sale_date ASC;

WITH RECURSIVE CTE1 AS (
    SELECT DATE_TRUNC('month', sale_date) AS month, SUM(total_amount) AS revenue
    FROM flourmills_sales
    GROUP BY month
),
CTE2 AS (
    SELECT ROW_NUMBER() OVER(ORDER BY month) AS rn, month, revenue
    FROM CTE1
),
CTE3 AS (
    SELECT rn, month, revenue, revenue AS cumulative_revenue
    FROM CTE2
    WHERE rn = 1

    UNION ALL

    SELECT rn, month, revenue, cumulative_revenue + revenue
    FROM CTE3
    WHERE cumulative_revenue = 500000000
)
SELECT * FROM CTE3
ORDER BY rn
LIMIT 1;