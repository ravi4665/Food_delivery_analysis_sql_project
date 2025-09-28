
CREATE DATABASE IF NOT EXISTS food_delivery;

USE food_delivery;


--  CREATE TABLES


-- Customers
CREATE TABLE Customer (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    email VARCHAR(150),
    phone VARCHAR(20),
    city VARCHAR(100),
    state VARCHAR(100),
    country VARCHAR(100)
);

-- Restaurants
CREATE TABLE Restaurant (
    restaurant_id INT PRIMARY KEY,
    name VARCHAR(150),
    city VARCHAR(100),
    cuisine VARCHAR(100),
    rating DECIMAL(3,1)
);

-- Delivery Partners
CREATE TABLE DeliveryPartner (
    partner_id INT PRIMARY KEY,
    name VARCHAR(100),
    phone VARCHAR(20),
    vehicle_type VARCHAR(50),
    rating DECIMAL(3,1)
);

-- Menu Items
CREATE TABLE MenuItem (
    item_id INT PRIMARY KEY,
    restaurant_id INT,
    name VARCHAR(150),
    price DECIMAL(8,2),
    category VARCHAR(50),
    FOREIGN KEY (restaurant_id) REFERENCES Restaurant(restaurant_id)
);

-- Orders
CREATE TABLE Orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    restaurant_id INT,
    partner_id INT,
    order_date DATE,
    total_amount DECIMAL(10,2),
    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id),
    FOREIGN KEY (restaurant_id) REFERENCES Restaurant(restaurant_id),
    FOREIGN KEY (partner_id) REFERENCES DeliveryPartner(partner_id)
);

-- Order Details
CREATE TABLE OrderDetail (
    order_detail_id INT PRIMARY KEY,
    order_id INT,
    item_id INT,
    quantity INT,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (item_id) REFERENCES MenuItem(item_id)
);

select * from  Customer;

select * from  Restaurant ;

select * from  DeliveryPartner ;

select * from  MenuItem ;

select * from  Orders  ;

select * from  OrderDetail ;

-- =========================

-- Q1: List all customers with their city and country


SELECT first_name, last_name, city, country FROM Customer;

-- Q2: Find the top 5 highest-rated restaurants

SELECT name, cuisine, rating
FROM Restaurant
ORDER BY rating DESC
LIMIT 5;

-- Q3: Count how many orders each customer placed

SELECT c.first_name, c.last_name, COUNT(o.order_id) AS total_orders
FROM Customer c
JOIN Orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id
ORDER BY total_orders DESC;

-- Q4: Which restaurant generated the most revenue?

SELECT r.name, SUM(o.total_amount) AS total_revenue
FROM Restaurant r
JOIN Orders o ON r.restaurant_id = o.restaurant_id
GROUP BY r.restaurant_id
ORDER BY total_revenue DESC
LIMIT 1;

-- Q5: Find the most popular menu item

SELECT m.name, SUM(od.quantity) AS total_ordered
FROM MenuItem m
JOIN OrderDetail od ON m.item_id = od.item_id
GROUP BY m.item_id
ORDER BY total_ordered DESC
LIMIT 1;


-- Q6: Find the busiest delivery partner (most orders delivered)

SELECT d.name, COUNT(o.order_id) AS deliveries
FROM DeliveryPartner d
JOIN Orders o ON d.partner_id = o.partner_id
GROUP BY d.partner_id
ORDER BY deliveries DESC
LIMIT 1;

-- Q7: Which cuisine is most popular based on order count?

SELECT r.cuisine, COUNT(o.order_id) AS order_count
FROM Restaurant r
JOIN Orders o ON r.restaurant_id = o.restaurant_id
GROUP BY r.cuisine
ORDER BY order_count DESC
LIMIT 1;

-- Q8: Show total sales per day (top 5 days by revenue)

SELECT order_date, SUM(total_amount) AS sales
FROM Orders
GROUP BY order_date
ORDER BY sales DESC
LIMIT 5;

-- Q9: Find customers who spent more than 5000 in total

SELECT c.first_name, c.last_name, SUM(o.total_amount) AS total_spent
FROM Customer c
JOIN Orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id
HAVING total_spent > 5000
ORDER BY total_spent DESC;

-- Q10: Which city has the highest number of customers?

SELECT city, COUNT(*) AS customer_count
FROM Customer
GROUP BY city
ORDER BY customer_count DESC
LIMIT 1;

-- Q11: Which partner has the highest average delivery rating?

SELECT name, rating FROM DeliveryPartner
ORDER BY rating DESC
LIMIT 1;

-- Q12: Find the top 5 customers by total quantity of items ordered

SELECT c.first_name, c.last_name, SUM(od.quantity) AS total_items
FROM Customer c
JOIN Orders o ON c.customer_id = o.customer_id
JOIN OrderDetail od ON o.order_id = od.order_id
GROUP BY c.customer_id
ORDER BY total_items DESC
LIMIT 5;

-- Q13: Show top 5 restaurants with most menu items

SELECT r.name, COUNT(m.item_id) AS item_count
FROM Restaurant r
JOIN MenuItem m ON r.restaurant_id = m.restaurant_id
GROUP BY r.restaurant_id
ORDER BY item_count DESC
LIMIT 5;

-- Q14: Which category of food is most frequently ordered?

SELECT m.category, SUM(od.quantity) AS total_ordered
FROM MenuItem m
JOIN OrderDetail od ON m.item_id = od.item_id
GROUP BY m.category
ORDER BY total_ordered DESC
LIMIT 1;

-- Q15: Find the top 3 highest value orders with customer details

SELECT o.order_id, c.first_name, c.last_name, o.total_amount
FROM Orders o
JOIN Customer c ON o.customer_id = c.customer_id
ORDER BY o.total_amount DESC
LIMIT 3;


-- ADVANCED ANALYSIS QUERIES


-- Q1: Top 3 Customers by Spending (Using Window Function RANK)

SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    SUM(o.total_amount) AS total_spent,
    RANK() OVER (ORDER BY SUM(o.total_amount) DESC) AS rank_position
FROM Customer c
JOIN Orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC
LIMIT 3;


-- Q2: Monthly Sales Trend (Using DATE functions & GROUPING)

SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    SUM(total_amount) AS monthly_sales,
    COUNT(order_id) AS total_orders
FROM Orders
GROUP BY DATE_FORMAT(order_date, '%Y-%m')
ORDER BY month;


-- Q3: Most Popular Food Category Per City (Using CTE + RANK)

WITH category_rank AS (
    SELECT 
        c.city,
        m.category,
        SUM(od.quantity) AS total_ordered,
        RANK() OVER (PARTITION BY c.city ORDER BY SUM(od.quantity) DESC) AS rnk
    FROM Customer c
    JOIN Orders o ON c.customer_id = o.customer_id
    JOIN OrderDetail od ON o.order_id = od.order_id
    JOIN MenuItem m ON od.item_id = m.item_id
    GROUP BY c.city, m.category
)
SELECT city, category, total_ordered
FROM category_rank
WHERE rnk = 1;


-- Q4: Customer Lifetime Value (CLV) Analysis

SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS lifetime_value,
    ROUND(AVG(o.total_amount),2) AS avg_order_value
FROM Customer c
JOIN Orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY lifetime_value DESC
LIMIT 10;


-- Q5: Top 3 Restaurants per Cuisine (Using DENSE_RANK)

WITH cuisine_rank AS (
    SELECT 
        cuisine,
        name AS restaurant_name,
        SUM(o.total_amount) AS revenue,
        DENSE_RANK() OVER (PARTITION BY cuisine ORDER BY SUM(o.total_amount) DESC) AS rnk
    FROM Restaurant r
    JOIN Orders o ON r.restaurant_id = o.restaurant_id
    GROUP BY cuisine, restaurant_name
)
SELECT cuisine, restaurant_name, revenue
FROM cuisine_rank
WHERE rnk <= 3
ORDER BY cuisine, revenue DESC;

