/*
===============================================================================
SALES ANALYTICS | POSTGRESQL GOLD LAYER
===============================================================================
Project: End-to-End Sales Analytics
Tables : gold.fact_sales, gold.dim_customers, gold.dim_products
Scope  : Country comparison, Bike mix, 2012 decline, 2013 recovery,
         source-data validation.

Run each numbered query independently in pgAdmin, or execute the entire file.
No data-changing statements are included.

Notes:
- Revenue per unit = SUM(sales_amount) / SUM(quantity).
- AOV = SUM(sales_amount) / COUNT(DISTINCT order_number).
- High/low Bike classification uses the median of *product-level* lifetime
  revenue per unit, calculated across all countries and years. This keeps the
  cutoff consistent for cross-country and year comparisons.
- Products are grouped by product_key to avoid conflating different SKUs with
  the same product_name.
- NULL order_date records are excluded from annual analyses but are inspected
  separately at the end.
- Counts of customers are distinct purchasing customers, not all dimension rows.
===============================================================================
*/

-- ============================================================================
-- SECTION 1. COUNTRY PERFORMANCE
-- ============================================================================

-- Q01. Revenue, customers, orders, units, units/order and revenue/unit by country.
SELECT
    COALESCE(c.country, 'N/A') AS country,
    SUM(s.sales_amount) AS total_revenue,
    COUNT(DISTINCT s.customer_key) AS total_customers,
    COUNT(DISTINCT s.order_number) AS total_orders,
    SUM(s.quantity) AS total_quantity,
    ROUND(SUM(s.quantity)::numeric /
          NULLIF(COUNT(DISTINCT s.order_number), 0), 2) AS units_per_order,
    ROUND(SUM(s.sales_amount)::numeric /
          NULLIF(SUM(s.quantity), 0), 2) AS revenue_per_unit
FROM gold.fact_sales AS s
LEFT JOIN gold.dim_customers AS c
    ON c.customer_key = s.customer_key
GROUP BY COALESCE(c.country, 'N/A')
ORDER BY total_revenue DESC;

-- Q02. Australia vs United States: revenue and unit mix by product category.
WITH category_country AS (
    SELECT
        c.country,
        p.category,
        SUM(s.sales_amount) AS total_revenue,
        SUM(s.quantity) AS total_quantity,
        COUNT(DISTINCT s.order_number) AS total_orders,
        ROUND(SUM(s.sales_amount)::numeric /
              NULLIF(SUM(s.quantity), 0), 2) AS revenue_per_unit
    FROM gold.fact_sales AS s
    JOIN gold.dim_customers AS c ON c.customer_key = s.customer_key
    JOIN gold.dim_products AS p ON p.product_key = s.product_key
    WHERE c.country IN ('Australia', 'United States')
    GROUP BY c.country, p.category
)
SELECT
    country,
    category,
    total_revenue,
    total_quantity,
    total_orders,
    revenue_per_unit,
    ROUND(100.0 * total_revenue /
          NULLIF(SUM(total_revenue) OVER (PARTITION BY country), 0), 2)
          AS category_revenue_share_pct
FROM category_country
ORDER BY country, total_revenue DESC;

-- Q03. Top 10 Bike models by revenue in EACH country, with revenue per unit.
WITH bike_models AS (
    SELECT
        c.country,
        p.product_key,
        p.product_name,
        SUM(s.sales_amount) AS total_revenue,
        SUM(s.quantity) AS total_quantity,
        ROUND(SUM(s.sales_amount)::numeric /
              NULLIF(SUM(s.quantity), 0), 2) AS revenue_per_unit
    FROM gold.fact_sales AS s
    JOIN gold.dim_customers AS c ON c.customer_key = s.customer_key
    JOIN gold.dim_products AS p ON p.product_key = s.product_key
    WHERE c.country IN ('Australia', 'United States')
      AND p.category = 'Bikes'
    GROUP BY c.country, p.product_key, p.product_name
), ranked AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY country ORDER BY total_revenue DESC, product_key
    ) AS revenue_rank
    FROM bike_models
)
SELECT country, revenue_rank, product_name, total_revenue,
       total_quantity, revenue_per_unit
FROM ranked
WHERE revenue_rank <= 10
ORDER BY country, revenue_rank;

-- ============================================================================
-- SECTION 2. BIKE VALUE SEGMENTATION: CONSISTENT GLOBAL MEDIAN
-- ============================================================================

-- Q04. Median revenue/unit across Bike products (full available history).
WITH product_rpu AS (
    SELECT
        p.product_key,
        p.product_name,
        SUM(s.sales_amount)::numeric / NULLIF(SUM(s.quantity), 0)
            AS revenue_per_unit
    FROM gold.fact_sales AS s
    JOIN gold.dim_products AS p ON p.product_key = s.product_key
    WHERE p.category = 'Bikes'
    GROUP BY p.product_key, p.product_name
)
SELECT ROUND(
    (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY revenue_per_unit))::numeric,
    3
) AS median_bike_revenue_per_unit
FROM product_rpu;

-- Q05. Australia vs United States: high/low Bike mix by units.
-- Classification is based on global product-level RPU, NOT each country's RPU.
WITH product_rpu AS (
    SELECT
        p.product_key,
        SUM(s.sales_amount)::numeric / NULLIF(SUM(s.quantity), 0)
            AS revenue_per_unit
    FROM gold.fact_sales AS s
    JOIN gold.dim_products AS p ON p.product_key = s.product_key
    WHERE p.category = 'Bikes'
    GROUP BY p.product_key
), cutoff AS (
    SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY revenue_per_unit)
           AS median_rpu
    FROM product_rpu
), country_units AS (
    SELECT
        c.country,
        CASE WHEN r.revenue_per_unit > cutoff.median_rpu
             THEN 'High-Value' ELSE 'Lower-Value' END AS bike_value_segment,
        SUM(s.quantity) AS total_quantity
    FROM gold.fact_sales AS s
    JOIN gold.dim_customers AS c ON c.customer_key = s.customer_key
    JOIN gold.dim_products AS p ON p.product_key = s.product_key
    JOIN product_rpu AS r ON r.product_key = p.product_key
    CROSS JOIN cutoff
    WHERE c.country IN ('Australia', 'United States')
      AND p.category = 'Bikes'
    GROUP BY c.country,
        CASE WHEN r.revenue_per_unit > cutoff.median_rpu
             THEN 'High-Value' ELSE 'Lower-Value' END
)
SELECT
    country,
    bike_value_segment,
    total_quantity,
    ROUND(100.0 * total_quantity /
          NULLIF(SUM(total_quantity) OVER (PARTITION BY country), 0), 2)
          AS quantity_share_pct
FROM country_units
ORDER BY country, bike_value_segment;

-- ============================================================================
-- SECTION 3. YEARLY COVERAGE AND SALES TREND
-- ============================================================================

-- Q06. Distinct order count per year and month, including partial years.
SELECT
    EXTRACT(YEAR FROM order_date)::int AS sales_year,
    EXTRACT(MONTH FROM order_date)::int AS sales_month,
    COUNT(DISTINCT order_number) AS total_orders
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY 1, 2
ORDER BY 1, 2;

-- Q07. Annual sales KPIs for 2011, 2012, and 2013.
SELECT
    EXTRACT(YEAR FROM order_date)::int AS sales_year,
    SUM(sales_amount) AS total_revenue,
    COUNT(DISTINCT customer_key) AS total_customers,
    COUNT(DISTINCT order_number) AS total_orders,
    SUM(quantity) AS total_quantity,
    ROUND(SUM(sales_amount)::numeric /
          NULLIF(COUNT(DISTINCT order_number), 0), 2) AS aov,
    ROUND(SUM(quantity)::numeric /
          NULLIF(COUNT(DISTINCT order_number), 0), 2) AS units_per_order,
    ROUND(SUM(sales_amount)::numeric /
          NULLIF(SUM(quantity), 0), 2) AS revenue_per_unit
FROM gold.fact_sales
WHERE EXTRACT(YEAR FROM order_date) IN (2011, 2012, 2013)
GROUP BY 1
ORDER BY 1;

-- Q08. YoY changes for revenue, orders, units and revenue per unit.
WITH annual AS (
    SELECT
        EXTRACT(YEAR FROM order_date)::int AS sales_year,
        SUM(sales_amount)::numeric AS revenue,
        COUNT(DISTINCT order_number)::numeric AS orders,
        SUM(quantity)::numeric AS units,
        SUM(sales_amount)::numeric / NULLIF(SUM(quantity), 0) AS rpu
    FROM gold.fact_sales
    WHERE EXTRACT(YEAR FROM order_date) IN (2011, 2012, 2013)
    GROUP BY 1
), comparison AS (
    SELECT *,
        LAG(revenue) OVER (ORDER BY sales_year) AS prev_revenue,
        LAG(orders) OVER (ORDER BY sales_year) AS prev_orders,
        LAG(units) OVER (ORDER BY sales_year) AS prev_units,
        LAG(rpu) OVER (ORDER BY sales_year) AS prev_rpu
    FROM annual
)
SELECT sales_year, revenue, orders, units, ROUND(rpu, 2) AS revenue_per_unit,
       ROUND(100 * (revenue - prev_revenue) / NULLIF(prev_revenue, 0), 2)
           AS revenue_yoy_pct,
       ROUND(100 * (orders - prev_orders) / NULLIF(prev_orders, 0), 2)
           AS orders_yoy_pct,
       ROUND(100 * (units - prev_units) / NULLIF(prev_units, 0), 2)
           AS units_yoy_pct,
       ROUND(100 * (rpu - prev_rpu) / NULLIF(prev_rpu, 0), 2)
           AS rpu_yoy_pct
FROM comparison
ORDER BY sales_year;

-- ============================================================================
-- SECTION 4. WHY DID REVENUE FALL IN 2012?
-- ============================================================================

-- Q09. Category-level revenue, orders, units and RPU for 2011-2013.
SELECT
    EXTRACT(YEAR FROM s.order_date)::int AS sales_year,
    p.category,
    SUM(s.sales_amount) AS total_revenue,
    COUNT(DISTINCT s.order_number) AS total_orders,
    SUM(s.quantity) AS total_quantity,
    ROUND(SUM(s.sales_amount)::numeric /
          NULLIF(SUM(s.quantity), 0), 2) AS revenue_per_unit
FROM gold.fact_sales AS s
JOIN gold.dim_products AS p ON p.product_key = s.product_key
WHERE EXTRACT(YEAR FROM s.order_date) IN (2011, 2012, 2013)
GROUP BY 1, 2
ORDER BY sales_year, p.category;

-- Q10. Did the 2011-to-2012 Bike mix shift to lower-value products?
-- The global median is consistent with Q04 and Q05.
WITH product_rpu AS (
    SELECT p.product_key,
           SUM(s.sales_amount)::numeric / NULLIF(SUM(s.quantity), 0) AS rpu
    FROM gold.fact_sales AS s
    JOIN gold.dim_products AS p ON p.product_key = s.product_key
    WHERE p.category = 'Bikes'
    GROUP BY p.product_key
), cutoff AS (
    SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY rpu) AS median_rpu
    FROM product_rpu
), yearly_mix AS (
    SELECT
        EXTRACT(YEAR FROM s.order_date)::int AS sales_year,
        CASE WHEN r.rpu > cutoff.median_rpu
             THEN 'High-Value' ELSE 'Lower-Value' END AS bike_value_segment,
        SUM(s.quantity) AS units
    FROM gold.fact_sales AS s
    JOIN gold.dim_products AS p ON p.product_key = s.product_key
    JOIN product_rpu AS r ON r.product_key = p.product_key
    CROSS JOIN cutoff
    WHERE EXTRACT(YEAR FROM s.order_date) IN (2011, 2012)
      AND p.category = 'Bikes'
    GROUP BY 1, 2
)
SELECT sales_year, bike_value_segment, units,
       ROUND(100.0 * units /
             NULLIF(SUM(units) OVER (PARTITION BY sales_year), 0), 2)
             AS quantity_share_pct
FROM yearly_mix
ORDER BY sales_year, bike_value_segment;

-- Q11. Country-level revenue change, 2011 vs 2012.
WITH country_year AS (
    SELECT
        COALESCE(c.country, 'N/A') AS country,
        EXTRACT(YEAR FROM s.order_date)::int AS sales_year,
        COUNT(DISTINCT s.order_number) AS orders,
        SUM(s.quantity) AS units,
        SUM(s.sales_amount) AS revenue
    FROM gold.fact_sales AS s
    LEFT JOIN gold.dim_customers AS c ON c.customer_key = s.customer_key
    WHERE EXTRACT(YEAR FROM s.order_date) IN (2011, 2012)
    GROUP BY 1, 2
)
SELECT country,
       SUM(revenue) FILTER (WHERE sales_year = 2011) AS revenue_2011,
       SUM(revenue) FILTER (WHERE sales_year = 2012) AS revenue_2012,
       COALESCE(SUM(revenue) FILTER (WHERE sales_year = 2012), 0)
         - COALESCE(SUM(revenue) FILTER (WHERE sales_year = 2011), 0)
         AS revenue_change,
       SUM(orders) FILTER (WHERE sales_year = 2011) AS orders_2011,
       SUM(orders) FILTER (WHERE sales_year = 2012) AS orders_2012,
       SUM(units) FILTER (WHERE sales_year = 2011) AS units_2011,
       SUM(units) FILTER (WHERE sales_year = 2012) AS units_2012
FROM country_year
GROUP BY country
ORDER BY revenue_change;

-- Q12. US sales: compare 2011 and 2012 RPU, orders and units.
SELECT
    EXTRACT(YEAR FROM s.order_date)::int AS sales_year,
    COUNT(DISTINCT s.order_number) AS total_orders,
    SUM(s.quantity) AS total_quantity,
    SUM(s.sales_amount) AS total_revenue,
    ROUND(SUM(s.sales_amount)::numeric /
          NULLIF(SUM(s.quantity), 0), 2) AS revenue_per_unit
FROM gold.fact_sales AS s
JOIN gold.dim_customers AS c ON c.customer_key = s.customer_key
WHERE c.country = 'United States'
  AND EXTRACT(YEAR FROM s.order_date) IN (2011, 2012)
GROUP BY 1
ORDER BY 1;

-- Q13. US-only high/low Bike units and share, 2011 vs 2012.
WITH product_rpu AS (
    SELECT p.product_key,
           SUM(s.sales_amount)::numeric / NULLIF(SUM(s.quantity), 0) AS rpu
    FROM gold.fact_sales AS s
    JOIN gold.dim_products AS p ON p.product_key = s.product_key
    WHERE p.category = 'Bikes'
    GROUP BY p.product_key
), cutoff AS (
    SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY rpu) AS median_rpu
    FROM product_rpu
), us_mix AS (
    SELECT
        EXTRACT(YEAR FROM s.order_date)::int AS sales_year,
        CASE WHEN r.rpu > cutoff.median_rpu
             THEN 'High-Value' ELSE 'Lower-Value' END AS bike_value_segment,
        SUM(s.quantity) AS units
    FROM gold.fact_sales AS s
    JOIN gold.dim_customers AS c ON c.customer_key = s.customer_key
    JOIN gold.dim_products AS p ON p.product_key = s.product_key
    JOIN product_rpu AS r ON r.product_key = p.product_key
    CROSS JOIN cutoff
    WHERE c.country = 'United States'
      AND p.category = 'Bikes'
      AND EXTRACT(YEAR FROM s.order_date) IN (2011, 2012)
    GROUP BY 1, 2
)
SELECT sales_year, bike_value_segment, units,
       ROUND(100.0 * units /
             NULLIF(SUM(units) OVER (PARTITION BY sales_year), 0), 2)
             AS quantity_share_pct
FROM us_mix
ORDER BY sales_year, bike_value_segment;

-- Interpretation: Inspect the results before claiming that US mix caused
-- the overall decline; the SQL demonstrates associations, not causation.

-- ============================================================================
-- SECTION 5. WHY DID REVENUE RECOVER IN 2013?
-- ============================================================================

-- Q14. 2012 vs 2013: annual revenue, orders, units, RPU and AOV.
SELECT
    EXTRACT(YEAR FROM order_date)::int AS sales_year,
    COUNT(DISTINCT order_number) AS total_orders,
    SUM(quantity) AS total_quantity,
    SUM(sales_amount) AS total_revenue,
    ROUND(SUM(sales_amount)::numeric /
          NULLIF(SUM(quantity), 0), 2) AS revenue_per_unit,
    ROUND(SUM(sales_amount)::numeric /
          NULLIF(COUNT(DISTINCT order_number), 0), 2) AS aov
FROM gold.fact_sales
WHERE EXTRACT(YEAR FROM order_date) IN (2012, 2013)
GROUP BY 1
ORDER BY 1;

-- Q15. Category contributions to revenue and unit growth, 2012 to 2013.
WITH category_year AS (
    SELECT
        p.category,
        EXTRACT(YEAR FROM s.order_date)::int AS sales_year,
        SUM(s.sales_amount) AS revenue,
        SUM(s.quantity) AS units
    FROM gold.fact_sales AS s
    JOIN gold.dim_products AS p ON p.product_key = s.product_key
    WHERE EXTRACT(YEAR FROM s.order_date) IN (2012, 2013)
    GROUP BY 1, 2
)
SELECT category,
       COALESCE(SUM(revenue) FILTER (WHERE sales_year = 2012), 0) AS revenue_2012,
       COALESCE(SUM(revenue) FILTER (WHERE sales_year = 2013), 0) AS revenue_2013,
       COALESCE(SUM(revenue) FILTER (WHERE sales_year = 2013), 0)
         - COALESCE(SUM(revenue) FILTER (WHERE sales_year = 2012), 0)
         AS revenue_change,
       COALESCE(SUM(units) FILTER (WHERE sales_year = 2012), 0) AS units_2012,
       COALESCE(SUM(units) FILTER (WHERE sales_year = 2013), 0) AS units_2013,
       COALESCE(SUM(units) FILTER (WHERE sales_year = 2013), 0)
         - COALESCE(SUM(units) FILTER (WHERE sales_year = 2012), 0)
         AS units_change
FROM category_year
GROUP BY category
ORDER BY revenue_change DESC;

-- Q16. Country/category breakdown for Accessories and Clothing, 2012-2013.
SELECT
    EXTRACT(YEAR FROM s.order_date)::int AS sales_year,
    COALESCE(c.country, 'N/A') AS country,
    p.category,
    COUNT(DISTINCT s.order_number) AS total_orders,
    SUM(s.sales_amount) AS total_revenue,
    SUM(s.quantity) AS total_quantity,
    ROUND(SUM(s.sales_amount)::numeric /
          NULLIF(SUM(s.quantity), 0), 2) AS revenue_per_unit
FROM gold.fact_sales AS s
JOIN gold.dim_products AS p ON p.product_key = s.product_key
LEFT JOIN gold.dim_customers AS c ON c.customer_key = s.customer_key
WHERE p.category IN ('Accessories', 'Clothing')
  AND EXTRACT(YEAR FROM s.order_date) IN (2012, 2013)
GROUP BY 1, 2, 3
ORDER BY country, sales_year, category;

-- ============================================================================
-- SECTION 6. DATA QUALITY / COVERAGE CHECKS
-- ============================================================================

-- Q17. Country values available in the customer dimension.
SELECT DISTINCT COALESCE(country, 'N/A') AS country
FROM gold.dim_customers
ORDER BY country;

-- Q18. Sales with missing order dates: records, orders, units, revenue.
SELECT
    COUNT(*) AS sales_rows_with_missing_date,
    COUNT(DISTINCT order_number) AS orders_with_missing_date,
    SUM(quantity) AS quantity_with_missing_date,
    SUM(sales_amount) AS revenue_with_missing_date
FROM gold.fact_sales
WHERE order_date IS NULL;

-- Q19. Data coverage by calendar year, useful for identifying partial years.
SELECT
    EXTRACT(YEAR FROM order_date)::int AS sales_year,
    MIN(order_date) AS first_order_date,
    MAX(order_date) AS last_order_date,
    COUNT(DISTINCT order_number) AS total_orders,
    SUM(sales_amount) AS total_revenue
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY 1
ORDER BY 1;

/*
END OF ANALYSIS

Business interpretations to validate with query results:
1. Australia vs US: similar revenue may mask differences in customers,
   purchase frequency, and the mix of high-value Bike units.
2. 2012: inspect whether revenue per unit and product mix declined even as
   order volume increased, especially in the United States.
3. 2013: inspect whether recovery was primarily volume-led and which product
   categories contributed the largest absolute increases.

CAUTION: This file is a cleaned, consolidated version of exploratory SQL.
Some metrics can differ from prior notebook/dashboard calculations because
Bike classification is standardized globally at product_key grain. If the
Power BI measures use a different classification method, align definitions
before claiming exact agreement.
*/
