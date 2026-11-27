-- =========================================
-- PART 1: CREATE RAW ZOMATO TABLE
-- =========================================

CREATE TABLE IF NOT EXISTS zomato_raw (
    ID TEXT PRIMARY KEY,
    Delivery_person_ID TEXT,
    Delivery_person_Age INTEGER,
    Delivery_person_Ratings REAL,
    Restaurant_latitude REAL,
    Restaurant_longitude REAL,
    Delivery_location_latitude REAL,
    Delivery_location_longitude REAL,
    Order_Date TEXT,
    Time_Orderd TEXT,
    Time_Order_picked TEXT,
    Weather_conditions TEXT,
    Road_traffic_density TEXT,
    Vehicle_condition INTEGER,
    Type_of_order TEXT,
    Type_of_vehicle TEXT,
    multiple_deliveries INTEGER,
    Festival TEXT,
    City TEXT,
    distance_km REAL,
    "Time_taken (min)" INTEGER
);
SELECT COUNT(*) AS total_records
FROM zomato_raw;

SELECT *
FROM zomato_raw
LIMIT 10;
-- =========================================
-- PART 2: CREATE RELATED TABLES
-- =========================================

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS delivery_partners (
    Delivery_person_ID TEXT PRIMARY KEY,
    Delivery_person_Age INTEGER,
    Delivery_person_Ratings REAL,
    Vehicle_condition INTEGER
);

CREATE TABLE IF NOT EXISTS orders (
    ID TEXT PRIMARY KEY,
    Delivery_person_ID TEXT,
    Order_Date TEXT,
    Weather_conditions TEXT,
    Road_traffic_density TEXT,
    Type_of_order TEXT,
    Type_of_vehicle TEXT,
    multiple_deliveries INTEGER,
    Festival TEXT,
    City TEXT,
    distance_km REAL,
    delivery_time INTEGER,
    FOREIGN KEY (Delivery_person_ID)
        REFERENCES delivery_partners(Delivery_person_ID)
);
-- =========================================
-- PART 3: INSERT DELIVERY PARTNER DATA
-- =========================================

INSERT OR REPLACE INTO delivery_partners (
    Delivery_person_ID,
    Delivery_person_Age,
    Delivery_person_Ratings,
    Vehicle_condition
)
SELECT
    Delivery_person_ID,
    MAX(Delivery_person_Age),
    MAX(Delivery_person_Ratings),
    MAX(Vehicle_condition)
FROM zomato_raw
WHERE Delivery_person_ID IS NOT NULL
GROUP BY Delivery_person_ID;
-- =========================================
-- INSERT ORDER DATA
-- =========================================

INSERT OR REPLACE INTO orders (
    ID,
    Delivery_person_ID,
    Order_Date,
    Weather_conditions,
    Road_traffic_density,
    Type_of_order,
    Type_of_vehicle,
    multiple_deliveries,
    Festival,
    City,
    distance_km,
    delivery_time
)
SELECT
    ID,
    Delivery_person_ID,
    Order_Date,
    Weather_conditions,
    Road_traffic_density,
    Type_of_order,
    Type_of_vehicle,
    multiple_deliveries,
    Festival,
    City,
    distance_km,
    "Time_taken (min)"
FROM zomato_raw
WHERE ID IS NOT NULL;
-- =========================================
-- PART 4: TABLE STRUCTURE
-- =========================================

PRAGMA table_info(zomato_raw);
PRAGMA table_info(delivery_partners);
PRAGMA table_info(orders);
-- CHECK TOTAL RECORDS

SELECT COUNT(*) AS total_raw_records
FROM zomato_raw;

SELECT COUNT(*) AS total_delivery_partners
FROM delivery_partners;

SELECT COUNT(*) AS total_orders
FROM orders;
-- CHECK FOREIGN KEY CONSISTENCY

PRAGMA foreign_key_check;
-- CHECK UNMATCHED ORDERS

SELECT COUNT(*) AS unmatched_orders
FROM orders o
LEFT JOIN delivery_partners d
ON o.Delivery_person_ID = d.Delivery_person_ID
WHERE d.Delivery_person_ID IS NULL;


--questions---Zomato_India_Orders_Dataset
--Query 1 — Display the latest delivery records
SELECT
    ID,
    Delivery_person_ID,
    City,
    Road_traffic_density,
    distance_km,
    delivery_time
FROM orders
ORDER BY Order_Date DESC
LIMIT 10;
---High-traffic deliveries taking more than 30 minutes
--Concept: WHERE, AND
SELECT
    ID,
    City,
    Road_traffic_density,
    delivery_time
FROM orders
WHERE Road_traffic_density = 'High'
AND delivery_time > 30
ORDER BY delivery_time DESC;

--Query 3 — Deliveries during difficult weather conditions or traffic jams
SELECT
    ID,
    Weather_conditions,
    Road_traffic_density,
    City,
    delivery_time
FROM orders
WHERE Weather_conditions IN ('Stormy', 'Fog', 'Sandstorms')
OR Road_traffic_density = 'Jam';
--Query 4 — Deliveries taking between 20 and 40 minutes
SELECT
    ID,
    City,
    delivery_time
FROM orders
WHERE delivery_time BETWEEN 20 AND 40
ORDER BY delivery_time;
--Query 5 — Search for delivery partner IDs containing DEL
SELECT
    Delivery_person_ID,
    Delivery_person_Age
FROM delivery_partners
WHERE Delivery_person_ID LIKE '%DEL%'
LIMIT 50;

-- =========================================
-- QUERY 6: CHECK MISSING VALUES
-- Concepts: IS NULL, COALESCE
-- =========================================

SELECT
    COUNT(*) AS total_orders,
    SUM(CASE WHEN distance_km IS NULL THEN 1 ELSE 0 END)
        AS missing_distance,
    SUM(CASE WHEN delivery_time IS NULL THEN 1 ELSE 0 END)
        AS missing_delivery_time
FROM orders;

SELECT
    ID,
    COALESCE(City, 'Unknown') AS city_name,
    COALESCE(Weather_conditions, 'Unknown') AS weather,
    delivery_time
FROM orders
LIMIT 20;


-- =========================================
-- QUERY 7: CLASSIFY DELIVERY TIME BY CITY
-- Concepts: ROUND, CASE
-- =========================================

SELECT
    City,
    ROUND(AVG(delivery_time), 2) AS average_delivery_time,
    CASE
        WHEN AVG(delivery_time) <= 25 THEN 'Fast'
        WHEN AVG(delivery_time) <= 35 THEN 'Moderate'
        ELSE 'Slow'
    END AS delivery_category
FROM orders
WHERE delivery_time IS NOT NULL
GROUP BY City;


-- =========================================
-- QUERY 8: OVERALL DELIVERY STATISTICS
-- Concepts: COUNT, AVG, MIN, MAX
-- =========================================

SELECT
    COUNT(*) AS total_deliveries,
    ROUND(AVG(delivery_time), 2) AS average_delivery_time,
    MIN(delivery_time) AS minimum_delivery_time,
    MAX(delivery_time) AS maximum_delivery_time
FROM orders;


-- =========================================
-- QUERY 9: DELIVERY TIME BY TRAFFIC DENSITY
-- Concept: GROUP BY
-- =========================================

SELECT
    Road_traffic_density,
    COUNT(*) AS total_orders,
    ROUND(AVG(delivery_time), 2) AS average_delivery_time
FROM orders
WHERE delivery_time IS NOT NULL
GROUP BY Road_traffic_density
ORDER BY average_delivery_time DESC;


-- =========================================
-- QUERY 10: TRAFFIC CONDITIONS ABOVE 25 MINUTES
-- Concept: HAVING
-- =========================================

SELECT
    Road_traffic_density,
    COUNT(*) AS total_orders,
    ROUND(AVG(delivery_time), 2) AS average_delivery_time
FROM orders
WHERE delivery_time IS NOT NULL
GROUP BY Road_traffic_density
HAVING AVG(delivery_time) > 25;


-- =========================================
-- QUERY 11: DELIVERY TIME BY WEATHER
-- =========================================

SELECT
    Weather_conditions,
    COUNT(*) AS total_orders,
    ROUND(AVG(delivery_time), 2) AS average_delivery_time,
    MIN(delivery_time) AS fastest_delivery,
    MAX(delivery_time) AS slowest_delivery
FROM orders
WHERE delivery_time IS NOT NULL
GROUP BY Weather_conditions
ORDER BY average_delivery_time DESC;


-- =========================================
-- QUERY 12: DELIVERY TIME BY VEHICLE TYPE
-- =========================================

SELECT
    Type_of_vehicle,
    COUNT(*) AS total_orders,
    ROUND(AVG(delivery_time), 2) AS average_delivery_time
FROM orders
WHERE delivery_time IS NOT NULL
GROUP BY Type_of_vehicle
ORDER BY average_delivery_time;


-- =========================================
-- QUERY 13: INNER JOIN ORDERS AND DELIVERY PARTNERS
-- Concept: INNER JOIN
-- =========================================

SELECT
    o.ID,
    o.City,
    o.distance_km,
    o.delivery_time,
    d.Delivery_person_Age,
    d.Delivery_person_Ratings,
    d.Vehicle_condition
FROM orders o
INNER JOIN delivery_partners d
ON o.Delivery_person_ID = d.Delivery_person_ID
LIMIT 50;


-- =========================================
-- QUERY 14: LEFT JOIN ORDERS AND DELIVERY PARTNERS
-- Concept: LEFT JOIN
-- =========================================

SELECT
    o.ID,
    o.Delivery_person_ID,
    d.Delivery_person_Age,
    d.Delivery_person_Ratings,
    o.delivery_time
FROM orders o
LEFT JOIN delivery_partners d
ON o.Delivery_person_ID = d.Delivery_person_ID
LIMIT 50;


-- =========================================
-- QUERY 15: CLASSIFY ORDERS BY DISTANCE
-- Concepts: CASE, GROUP BY
-- =========================================

SELECT
    CASE
        WHEN distance_km < 5 THEN 'Short Distance'
        WHEN distance_km BETWEEN 5 AND 10 THEN 'Medium Distance'
        WHEN distance_km > 10 THEN 'Long Distance'
        ELSE 'Unknown Distance'
    END AS distance_category,
    COUNT(*) AS total_orders,
    ROUND(AVG(delivery_time), 2) AS average_delivery_time
FROM orders
WHERE delivery_time IS NOT NULL
GROUP BY distance_category
ORDER BY average_delivery_time DESC;


-- =========================================
-- QUERY 16: ANALYSE MULTIPLE DELIVERIES
-- =========================================

SELECT
    multiple_deliveries,
    COUNT(*) AS total_orders,
    ROUND(AVG(delivery_time), 2) AS average_delivery_time
FROM orders
WHERE delivery_time IS NOT NULL
GROUP BY multiple_deliveries
ORDER BY multiple_deliveries;


-- =========================================
-- QUERY 17: TRAFFIC AND MULTIPLE DELIVERIES
-- =========================================

SELECT
    Road_traffic_density,
    multiple_deliveries,
    COUNT(*) AS total_orders,
    ROUND(AVG(delivery_time), 2) AS average_delivery_time
FROM orders
WHERE delivery_time IS NOT NULL
GROUP BY Road_traffic_density, multiple_deliveries
ORDER BY Road_traffic_density, multiple_deliveries;


-- =========================================
-- QUERY 18: FESTIVAL VS NON-FESTIVAL DELIVERIES
-- =========================================

SELECT
    Festival,
    COUNT(*) AS total_orders,
    ROUND(AVG(delivery_time), 2) AS average_delivery_time
FROM orders
WHERE delivery_time IS NOT NULL
GROUP BY Festival;


-- =========================================
-- QUERY 19: DELIVERY TIME BY PARTNER RATINGS
-- Concepts: INNER JOIN, CASE
-- =========================================

SELECT
    CASE
        WHEN d.Delivery_person_Ratings >= 4.5 THEN 'High Rating'
        WHEN d.Delivery_person_Ratings >= 4.0 THEN 'Medium Rating'
        ELSE 'Low Rating'
    END AS rating_category,
    COUNT(o.ID) AS total_orders,
    ROUND(AVG(o.delivery_time), 2) AS average_delivery_time
FROM orders o
INNER JOIN delivery_partners d
ON o.Delivery_person_ID = d.Delivery_person_ID
WHERE d.Delivery_person_Ratings IS NOT NULL
AND o.delivery_time IS NOT NULL
GROUP BY rating_category;


-- =========================================
-- QUERY 20: CITIES WITH HIGHEST AVERAGE DELIVERY TIME
-- Concepts: GROUP BY, HAVING, ORDER BY
-- =========================================

SELECT
    City,
    COUNT(*) AS total_orders,
    ROUND(AVG(delivery_time), 2) AS average_delivery_time
FROM orders
WHERE delivery_time IS NOT NULL
GROUP BY City
HAVING COUNT(*) >= 100
ORDER BY average_delivery_time DESC;


-- =========================================
-- FINAL DATABASE VERIFICATION
-- =========================================

SELECT 'Raw Dataset' AS table_name, COUNT(*) AS total_records
FROM zomato_raw

UNION ALL

SELECT 'Delivery Partners', COUNT(*)
FROM delivery_partners

UNION ALL

SELECT 'Orders', COUNT(*)
FROM orders;


-- CHECK FOREIGN KEY CONSISTENCY

PRAGMA foreign_key_check;


-- CHECK MISSING DELIVERY TIMES

SELECT COUNT(*) AS missing_delivery_times
FROM orders
WHERE delivery_time IS NULL;