-- Combine data from multiple AppleStore_description tables
CREATE TABLE AppleStore_description_combined AS 
SELECT * FROM appleStore_description1
UNION ALL
SELECT * FROM appleStore_description2
UNION ALL
SELECT * FROM appleStore_description3
UNION ALL
SELECT * FROM appleStore_description4;

-- Stakeholder: App developer seeking data-driven insights
-- Exploratory Data Analysis

-- Check the number of unique apps in both AppleStore tables
SELECT COUNT(DISTINCT id) AS uniqueAPPIDs FROM AppleStore; -- 7197
SELECT COUNT(DISTINCT id) AS uniqueAPPIDs FROM AppleStore_description_combined; -- 7197

-- Check for missing values in key fields
SELECT COUNT(*) AS missing_values
FROM AppleStore
WHERE track_name IS NULL OR user_rating IS NULL OR prime_genre IS NULL; -- 0

SELECT COUNT(*) AS missing_values
FROM AppleStore_description_combined
WHERE app_desc IS NULL; -- 0

-- Find out the number of apps per genre
SELECT prime_genre, COUNT(*) AS NumApps
FROM AppleStore
GROUP BY prime_genre
ORDER BY NumApps DESC;

-- Get an overview of app ratings
SELECT MIN(user_rating) AS MinRating,
	   MAX(user_rating) AS MaxRating,
       AVG(user_rating) AS AvgRating
FROM AppleStore; -- Min-0, Max-5, Avg-3.5

-- Data Analysis

-- Determine whether paid apps have higher ratings than free apps
SELECT 
    CASE
        WHEN price > 0 THEN 'Paid'
        ELSE 'Free'
    END AS App_type,
    AVG(user_rating) AS Avg_Rating
FROM AppleStore
GROUP BY App_type; -- Free-3.37, Paid-3.7

-- Check if apps supporting more languages have higher ratings
SELECT 
    CASE 
        WHEN lang_num < 10 THEN 'Below 10 Languages'
        WHEN lang_num BETWEEN 10 AND 30 THEN '10-30 Languages'
        ELSE 'Above 30 Languages'
    END AS language_group,
    AVG(user_rating) AS Avg_Rating
FROM AppleStore
GROUP BY language_group
ORDER BY Avg_Rating DESC; -- 10-30-4.13, Above 30-3.7, Below 30-3.36

-- Check genres with low ratings
SELECT prime_genre,
	   AVG(user_rating) AS Avg_Rating
FROM AppleStore
GROUP BY prime_genre
ORDER BY Avg_Rating ASC
LIMIT 10; -- Catalogs-2.1, Finance-2.4

-- Check if there is a correlation between the length of the app description and user rating
SELECT 
    CASE
        WHEN LENGTH(AD.app_desc) < 100 THEN 'Short_Description'
        WHEN LENGTH(AD.app_desc) BETWEEN 100 AND 1000 THEN 'Medium_Description'
        ELSE 'Long_Description'
    END AS Desc_Length_Type,
    AVG(user_rating) AS Avg_Rating
FROM AppleStore AS A
JOIN AppleStore_description_combined AS AD ON A.id = AD.id
GROUP BY Desc_Length_Type
ORDER BY Avg_Rating DESC; -- Long-3.8, Medium-2.9, Short-1.7

-- Check the top-rated apps for each genre
SELECT
    prime_genre,
    track_name,
    user_rating
FROM (
    SELECT
        prime_genre,
        track_name,
        user_rating,
        RANK() OVER (PARTITION BY prime_genre ORDER BY user_rating DESC, rating_count_tot DESC) AS rank
    FROM AppleStore) AS A
WHERE A.rank = 1; -- All 5 genres

-- Add a new column 'RatingBucket' using NTILE function
SELECT
    id,
    track_name,
    user_rating,
    NTILE(5) OVER (ORDER BY user_rating DESC) AS RatingBucket
FROM AppleStore;

-- Create a view combining data from AppleStore and AppleStore_description_combined
CREATE VIEW AppleStore_Combined AS
SELECT
    A.*,
    AD.app_desc
FROM
    AppleStore A
JOIN
    AppleStore_description_combined AD ON A.id = AD.id;

-- Recommendations

-- 1. Paid apps have better ratings than free; consider charging more for quality content
-- 2. Apps supporting 10-30 languages have better ratings
-- 3. Finance and book apps have low ratings
-- 4. Apps with longer descriptions have better ratings
-- 5. A new app should aim for an average rating above 3.5
-- 6. Games and Entertainment genres have higher ratings
