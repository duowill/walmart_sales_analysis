SHOW DATABASES;
USE walmart_db;

SELECT * FROM walmart;

--
SELECT COUNT(*) FROM walmart;

SELECT
	payment_method,
    COUNT(*)
FROM walmart
GROUP BY payment_method;

SELECT COUNT(DISTINCT branch)
FROM walmart;

SELECT MIN(quantity) FROM walmart;

-- Business Problems
-- Q1. Find the different payment methods and for each: number of transactions, number of qty sold

SELECT 
	payment_method,
    COUNT(*) AS no_payments,
    SUM(quantity) AS no_qty_sold
FROM walmart
GROUP BY payment_method;

-- Q2. Identify the highest-rated category in each branch, displaying the branch, category, average rating

SELECT
	branch,
    category,
    AVG(rating) AS avg_rating
FROM walmart
GROUP BY branch, category
ORDER BY branch, avg_rating DESC;

-- Q3. Identify the busiest day for each branch based on the number of transactions

SELECT *
FROM (
    SELECT 
        branch, 
        DAYNAME(STR_TO_DATE(date, '%d/%m/%y')) AS day_name,
        COUNT(*) AS no_transactions,
        RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS rank
    FROM walmart
    GROUP BY branch, day_name
)
WHERE rank = 1;

-- Q4. Calculate the total qty of items sold per payment method and list payment_method and total quantity. 

SELECT 
	payment_method,
--     COUNT(*) AS no_payments,
    SUM(quantity) AS no_qty_sold
FROM walmart
GROUP BY payment_method;

-- Q5. 
-- Determine the average, minimum and maximum rating of products for each city. 
-- List the city, average_rating, min_rating, and max_rating. 

SELECT 
	city,
    category,
    AVG(rating) AS avg_rating,
    MIN(rating) AS min_rating,
    MAX(rating) AS max_rating
FROM walmart
GROUP BY city, category;

-- Q6. 
-- Calculate the total profit for each category.
-- List category and total_profit, ordered from highest to lowest profit.

SELECT
	category,
    SUM(total * profit_margin) AS total_profit
FROM walmart
GROUP BY category
ORDER BY total_profit DESC;

-- Q7. 
-- Determine the most common payment method for each branch. 
-- List branch and the preferred_payment_method. 

WITH cte
AS
(SELECT
	branch,
    payment_method,
    COUNT(*) AS total_trans,
    RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS rank
FROM walmart
GROUP BY branch, payment_method
)
SELECT *
FROM cte
WHERE rank = 1;

-- Q8. 
-- For each branch, categorize sales in 3 groups: Morning, Afternoon, Evening. 
-- List branch, shift time, and number of invoices.

ALTER TABLE walmart 
ADD COLUMN formatted_time TIME;

UPDATE walmart
SET formatted_time = STR_TO_DATE(`time`, '%H:%i:%s');

SELECT
	branch,
    CASE 
        WHEN HOUR(formatted_time) < 12 THEN 'Morning'
        WHEN HOUR(formatted_time) BETWEEN 12 AND 17 THEN 'Afternoon'
        ELSE 'Evening'
    END shift_time,
    COUNT(*) AS no_invoices
FROM walmart
GROUP BY branch, shift_time
ORDER BY branch, no_invoices DESC;

-- Q9. 
-- Identify the 5 branches with the highest % decrease in revenue compared to last year.
-- List branch, last_year_revenue, current_year_revenue, pct_decrease_revenue
-- Use current year = 2023. Round to 2 decimal places.

-- rdr == last_rev-cr_rev/ls_rev*100 

SELECT
	YEAR(STR_TO_DATE(date, '%d/%m/%y')) AS formatted_year
FROM walmart;

WITH revenue_2022 -- 2022 sales
AS
(
	SELECT
		branch,
		sum(total) AS revenue 
	FROM walmart
	WHERE YEAR(STR_TO_DATE(date, '%d/%m/%y')) = 2022
	GROUP BY branch
),

revenue_2023 -- 2023 sales
AS
(
	SELECT
		branch,
		sum(total) AS revenue 
	FROM walmart
	WHERE YEAR(STR_TO_DATE(date, '%d/%m/%y')) = 2023
	GROUP BY branch
)

SELECT 
	last_yr_sales.branch,
    last_yr_sales.revenue AS last_year_revenue,
    current_yr_sales.revenue AS current_year_revenue,
	ROUND((CAST((last_yr_sales.revenue - current_yr_sales.revenue) AS DECIMAL(10,2)) / last_yr_sales.revenue) * 100, 2) AS pct_decrease_revenue
FROM 
	revenue_2022 AS last_yr_sales
JOIN 
	revenue_2023 current_yr_sales
ON
	last_yr_sales.branch = current_yr_sales.branch
WHERE 
	last_yr_sales.revenue > current_yr_sales.revenue
ORDER BY 
	pct_decrease_revenue DESC
LIMIT 5;