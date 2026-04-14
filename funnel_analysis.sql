-- ================================================
-- OLIST E-COMMERCE FUNNEL & RETENTION ANALYSIS
-- Author: Esha Sharma
-- Dataset: Brazilian E-Commerce Public Dataset (Olist)
-- ================================================

USE olist_db;

-- ------------------------------------------------
-- QUERY 1: Order Status Breakdown
-- ------------------------------------------------
SELECT 
    order_status,
    COUNT(*) as total_orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- ------------------------------------------------
-- QUERY 2: Purchase Funnel - Stage Counts
-- ------------------------------------------------
SELECT
    'Step 1 - Orders Placed' as funnel_stage,
    COUNT(*) as order_count
FROM orders

UNION ALL

SELECT 'Step 2 - Payment Confirmed',
    COUNT(DISTINCT o.order_id)
FROM orders o
JOIN order_payments op ON o.order_id = op.order_id

UNION ALL

SELECT 'Step 3 - Shipped',
    COUNT(*)
FROM orders
WHERE order_delivered_carrier_date IS NOT NULL

UNION ALL

SELECT 'Step 4 - Delivered',
    COUNT(*)
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;

-- ------------------------------------------------
-- QUERY 3: Funnel Drop-off Percentages
-- ------------------------------------------------
SELECT
    funnel_stage,
    order_count,
    LAG(order_count) OVER (ORDER BY stage_order) as previous_stage,
    ROUND(
        (order_count - LAG(order_count) OVER (ORDER BY stage_order)) * 100.0 / 
        LAG(order_count) OVER (ORDER BY stage_order), 2
    ) as drop_off_pct
FROM (
    SELECT 'Step 1 - Orders Placed' as funnel_stage, 
        COUNT(*) as order_count, 1 as stage_order 
    FROM orders
    
    UNION ALL
    
    SELECT 'Step 2 - Payment Confirmed', 
        COUNT(DISTINCT o.order_id), 2
    FROM orders o 
    JOIN order_payments op ON o.order_id = op.order_id
    
    UNION ALL
    
    SELECT 'Step 3 - Shipped', COUNT(*), 3
    FROM orders 
    WHERE order_delivered_carrier_date IS NOT NULL
    
    UNION ALL
    
    SELECT 'Step 4 - Delivered', COUNT(*), 4
    FROM orders 
    WHERE order_delivered_customer_date IS NOT NULL
) funnel;

-- ------------------------------------------------
-- QUERY 4: Revenue by Product Category (Top 10)
-- ------------------------------------------------
SELECT 
    p.product_category_name_english as category,
    ROUND(SUM(op.payment_value), 2) as total_revenue,
    COUNT(DISTINCT op.order_id) as total_orders,
    ROUND(AVG(op.payment_value), 2) as avg_order_value
FROM order_payments op
JOIN order_items oi ON op.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE p.product_category_name_english IS NOT NULL
GROUP BY p.product_category_name_english
ORDER BY total_revenue DESC
LIMIT 10;

-- ------------------------------------------------
-- QUERY 5: Monthly Order Trends
-- ------------------------------------------------
SELECT 
    DATE_FORMAT(order_purchase_timestamp, '%Y-%m') as order_month,
    COUNT(*) as total_orders,
    ROUND(SUM(op.payment_value), 2) as monthly_revenue,
    ROUND(AVG(op.payment_value), 2) as avg_order_value
FROM orders o
JOIN order_payments op ON o.order_id = op.order_id
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY order_month
ORDER BY order_month;