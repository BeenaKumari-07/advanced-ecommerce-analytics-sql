-- ADVANCED COMPREHENSIVE BI ANALYTICAL QUERY BUNDLE
-- -------------------------------------------------------------------------
-- USER BEHAVIOR & REVENUE METRICS ENGINE (REFACTORED)
-- -------------------------------------------------------------------------
WITH TransactionalBase AS (
    SELECT 
        o.order_id,
        o.user_id,
        o.order_date,
        o.status,
        oi.product_id,
        (oi.quantity * oi.price_per_unit) AS line_item_revenue,
        p.category,
        p.product_name
    FROM orders o
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    INNER JOIN products p ON oi.product_id = p.product_id
),
OrderLevelBase AS (
    SELECT 
        user_id,
        order_id,
        order_date,
        SUM(line_item_revenue) AS total_order_revenue
    FROM TransactionalBase
    WHERE status = 'Completed'
    GROUP BY user_id, order_id, order_date
),
CustomerWindowMetrics AS (
    SELECT 
        olb.user_id,
        olb.order_id,
        olb.order_date,
        olb.total_order_revenue,
        SUM(olb.total_order_revenue) OVER(
            PARTITION BY olb.user_id 
            ORDER BY olb.order_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_total_spend,
        ROW_NUMBER() OVER(PARTITION BY olb.user_id ORDER BY olb.order_date) AS user_purchase_sequence,
        LAG(olb.order_date) OVER(PARTITION BY olb.user_id ORDER BY olb.order_date) AS previous_purchase_date
    FROM OrderLevelBase olb
),
PivotedCategoryMatrix AS (
    SELECT 
        user_id,
        SUM(CASE WHEN category = 'Electronics' THEN line_item_revenue ELSE 0 END) AS electronics_spend,
        SUM(CASE WHEN category = 'Accessories' THEN line_item_revenue ELSE 0 END) AS accessories_spend,
        SUM(CASE WHEN category = 'Apparel' THEN line_item_revenue ELSE 0 END) AS apparel_spend,
        SUM(line_item_revenue) AS total_customer_spend
    FROM TransactionalBase
    WHERE status = 'Completed'
    GROUP BY user_id
),
ClickstreamMetrics AS (
    SELECT 
        user_id,
        COUNT(CASE WHEN event_type = 'view' THEN 1 END) AS total_product_views,
        COUNT(CASE WHEN event_type = 'add_to_cart' THEN 1 END) AS total_cart_additions
    FROM web_logs
    GROUP BY user_id
)
SELECT 
    u.user_id,
    u.name,
    u.country,
    COALESCE(pm.total_customer_spend, 0.00) AS total_lifetime_value,
    COALESCE(pm.electronics_spend, 0.00) AS total_electronics_spend,
    CASE 
        WHEN pm.total_customer_spend >= 1000 THEN 'VIP Tier'
        WHEN pm.total_customer_spend >= 200 THEN 'Regular Tier'
        ELSE 'Casual Tier'
    END AS customer_value_segment,
    TIMESTAMPDIFF(DAY, cwm.previous_purchase_date, cwm.order_date) AS days_between_first_and_second_purchase,
    ROUND((COALESCE(cm.total_cart_additions, 0) / NULLIF(cm.total_product_views, 0)), 2) AS cart_conversion_rate
FROM users u
LEFT JOIN PivotedCategoryMatrix pm ON u.user_id = pm.user_id
LEFT JOIN CustomerWindowMetrics cwm ON u.user_id = cwm.user_id AND cwm.user_purchase_sequence = 2
LEFT JOIN ClickstreamMetrics cm ON u.user_id = cm.user_id
ORDER BY total_lifetime_value DESC;


-- -------------------------------------------------------------------------
-- PHASE 1: ADVANCED AGGREGATIONS & COHORT TRACKING
-- -------------------------------------------------------------------------

-- Query 1: Month-over-Month (MoM) Revenue Growth Rate
SELECT 
    DATE_FORMAT(o.order_date, '%Y-%m-01') AS business_month,
    SUM(oi.quantity * oi.price_per_unit) AS current_month_revenue,
    LAG(SUM(oi.quantity * oi.price_per_unit)) OVER (
        ORDER BY DATE_FORMAT(o.order_date, '%Y-%m-01')
    ) AS previous_month_revenue,
    ROUND(((SUM(oi.quantity * oi.price_per_unit) - LAG(SUM(oi.quantity * oi.price_per_unit)) OVER (ORDER BY DATE_FORMAT(o.order_date, '%Y-%m-01'))) / 
        NULLIF(LAG(SUM(oi.quantity * oi.price_per_unit)) OVER (ORDER BY DATE_FORMAT(o.order_date, '%Y-%m-01')), 0)) * 100, 2) AS mom_growth_percentage
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'Completed'
GROUP BY DATE_FORMAT(o.order_date, '%Y-%m-01')
ORDER BY business_month;

-- Query 2: Customer Retention Cohorts (First vs. Repeat Purchase)
WITH OrderSequence AS (
    SELECT user_id, order_date, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY order_date) AS purchase_number
    FROM orders WHERE status = 'Completed'
)
SELECT 
    DATE_FORMAT(order_date, '%Y-%m-01') AS cohort_month,
    COUNT(CASE WHEN purchase_number = 1 THEN 1 END) AS new_customers,
    COUNT(CASE WHEN purchase_number > 1 THEN 1 END) AS returning_customers
FROM OrderSequence
GROUP BY DATE_FORMAT(order_date, '%Y-%m-01')
ORDER BY cohort_month;

-- Query 3: High-Value Product Category Affinity Matrix
SELECT p1.category AS primary_category, p2.category AS secondary_category, COUNT(DISTINCT oi1.order_id) AS joint_orders_count
FROM order_items oi1
JOIN order_items oi2 ON oi1.order_id = oi2.order_id AND oi1.product_id < oi2.product_id
JOIN products p1 ON oi1.product_id = p1.product_id
JOIN products p2 ON oi2.product_id = p2.product_id
GROUP BY p1.category, p2.category
ORDER BY joint_orders_count DESC LIMIT 5;

-- Query 4: Top 2 Transacting Customers per Country (Without Gaps)
WITH RankedUsers AS (
    SELECT u.country, u.user_id, u.name, SUM(oi.quantity * oi.price_per_unit) AS total_spent,
           DENSE_RANK() OVER (PARTITION BY u.country ORDER BY SUM(oi.quantity * oi.price_per_unit) DESC) AS ranking
    FROM users u
    JOIN orders o ON u.user_id = o.user_id
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Completed'
    GROUP BY u.country, u.user_id, u.name
)
SELECT country, user_id, name, total_spent FROM RankedUsers WHERE ranking <= 2;

-- Query 5: Identifying Average Days to First Purchase Post-Signup
WITH FirstPurchases AS (
    SELECT user_id, MIN(order_date) AS first_order_time FROM orders WHERE status = 'Completed' GROUP BY user_id
)
SELECT u.country, COUNT(fp.user_id) AS converted_users, ROUND(AVG(TIMESTAMPDIFF(DAY, u.signup_date, fp.first_order_time)), 1) AS avg_days_to_convert
FROM users u
JOIN FirstPurchases fp ON u.user_id = fp.user_id
GROUP BY u.country;


-- -------------------------------------------------------------------------
-- PHASE 2: WINDOW FUNCTIONS & ANALYTICAL DEPTH
-- -------------------------------------------------------------------------

-- Query 6: Rolling 3-Order Revenue Moving Average per User (Resolved Namespace Collision)
WITH OrderRevenues AS (
    SELECT o.user_id, o.order_id, o.order_date, SUM(oi.quantity * oi.price_per_unit) AS current_order_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.user_id, o.order_id, o.order_date
)
SELECT user_id, order_id, order_date, current_order_revenue,
       ROUND(AVG(current_order_revenue) OVER (PARTITION BY user_id ORDER BY order_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS rolling_avg_revenue
FROM OrderRevenues;

-- Query 7: Find the "Pareto Principle" (Products generating top 80% revenue)
WITH ProductRevenue AS (
    SELECT product_id, SUM(quantity * price_per_unit) AS total_revenue FROM order_items GROUP BY product_id
),
RunningPercentages AS (
    SELECT product_id, total_revenue,
           SUM(total_revenue) OVER (ORDER BY total_revenue DESC) AS running_cumulative_rev,
           SUM(total_revenue) OVER () AS total_platform_rev
    FROM ProductRevenue
)
SELECT product_id, total_revenue, ROUND((running_cumulative_rev / total_platform_rev) * 100, 2) AS cumulative_revenue_percentage
FROM RunningPercentages
WHERE (running_cumulative_rev - total_revenue) / total_platform_rev <= 0.80
ORDER BY total_revenue DESC;

-- Query 8: User Session Clickstream Funnel Analysis
SELECT session_id,
    COUNT(CASE WHEN event_type = 'view' THEN 1 END) AS views,
    COUNT(CASE WHEN event_type = 'add_to_cart' THEN 1 END) AS cart_adds,
    COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) AS purchases,
    CASE WHEN COUNT(CASE WHEN event_type = 'view' THEN 1 END) > 0 THEN 1 ELSE 0 END AS reached_step_1,
    CASE WHEN COUNT(CASE WHEN event_type = 'add_to_cart' THEN 1 END) > 0 THEN 1 ELSE 0 END AS reached_step_2,
    CASE WHEN COUNT(CASE WHEN event_type = 'purchase' THEN 1 END) > 0 THEN 1 ELSE 0 END AS reached_step_3
FROM web_logs GROUP BY session_id;

-- Query 9: Finding Users with Consecutive Day Activity
WITH UniqueDailyLogins AS (
    SELECT DISTINCT user_id, CAST(event_timestamp AS DATE) AS login_date FROM web_logs
),
NextLogins AS (
    SELECT user_id, login_date, LEAD(login_date) OVER (PARTITION BY user_id ORDER BY login_date) AS next_login_date FROM UniqueDailyLogins
)
SELECT DISTINCT user_id FROM NextLogins WHERE next_login_date = DATE_ADD(login_date, INTERVAL 1 DAY);

-- Query 10: Items Adding to Cart But Frequently Cancelled/Abandoned
SELECT p.product_id, p.product_name, COUNT(DISTINCT wl.log_id) AS total_cart_additions, COUNT(DISTINCT oi.item_id) AS confirmed_purchased_items,
    (COUNT(DISTINCT wl.log_id) - COUNT(DISTINCT oi.item_id)) AS abandoned_volume,
    ROUND(((COUNT(DISTINCT wl.log_id) - COUNT(DISTINCT oi.item_id)) / COUNT(DISTINCT wl.log_id)) * 100, 2) AS abandonment_rate
FROM products p
JOIN web_logs wl ON p.product_id = wl.product_id AND wl.event_type = 'add_to_cart'
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name ORDER BY abandonment_rate DESC;


-- -------------------------------------------------------------------------
-- PHASE 3: COMPLEX ANALYTICS & DATA MANIPULATION
-- -------------------------------------------------------------------------

-- 11. RFM Deployment Logic (Recency, Frequency, Monetary scoring)
WITH CustomerMetrics AS (
    SELECT 
        user_id,
        MAX(order_date) AS last_purchase_date,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(quantity * price_per_unit) AS total_monetary_value
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'Completed'
    GROUP BY user_id
)
SELECT 
    user_id,
    NTILE(5) OVER (ORDER BY last_purchase_date ASC) AS recency_score,
    NTILE(5) OVER (ORDER BY total_orders DESC) AS frequency_score,
    NTILE(5) OVER (ORDER BY total_monetary_value DESC) AS monetary_score
FROM CustomerMetrics;

-- 12. Recursive Query for Inventory Running Balance (Simulated Loop)
WITH RECURSIVE HistoricalStock AS (
    -- Anchor Member
    SELECT 
        product_id,
        stock_quantity AS computed_stock,
        CAST(NOW() AS DATETIME) AS calculation_step
    FROM products WHERE product_id = 101
    
    UNION ALL
    
    -- Recursive Member
    SELECT 
        hs.product_id,
        hs.computed_stock - 1,
        DATE_ADD(hs.calculation_step, INTERVAL 1 HOUR)
    FROM HistoricalStock hs
    WHERE hs.computed_stock > 45
)
SELECT * FROM HistoricalStock;

-- 13. Advanced String Cleansing & Anonymization Engine
SELECT 
    user_id,
    name,
    CONCAT(
        SUBSTRING(email, 1, 2),
        '******@',
        SUBSTRING(email, LOCATE('@', email) + 1)
    ) AS anonymized_email_string,
    UPPER(TRIM(country)) AS cleaned_country_code
FROM users;

-- 14. Correlated Corrupt-Log Identification (Outliers)
SELECT wl.user_id, wl.session_id, wl.event_timestamp
FROM web_logs wl
WHERE wl.event_timestamp > (
    SELECT DATE_ADD(AVG(orders.order_date), INTERVAL 30 DAY)
    FROM orders 
    WHERE orders.user_id = wl.user_id
)
ORDER BY wl.event_timestamp DESC;

-- 15. Real-time Status Switching Duration Log Tracking
SELECT 
    order_id,
    status AS current_logged_status,
    order_date AS step_start_time,
    LEAD(order_date) OVER (PARTITION BY order_id ORDER BY order_date) AS step_end_time,
    TIMESTAMPDIFF(SECOND, order_date, LEAD(order_date) OVER (PARTITION BY order_id ORDER BY order_date)) AS seconds_spent_in_phase
FROM orders
ORDER BY order_id, order_date;
    
