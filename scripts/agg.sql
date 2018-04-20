-- turnover by month
SELECT
    MONTH(co.order_date) as order_month
    ,sum(op.quantity * p.value) as turnover
FROM customer_order co
LEFT JOIN order_products op
    ON co.id_customer_order = op.id_customer_order
LEFT JOIN price p
    ON op.id_price = p.id_price
GROUP BY order_month
;

-- turnover by product
SELECT
    op.id_product as id_product
    ,sum(op.quantity * p.value) as turnover
FROM order_products op
LEFT JOIN price p
    ON op.id_price = p.id_price
GROUP BY id_product
;

-- turnover by month, by product
SELECT
    MONTH(co.order_date) as order_month
    , op.id_product as id_product
    ,sum(op.quantity * p.value) as turnover
FROM customer_order co
LEFT JOIN order_products op
    ON co.id_customer_order = op.id_customer_order
LEFT JOIN price p
    ON op.id_price = p.id_price
GROUP BY order_month, id_product
;

-- turnover by month, by product with product nameœ
SELECT
    product.name
    , order_month
    , turnover
FROM
    product
LEFT JOIN (
    SELECT
        MONTH(co.order_date) as order_month
        , op.id_product as id_product
        ,sum(op.quantity * p.value) as turnover
    FROM customer_order co
    LEFT JOIN order_products op
        ON co.id_customer_order = op.id_customer_order
    LEFT JOIN price p
        ON op.id_price = p.id_price
    GROUP BY order_month, id_product
) product_turnover
ON product.id_product = product_turnover.id_product
;

-- turover indicator
SELECT
    order_month,
    CASE
        WHEN turnover > 1000 THEN 'good'
        WHEN turnover < 1000 THEN 'bad'
    END as indicator
FROM (
    SELECT
        MONTH(co.order_date) as order_month
        ,sum(op.quantity * p.value) as turnover
    FROM customer_order co
    LEFT JOIN order_products op
        ON co.id_customer_order = op.id_customer_order
    LEFT JOIN price p
        ON op.id_price = p.id_price
    GROUP BY order_month
) turnover_indicator
;

-- turnover by year, month with sub totol
SELECT
    YEAR(co.order_date) as order_year
    , MONTH(co.order_date) as order_month
    ,coalesce(sum(op.quantity * p.value), 0) as turnover
FROM customer_order co
LEFT JOIN order_products op
    ON co.id_customer_order = op.id_customer_order
LEFT JOIN price p
    ON op.id_price = p.id_price
GROUP BY order_year DESC, order_month DESC WITH ROLLUP
;

-- export yesterday orders
-- SHOW VARIABLES LIKE "secure_file_priv";
-- LOAD DATA INFILE '/path/to/file.csv' INTO TABLE table1;
SELECT
    *
FROM customer_order
WHERE DATE_SUB(CURDATE(), INTERVAL 1 DAY) = customer_order.order_date
INTO OUTFILE '/var/lib/mysql-files/orders.csv'
FIELDS ENCLOSED BY '"'
TERMINATED BY ';'
ESCAPED BY '"'
LINES TERMINATED BY '\n';

-- average turnover by month
SELECT
    order_month
    , coalesce(avg(turnover), 0) as average_turnover
FROM (
    SELECT
        MONTH(co.order_date) as order_month
        , coalesce(sum(op.quantity * p.value), 0) as turnover
    FROM customer_order co
    LEFT JOIN order_products op
        ON co.id_customer_order = op.id_customer_order
    LEFT JOIN price p
        ON op.id_price = p.id_price
    GROUP BY order_month
) turnover_by_month
GROUP BY order_month DESC
;

-- average turnover by month, with sold products id list
SELECT
    order_month
    , coalesce(avg(turnover), 0) as average_turnover
    , coalesce(products, '') as products
FROM (
    SELECT
        MONTH(co.order_date) as order_month
        , coalesce(sum(op.quantity * p.value), 0) as turnover
        , group_concat(DISTINCT p.id_product
                      ORDER BY p.id_product DESC SEPARATOR ', ') as products
    FROM customer_order co
    LEFT JOIN order_products op
        ON co.id_customer_order = op.id_customer_order
    LEFT JOIN price p
        ON op.id_price = p.id_price
    GROUP BY order_month
) turnover_by_month
GROUP BY order_month DESC
;

-- average turnover by month, with sold products id list, num sold product
SELECT
    order_month
    , coalesce(avg(turnover), 0) as average_turnover
    , coalesce(products, '') as products
FROM (
    SELECT
        MONTH(co.order_date) as order_month
        , coalesce(sum(op.quantity * p.value), 0) as turnover
        , count(op.quantity) as num_product
        , group_concat(DISTINCT p.id_product
                      ORDER BY p.id_product DESC SEPARATOR ', ') as products
    FROM customer_order co
    LEFT JOIN order_products op
        ON co.id_customer_order = op.id_customer_order
    LEFT JOIN price p
        ON op.id_price = p.id_price
    GROUP BY order_month
) turnover_by_month
GROUP BY order_month DESC
;
