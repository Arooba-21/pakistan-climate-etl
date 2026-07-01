                                 -- Global Level (df_global)--

--What is the average land temperature per decade since 1750?
SELECT (EXTRACT(YEAR FROM dt)::int/10)*10 AS decade,
        AVG("LandAverageTemperature")
FROM global_temp
WHERE EXTRACT (YEAR FROM dt)>=1750
GROUP BY (EXTRACT(YEAR FROM dt)::int/10)*10
ORDER BY decade ASC
;

--Which month historically has the highest global average temperature?
SELECT EXTRACT(MONTH FROM dt) AS Month,
       AVG("LandAverageTemperature") AS Highest_temp
FROM global_temp
GROUP BY EXTRACT(MONTH FROM dt)
ORDER BY Highest_temp DESC
Limit 1
;

--How much has global temperature increased from 1900 to 2015? (first vs last 10 year avg)
WITH temp_avg AS (
    SELECT
        CASE
            WHEN EXTRACT(YEAR FROM dt) BETWEEN 1900 AND 1909 THEN '1900-1909'
            WHEN EXTRACT(YEAR FROM dt) BETWEEN 2006 AND 2015 THEN '2006-2015'
        END AS period,
        AVG("LandAverageTemperature") AS avg_temp
    FROM global_temp
    WHERE EXTRACT(YEAR FROM dt) BETWEEN 1900 AND 2015
    GROUP BY period
)
SELECT *
FROM temp_avg
WHERE period IS NOT NULL
;

--Which year had the most uncertainty in measurements?
SELECT EXTRACT(YEAR FROM dt) AS year,
       AVG("LandAverageTemperatureUncertainty") AS Most_Uncertainty
FROM global_temp
GROUP BY EXTRACT(YEAR FROM dt)
ORDER BY Most_Uncertainty DESC
LIMIT 1
;

--Compare LandAverageTemperature vs LandAndOceanAverageTemperature — which is higher and by how much on average?
SELECT
    AVG("LandAverageTemperature") AS avg_land_temp,
    AVG("LandAndOceanAverageTemperature") AS avg_land_ocean_temp,
    ABS(
        AVG("LandAverageTemperature") -
        AVG("LandAndOceanAverageTemperature")
    ) AS avg_difference,
    CASE
        WHEN AVG("LandAverageTemperature") >
             AVG("LandAndOceanAverageTemperature")
        THEN 'LandAverageTemperature'
        ELSE 'LandAndOceanAverageTemperature'
    END AS higher_temperature
FROM global_temp
;

                                 -- Pakistan Level (df_pakistan)--

--What is Pakistan's average temperature per month? (seasonal pattern)
SELECt AVG("AverageTemperature"),month
FROM pakistan_temp
GROUP BY month
ORDER BY month ASC
;

--Which year was the hottest on record for Pakistan?
SELECT year, AVG("AverageTemperature") AS avg_temp
FROM pakistan_temp
GROUP BY year
ORDER BY avg_temp DESC
LIMIT 1;
;

--Show year over year temperature change using LAG
WITH yearly_temp AS (
    SELECT
        year,
        AVG("AverageTemperature") AS avg_temp
    FROM pakistan_temp
    GROUP BY year
)
SELECT
    year,
    avg_temp,
    LAG(avg_temp) OVER (ORDER BY year) AS previous_year_temp,
    avg_temp - LAG(avg_temp) OVER (ORDER BY year) AS temp_change
FROM yearly_temp
ORDER BY year
;

--Which decade showed the steepest warming in Pakistan?
WITH decade_temp AS (
    SELECT
        (EXTRACT(YEAR FROM dt)::INT / 10) * 10 AS decade,
        AVG("AverageTemperature") AS avg_temp
    FROM pakistan_temp
    GROUP BY decade
)
SELECT
    decade,
    avg_temp,
    LAG(avg_temp) OVER (ORDER BY decade) AS previous_decade_temp,
    avg_temp - LAG(avg_temp) OVER (ORDER BY decade) AS warming
FROM decade_temp
ORDER BY warming DESC
LIMIT 1
;

--How many years had average temperature above 25°C?
SELECT COUNT(*) AS total_years
FROM (
    SELECT year
    FROM pakistan_temp
    GROUP BY year
    HAVING AVG("AverageTemperature") > 25
) AS t
;

                                --Karachi level(df_karachi)--
-- What is Karachi's average temperature per month across all years?
SELECT
    month,
    AVG("AverageTemperature") AS avg_temp
FROM karachi_temp
GROUP BY month
ORDER BY month
;

-- Which was Karachi's hottest and coldest year on record?
WITH MAX AS (SELECT year,AVG("AverageTemperature") AS max_temp
FROM karachi_temp
GROUP BY year
ORDER BY max_temp DESC
limit 1),
      MIN AS (SELECT year,AVG("AverageTemperature") AS min_temp
FROM karachi_temp
GROUP BY year
ORDER BY min_temp ASC
limit 1
)
SELECT * FROM MAX,MIN
;

-- Count of months where Karachi exceeded 32°C — per decade
SELECT (year/10)*10 AS decade,
        COUNT(*) AS month,
		AVG("AverageTemperature")
		FROM karachi_temp
		WHERE "AverageTemperature" > 32
        GROUP BY (year / 10) * 10		
		ORDER BY decade
;

-- What is the temperature trend in Karachi post-1950 vs pre-1950?
WITH temp_avg AS (
    SELECT
        CASE
            WHEN year>= 1950 THEN 'post-1950'
            ELSE 'Pre-1950'
        END AS period,
        AVG("AverageTemperature") AS avg_temp
    FROM karachi_temp
    GROUP BY period
)
SELECT *
FROM temp_avg
;

-- Which month in Karachi has the highest temperature variance across years?
SELECT
    month,
    VARIANCE("AverageTemperature") AS temp_variance
FROM karachi_temp
GROUP BY month
ORDER BY temp_variance DESC
LIMIT 1
;

                                -- Cross Table / Comparison --

-- Is Karachi warming faster than Pakistan's national average?
WITH pak AS(
     SELECT AVG("AverageTemperature") AS p_avg ,year
	 FROM pakistan_temp
	 GROUP BY year
),
     khi AS(
     SELECT AVG("AverageTemperature") AS k_temp,year
	 FROM karachi_temp
	 GROUP BY year
),
     pak_change AS (
     SELECT MAX(p_avg) - MIN(p_avg) AS warming
     FROM pak
),
     khi_change AS (
     SELECT MAX(k_temp) - MIN(k_temp) AS warming
    FROM khi
)
SELECT
    pak_change.warming AS pakistan_warming,
    khi_change.warming AS karachi_warming,
    CASE
        WHEN khi_change.warming > pak_change.warming
        THEN 'Karachi is warming faster'
        ELSE 'Pakistan is warming faster'
    END AS comparison
FROM pak_change, khi_change;

-- Compare Pakistan vs global warming rate — who warmed more since 1900?
WITH pak AS (
    SELECT
        year,
        AVG("AverageTemperature") AS avg_temp
    FROM pakistan_temp
    WHERE year >= 1900
    GROUP BY year
),
glob AS (
    SELECT
        EXTRACT(YEAR FROM dt) AS year,
        AVG("LandAverageTemperature") AS avg_temp
    FROM global_temp
    WHERE EXTRACT(YEAR FROM dt) >= 1900
    GROUP BY EXTRACT(YEAR FROM dt)
),
pak_rate AS (
    SELECT MAX(avg_temp) - MIN(avg_temp) AS warming
    FROM pak
),
glob_rate AS (
    SELECT MAX(avg_temp) - MIN(avg_temp) AS warming
    FROM glob
)
SELECT
    pak_rate.warming,
    glob_rate.warming,
    CASE
        WHEN pak_rate.warming > glob_rate.warming
        THEN 'Pakistan warmed more since 1900'
        ELSE 'Global average warmed more since 1900'
    END AS comparison
FROM pak_rate, glob_rate;

-- In which decades did Pakistan's temperature exceed global average?
WITH pak AS (
    SELECT (year/10)*10 AS decade,
        AVG("AverageTemperature") AS p_temp
    FROM pakistan_temp
    GROUP BY (year/10)*10 
),
    glob AS (
    SELECT (EXTRACT (year FROM dt)::int/10)*10 AS decade,
    AVG("LandAverageTemperature") AS g_temp
    FROM global_temp
    GROUP BY (EXTRACT (year FROM dt)::int/10)*10
) 
SELECT
    p.decade,
    p.p_temp,
    g.g_temp,
    p.p_temp - g.g_temp AS difference,
    CASE
        WHEN p.p_temp > g.g_temp THEN 'Pakistan exceeded global average'
        ELSE 'Global average was higher'
    END AS result
FROM pak p
JOIN glob g
ON p.decade = g.decade
ORDER BY p.decade
;

-- What is the difference between Karachi and Pakistan average in summer months (May-Aug)?
WITH pak AS (
        SELECT month,
        AVG("AverageTemperature") AS avg_temp
        FROM pakistan_temp
        WHERE month BETWEEN 5 AND 8
        GROUP BY month
),
     khi AS (
        SELECT month,
        AVG("AverageTemperature") AS avg_temp
        FROM karachi_temp
        WHERE month BETWEEN 5 AND 8
        GROUP BY month
)
SELECT
    pak.month,
    pak.avg_temp AS Pak_temp,
    khi.avg_temp AS Khi_temp,
	khi.avg_temp-pak.avg_temp AS difference
FROM pak
INNER JOIN khi
ON pak.month = khi.month
ORDER BY pak.month;
;

-- Rank each decade by temperature for both Pakistan and Karachi side by side
WITH pak AS (
        SELECT (year/10)*10 AS decade,
        ROUND(AVG("AverageTemperature"):: numeric,2)AS pak_temp,
		RANK()OVER(Order by AVG("AverageTemperature")) AS pak_rank
        FROM pakistan_temp
		GROUP BY (year/10)*10
),
    khi AS (
        SELECT (year/10)*10 AS decade,
        ROUND(AVG("AverageTemperature"):: numeric,2)AS khi_temp,
		RANK()OVER(Order by AVG("AverageTemperature")) AS khi_rank
        FROM karachi_temp
		GROUP BY (year/10)*10
)
SELECT
    pak.decade,
    pak.pak_temp,
    pak.pak_rank,
    khi.khi_temp,
    khi.khi_rank
FROM pak
INNER JOIN khi
ON pak.decade = khi.decade
ORDER BY pak.decade
;





