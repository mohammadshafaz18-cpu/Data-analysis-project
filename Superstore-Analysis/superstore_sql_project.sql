# Creating Database
CREATE database superstore_project;
USE superstore_project;

# After Importing a table checking for that table

SELECT * FROM superstore_raw;

# Data Cleaning
describe superstore_raw;

## Checking for Null values
SELECT
COUNT(*) - COUNT(`Order ID`) AS order_id_nulls,
COUNT(*) - COUNT(`Customer Name`) AS customer_name_nulls,
COUNT(*) - COUNT(`Product Name`) AS product_name_nulls,
COUNT(*) - COUNT(Sales) AS sales_nulls,
COUNT(*) - COUNT(Quantity) AS quantity_nulls,
COUNT(*) - COUNT(Profit) AS profit_nulls
FROM superstore_raw;

# Checking for duplicate values
SELECT `Order ID`, COUNT(*)
FROM superstore_raw
GROUP BY `Order ID`
HAVING COUNT(*) > 1;

### Checking whether sales have negative values
SELECT *
FROM superstore_raw
WHERE Sales < 0;

SELECT *
FROM superstore_raw
WHERE Quantity <= 0;

# Data Normalization

## Creating customer table

CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_name VARCHAR(150),
    segment VARCHAR(50),
    country VARCHAR(50),
    city VARCHAR(50),
    state VARCHAR(50),
    region VARCHAR(50)
);

## Inserting into customers

INSERT INTO customers
(customer_id, customer_name, segment, country, city, state, region)
SELECT
`Customer ID`,
MIN(`Customer Name`),
MIN(Segment),
MIN(Country),
MIN(City),
MIN(State),
MIN(Region)
FROM superstore_raw
GROUP BY `Customer ID`;

SELECT COUNT(*) FROM customers;

## creating products

CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_name VARCHAR(200),
    category VARCHAR(100),
    sub_category VARCHAR(100)
);

## Inserting

INSERT INTO products
(product_id, product_name, category, sub_category)
SELECT
`Product ID`,
MIN(`Product Name`),
MIN(Category),
MIN(`Sub-Category`)
FROM superstore_raw
GROUP BY `Product ID`;

SELECT COUNT(*) FROM products;

## Creating orders

CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    order_date DATE,
    ship_date DATE,
    ship_mode VARCHAR(50),
    customer_id VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);


INSERT INTO orders
(order_id, order_date, ship_date, ship_mode, customer_id)
SELECT
`Order ID`,
STR_TO_DATE(MIN(`Order Date`), '%m/%d/%Y'),
STR_TO_DATE(MIN(`Ship Date`), '%m/%d/%Y'),
MIN(`Ship Mode`),
`Customer ID`
FROM superstore_raw
GROUP BY `Order ID`, `Customer ID`;

SELECT COUNT(*) FROM orders;

## Creating order_details

CREATE TABLE order_details (
    row_id INT PRIMARY KEY,
    order_id VARCHAR(50),
    product_id VARCHAR(50),
    sales DECIMAL(10,2),
    quantity INT,
    discount DECIMAL(5,2),
    profit DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

## Insering transactional data

INSERT INTO order_details
(row_id, order_id, product_id, sales, quantity, discount, profit)
SELECT
`Row ID`,
`Order ID`,
`Product ID`,
Sales,
Quantity,
Discount,
Profit
FROM superstore_raw;

SELECT COUNT(*) FROM order_details;

SHOW WARNINGS;

## Checking for NULL values from all tables
SELECT *
FROM customers
WHERE customer_id IS NULL;
SELECT *
FROM customers
WHERE customer_name IS NULL;

SELECT *
FROM products
WHERE product_id IS NULL;

SELECT *
FROM orders
WHERE order_id IS NULL
OR customer_id IS NULL;

SELECT *
FROM order_details
WHERE order_id IS NULL
OR product_id IS NULL;

## Checking for duplucate values 

SELECT customer_id, COUNT(*)
FROM customers
GROUP BY customer_id
HAVING COUNT(*) > 1;

SELECT product_id, COUNT(*)
FROM products
GROUP BY product_id
HAVING COUNT(*) > 1;

SELECT order_id, COUNT(*)
FROM orders
GROUP BY order_id
HAVING COUNT(*) > 1;

SELECT row_id, COUNT(*)
FROM order_details
GROUP BY row_id
HAVING COUNT(*) > 1;

### Check for broken relationship
SELECT *
FROM order_details od
LEFT JOIN orders o ON od.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT *
FROM order_details od
LEFT JOIN products p ON od.product_id = p.product_id
WHERE p.product_id IS NULL;


# DATA ANALYSIS

## Total Sales Per Customer

SELECT 
c.customer_name,
SUM(od.sales) AS total_sales
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id = od.order_id
GROUP BY c.customer_name
ORDER BY total_sales DESC;

## Top 10 Customers

SELECT 
c.customer_name,
SUM(od.sales) AS total_sales
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id = od.order_id
GROUP BY c.customer_name
ORDER BY total_sales DESC
LIMIT 10;

## Total Sales by Product

SELECT 
p.product_name,
SUM(od.sales) AS total_sales
FROM products p
JOIN order_details od ON p.product_id = od.product_id
GROUP BY p.product_name
ORDER BY total_sales DESC;

## Top 10 Product by Sales

SELECT 
p.product_name,
SUM(od.sales) AS total_sales
FROM products p
JOIN order_details od 
ON p.product_id = od.product_id
GROUP BY p.product_name
ORDER BY total_sales DESC
LIMIT 10;

## Sales by Region

SELECT 
c.region,
SUM(od.sales) AS total_sales
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id = od.order_id
GROUP BY c.region
ORDER BY total_sales DESC;

## Monthly sales trend

SELECT 
YEAR(o.order_date) AS year,
MONTH(o.order_date) AS month,
SUM(od.sales) AS total_sales
FROM orders o
JOIN order_details od ON o.order_id = od.order_id
GROUP BY year, month
ORDER BY year, month;

## Top 10 most profitable products

SELECT 
p.product_name,
SUM(od.profit) AS total_profit
FROM products p
JOIN order_details od ON p.product_id = od.product_id
GROUP BY p.product_name
ORDER BY total_profit DESC
LIMIT 10;


## Top 10 Customer by profit

SELECT 
c.customer_name,
SUM(od.profit) AS total_profit
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_details od ON o.order_id = od.order_id
GROUP BY c.customer_name
ORDER BY total_profit DESC
LIMIT 10;

## Salesby category

SELECT 
p.category,
SUM(od.sales) AS total_sales
FROM products p
JOIN order_details od ON p.product_id = od.product_id
GROUP BY p.category
ORDER BY total_sales DESC;

## Profit margin by category

SELECT 
p.category,
SUM(od.profit) / SUM(od.sales) * 100 AS profit_margin
FROM products p
JOIN order_details od ON p.product_id = od.product_id
GROUP BY p.category;


## Average order values

SELECT 
AVG(order_total) AS avg_order_value
FROM (
    SELECT 
    o.order_id,
    SUM(od.sales) AS order_total
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    GROUP BY o.order_id
) t;


## Loss Making product

SELECT 
p.product_name,
SUM(od.profit) AS total_profit
FROM products p
JOIN order_details od ON p.product_id = od.product_id
GROUP BY p.product_name
HAVING total_profit < 0
ORDER BY total_profit;

