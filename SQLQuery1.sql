-- Busines Request 1 :- City Level Fare and Trip Summary Report --
SELECT 
    cit.city_name,
    COUNT(trp.trip_id) AS total_trips,
    SUM(trp.fare_amount) / NULLIF(SUM(trp.distance_travelled_km), 0) AS avg_fare_per_km,
    SUM(trp.fare_amount) / COUNT(trp.trip_id) AS avg_fare_per_trip,
    COUNT(trp.trip_id) / CAST((SELECT COUNT(trip_id) FROM [Trips_db].[dbo].[fact_trips]) AS DECIMAL(9,2)) * 100 AS percent_contribution_total_trips
FROM 
    [Trips_db].[dbo].[dim_city] AS cit
JOIN 
    [Trips_db].[dbo].[fact_trips] AS trp
    ON cit.city_id = trp.city_id
GROUP BY 
    cit.city_name;
-- note :- avg_fare_per_km and avg_fare_per_trip is avg of cities not of whole data --

-- Business Request 2 :- Monthly City-Level Trips Target Performance Report --

WITH aggregated_trips AS (
    SELECT 
        city_id,
        DATEPART(MONTH, date) AS trip_month,  -- Extract month as integer
        COUNT(trip_id) AS total_trip
    FROM [Trips_db].[dbo].[fact_trips]
    GROUP BY city_id, DATEPART(MONTH, date)
)
SELECT 
    cit.city_name,
    FORMAT(target_a.month, 'MMMM') AS month_name,  -- Directly format DATE to month name
    agg.total_trip,
    target_a.total_target_trips AS total_trgt_trp,
	ROUND(CAST( agg.total_trip - target_a.total_target_trips AS float)/CAST((agg.total_trip + target_a.total_target_trips)/2 AS float)*100,2) AS percent_difference,
    CASE
	  WHEN agg.total_trip < target_a.total_target_trips THEN 'below_target'
	  ELSE 'above_target'
	END AS target_status
FROM [Trips_db].[dbo].[dim_city] AS cit
JOIN aggregated_trips AS agg 
    ON cit.city_id = agg.city_id
JOIN [Targets.db].[dbo].[monthly_target_trips] AS target_a 
    ON agg.city_id = target_a.city_id 
    AND agg.trip_month = DATEPART(MONTH, target_a.month)  -- Compare month integers
ORDER BY cit.city_name DESC, DATEPART(MONTH, target_a.month) DESC;

-- Business Request 3 :- City-level repeat passengers trip frequency report --

SELECT
  city_name,
  ROUND(CAST(SUM(CASE WHEN trip_count = '10-Trips' THEN repeat_passenger_count END)AS float)/CAST(SUM(repeat_passenger_count) AS float) * 100,2) AS '10_trip',
  ROUND(CAST(SUM(CASE WHEN trip_count = '9-Trips' THEN repeat_passenger_count END)AS float)/CAST(SUM(repeat_passenger_count) AS float) * 100,2) AS '9_trip',
  ROUND(CAST(SUM(CASE WHEN trip_count = '8-Trips' THEN repeat_passenger_count END)AS float)/CAST(SUM(repeat_passenger_count) AS float) * 100,2) AS '8_trip',
  ROUND(CAST(SUM(CASE WHEN trip_count = '7-Trips' THEN repeat_passenger_count END)AS float)/CAST(SUM(repeat_passenger_count) AS float) * 100,2) AS '7_trip',
  ROUND(CAST(SUM(CASE WHEN trip_count = '6-Trips' THEN repeat_passenger_count END)AS float)/CAST(SUM(repeat_passenger_count) AS float) * 100,2) AS '6_trip',
  ROUND(CAST(SUM(CASE WHEN trip_count = '5-Trips' THEN repeat_passenger_count END)AS float)/CAST(SUM(repeat_passenger_count) AS float) * 100,2) AS '5_trip',
  ROUND(CAST(SUM(CASE WHEN trip_count = '4-Trips' THEN repeat_passenger_count END)AS float)/CAST(SUM(repeat_passenger_count) AS float) * 100,2) AS '4_trip',
  ROUND(CAST(SUM(CASE WHEN trip_count = '3-Trips' THEN repeat_passenger_count END)AS float)/CAST(SUM(repeat_passenger_count) AS float) * 100,2) AS '3_trip',
  ROUND(CAST(SUM(CASE WHEN trip_count = '2-Trips' THEN repeat_passenger_count END)AS float)/CAST(SUM(repeat_passenger_count) AS float) * 100,2) AS '2_trip'
FROM [Trips_db].[dbo].[dim_city] AS city
JOIN [Trips_db].[dbo].[dim_repeat_trip_distribution] AS trip_distribution
  ON city.city_id = trip_distribution.city_id
GROUP BY city_name;

-- Business Request 4 :- identify cities with highest and lowest total new passenger --

SELECT
  city_name,
  SUM(new_passengers) AS new_passenger
FROM [Trips_db].[dbo].[dim_city] AS city
JOIN [Trips_db].[dbo].[fact_passenger_summary] AS passenger
  ON city.city_id = passenger.city_id
GROUP BY city_name;



-- Business Request 5 :- Identify month with higest revenue for each city --

WITH monthly_revenue_cte AS (
SELECT
  city_name,
  month_name,
  SUM(fare_amount) as revenue
FROM [Trips_db].[dbo].[dim_city] AS city
JOIN [Trips_db].[dbo].[fact_trips] AS trips
  ON city.city_id = trips.city_id
JOIN [Trips_db].[dbo].[dim_date] AS dim_date
  ON trips.date = dim_date.date
GROUP BY city_name,month_name 
)

SELECT 
city_name,
month_name,
max(revenue)
FROM monthly_revenue_cte
GROUP BY city_name, month_name;


-- Business Request 6 :- Repeat passenger rate analysis --


SELECT
city_name,
month_name,
total_passengers,
ROUND((CAST(repeat_passengers as float)/CAST(total_passengers AS float))*100,2) AS repeat_passenger_rate
FROM [Trips_db].[dbo].[dim_city] AS city
JOIN [Trips_db].[dbo].[fact_passenger_summary] AS summary
  ON city.city_id = summary.city_id
JOIN [Trips_db].[dbo].[dim_date]
  ON summary.month = dim_date.date