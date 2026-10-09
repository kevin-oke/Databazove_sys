-- Active: 1790324121799@@127.0.0.1@5432@retail_sales
CREATE DATABASE retail_sales;

CREATE TABLE orders (
    order_id VARCHAR(20) PRIMARY KEY,
    customer_id VARCHAR(20) NOT NULL,
    product_id VARCHAR(20) NOT NULL,
    order_date DATE NOT NULL,
    region VARCHAR(20) NOT NULL,
    category VARCHAR(50) NOT NULL,
    ship_mode VARCHAR(30) NOT NULL,
    sales NUMERIC(10,2) NOT NULL,
    profit NUMERIC(10,2) NOT NULL
);

ALTER DATABASE retail_sales
SET datestyle TO 'ISO, MDY';

SELECT *
FROM orders;

CREATE PROCEDURE get_customer_sales(id_zakaznika VARCHAR(20))
LANGUAGE plpgsql
AS $procedures$
DECLARE
    sucet NUMERIC(10,2);
BEGIN

    SELECT SUM(sales)
    INTO sucet
    FROM orders
    WHERE customer_id = id_zakaznika;

    RAISE NOTICE 'id: %, celkový predaj: % ', id_zakaznika, sucet;

END;
$procedures$;

CALL get_customer_sales('CUST00001');

CREATE OR REPLACE PROCEDURE apply_regional_discount(
    region_name VARCHAR(20),
    discount_rate NUMERIC(10,2)
)
LANGUAGE plpgsql
AS $procedures$
BEGIN

    UPDATE orders
    SET sales = sales * (1 - discount_rate)
    WHERE region = region_name;

END;
$procedures$;

CALL apply_regional_discount('West', 0.10);


CREATE OR REPLACE PROCEDURE get_sales_between(
    start_date DATE,
    end_date DATE
)
LANGUAGE plpgsql
AS $procedures$
DECLARE
    celkove_sales NUMERIC(10,2);
BEGIN

    SELECT SUM(sales)
    INTO celkove_sales
    FROM orders
    WHERE order_date BETWEEN start_date AND end_date;

    RAISE NOTICE 'Začiatok: %, koniec: %, súčet: %', start_date, end_date, celkove_sales;

END;
$procedures$;

CALL get_sales_between('2024-01-01', '2024-03-31');