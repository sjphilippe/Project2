--Total avocados sold per region
WITH table1 AS (SELECT
region, date,
sum(total_vol) OVER 
	(PARTITION BY date ORDER BY region) AS sumavo
FROM florida_avo
WHERE region IN ('Miami', 'Tampa') AND
year = '2019') -- can change date

SELECT region, date, sumavo
FROM table1
GROUP BY sumavo, date, region
ORDER BY date


-- total avo type sold per year in each region 
SELECT
region, sum(total_vol), year, type
FROM florida_avo
WHERE type = 'organic' -- can change to conventional. can also add a year = '...' clause
GROUP BY type, region, year
ORDER BY year, region

			

-- sum of avos sold per region by quarter 
WITH table1 AS (SELECT
region, total_vol, year, date, type,
date_part('quarter', date) AS quart
FROM florida_avo)

SELECT 
region, sum(total_vol), year, quart
FROM table1
WHERE (type ='organic' or type = 'conventional') AND quart = '1' -- change quarter to 1,2,3 or 4
GROUP BY region, year, quart

-- What weeks were avo prices above/below the us average 
WITH table1 AS (SELECT ROUND(avg_price,2) AS usavg, date, type
FROM florida_avo
WHERE region = 'TotalUS') 

SELECT region, fa.date, usavg, ROUND(avg_price,2) AS city_price, t1.type,
CASE WHEN fa.avg_price < usavg THEN 'Below'
	WHEN fa.avg_price > usavg THEN 'Above'
	ELSE 'Matching' END AS price_flux
FROM florida_avo AS fa
JOIN table1 AS t1
ON t1.date = fa.date
	AND t1.type = fa.type
WHERE 
	-- t1.type = 'organic' AND --> filter by type of avo(organic/conventional)
	region != 'TotalUS' AND -- excludes total us AS region value 
	region = 'Tampa' AND -->filter by region(s). exlude to show all. 
	 year BETWEEN '2019' AND '2021'
ORDER BY fa.date, region

--- Number of times avo prices were over 2.00
SELECT region, Round(avg_price,2), date, type
FROM florida_avo
WHERE region In ('Tampa', 'Miami') AND avg_price > 2.00

--Counts the number of weeks avos in florida have been sold above/below us avg since 2019
WITH table1 AS (SELECT ROUND(avg_price,2) AS usavg, date, type
FROM florida_avo
WHERE region = 'TotalUS'),

table2 AS (SELECT region, fa.date, usavg, ROUND(avg_price,2) AS city_price, t1.type, year,
CASE WHEN fa.avg_price < usavg THEN 'Below' END AS pricebelow,
CASE WHEN fa.avg_price > usavg THEN 'Above' END AS priveabove,
CASE WHEN fa.avg_price = usavg THEN 'Matching' END AS sameprice
FROM florida_avo AS fa
JOIN table1 AS t1
ON t1.date = fa.date
	AND t1.type = fa.type
WHERE 
	region != 'TotalUS' AND --> excludes total us AS region value 
	year BETWEEN '2019' AND '2021' --> filter by year here
ORDER BY fa.date, fa.region)

SELECT distinct region, year, count(priveabove)/2 AS timesabove_usavg, --> count()/2 because query counts organic & conventional prices AS seperate weeks.
	count(pricebelow)/2 AS timesbelow_usavg,
	count(sameprice)/2 AS timesmatching_usavg
FROM table2 
GROUP BY region, year
ORDER BY year


-- which weeks did TOTALUS avo outsell total imports (did they go into avocado reserves?)
WITH chart1 AS (SELECT
region, date,
sum(total_vol) OVER 
	(PARTITION BY date ORDER BY region) AS sumavo
FROM florida_avo
WHERE region = 'TotalUS')

SELECT t.week, region, t.total_vol AS imported, ROUND(sumavo,0) AS sold, Round(t.total_vol- sumavo,0) AS difference,
CASE WHEN sumavo > t.total_vol THEN 'oversold'
	WHEN sumavo < t.total_vol THEN 'undersold' END AS howmany
FROM chart1 AS c
JOIN total_volume AS t
ON t.week = c.date
GROUP BY t.week, region, t.total_vol, sumavo
ORDER BY t.week


