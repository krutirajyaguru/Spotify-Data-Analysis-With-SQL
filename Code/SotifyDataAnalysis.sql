
-- -------------------------------------
-- EDA
-- -------------------------------------

SELECT COUNT(*) FROM spotify;

SELECT COUNT(DISTINCT artist) FROM spotify;

SELECT DISTINCT album_type FROM spotify;

SELECT MAX(duration_min) FROM spotify;

SELECT MIN(duration_min) FROM spotify;

SELECT * FROM spotify WHERE duration_min = 0; -- 2 rows

DELETE FROM spotify WHERE duration_min = 0;

SELECT * FROM spotify WHERE duration_min = 0; -- 0 row

SELECT DISTINCT most_played_on FROM spotify;


-- -------------------------------------
-- DATA ANALYSIS -- EASY Level
-- -------------------------------------

-- Q. 1 Retrieve the names of all tracks that have more than 1 billion streams.

SELECT * FROM spotify
WHERE stream > 1000000000;

-- Q. 2 List all albums along with their respective artists.

SELECT 
	DISTINCT album, 
	artist 
FROM spotify 
ORDER BY 1; -- ORDER BY First Column -- NOT RECOMMENDED

-- Q. 3 Get the total number of comments for tracks where licensed = TRUE.

	-- SELECT DISTINCT licensed FROM spotify;
SELECT 
	SUM(comments) AS total_comments 
FROM spotify
WHERE licensed = true;

-- Q. 4 Find all tracks that belong to the album type single.

SELECT 
	track
FROM spotify
WHERE album_type = 'single'; -- = / LIKE

-- Q. 5 Count the total number of tracks by each artist.

SELECT
	artist, 
	COUNT(track) AS total_tracks -- COUNT(*)
FROM spotify
GROUP BY artist
ORDER BY total_tracks;


-- -------------------------------------
-- DATA ANALYSIS -- Medium Level
-- -------------------------------------

-- Q. 6 Calculate the average danceability of tracks in each album.

SELECT 
	album, 
	AVG(danceability) AS avg_dance_ability
FROM spotify
GROUP BY album
ORDER BY avg_dance_ability DESC;

-- Q. 7 Find the top 5 tracks with the highest energy values.

SELECT 
	track,
	MAX(energy) AS mx_energy
FROM spotify
GROUP BY track
ORDER BY mx_energy DESC
LIMIT 5;

-- Q. 8 List all tracks along with their views and likes where official_video = TRUE.

SELECT 
	track,
	SUM(views) AS total_views,
	SUM(likes) AS total_likes
FROM spotify
WHERE official_video = true
GROUP BY track
ORDER BY total_views DESC;

-- Q. 9 For each album, calculate the total views of all associated tracks.

SELECT 
	album,
	track,
	SUM(views) AS total_views
FROM spotify
GROUP BY album, track
ORDER BY total_views DESC;

-- Q. 10 Retrieve the track names that have been streamed on Spotify more than YouTube.

SELECT * FROM
(SELECT 
	track, 
	COALESCE(SUM(CASE WHEN most_played_on = 'Spotify' THEN stream END),0) AS spotify_streaming,
	COALESCE(SUM(CASE WHEN most_played_on = 'Youtube' THEN stream END),0) AS youtube_streaming
FROM spotify
GROUP BY track) AS t1
WHERE spotify_streaming > youtube_streaming
	AND
	youtube_streaming <> 0



-- -------------------------------------
-- DATA ANALYSIS -- Advanced Level
-- -------------------------------------

-- Q. 11 Find the top 3 most-viewed tracks for each artist using window functions.

SELECT 
	artist,
	track,
	MAX(views) AS total_view
FROM spotify
GROUP BY artist,track
ORDER BY most_viewed DESC
LIMIT 3;

	-- each artist and total view for each track
	-- track with highest view for each artist
	-- dense rank (WINDOW FUNCTION)
	-- CTE and filter rank <=3	

	-- 1. DENSE_RANK()
		-- This is a window function that assigns a ranking to each row without skipping ranks when there are ties (unlike RANK(), which skips ranks).
		-- If multiple rows have the same value for MAX(views), they will receive the same rank, and the next rank will be incremented by 1, not skipped.
	-- 2. OVER (...)
		-- This defines the window in which DENSE_RANK() operates.
	-- 3. PARTITION BY artist
		-- This means the ranking resets for each artist.
		-- Each artist's tracks are ranked separately based on their highest views.
		
4. ORDER BY MAX(views) DESC
This orders the tracks by their maximum views (from highest to lowest).
Tracks with higher views will get a lower rank number (1 is the highest rank).
WITH ranking_artist AS (
	SELECT 
		artist,
		track,
		MAX(views) AS total_views,
		DENSE_RANK() OVER (PARTITION BY artist ORDER BY MAX(views) DESC) AS rank
	FROM spotify
	GROUP BY artist, track
	ORDER BY artist, total_views DESC
)

SELECT * FROM ranking_artist
WHERE rank <= 3;

-- Q. 12 Write a query to find tracks where the liveness score is above the average.
	
	-- SUBQUERY
	-- SELECT AVG(liveness) FROM spotify; -- avg - 0.19
	
SELECT 
	track,
	artist,
	liveness	
FROM spotify
WHERE liveness > (SELECT AVG(liveness) FROM spotify);

-- Q. 13 Use a WITH clause to calculate the difference between the highest and lowest energy values for tracks in each album.

WITH cte AS (
	SELECT 
		album, 
		MAX(energy) AS highest_energy,
		MIN(energy) AS lowest_energy
	FROM spotify
	GROUP BY album
	ORDER BY highest_energy DESC
)

SELECT 
	album,
	highest_energy - lowest_energy AS energy_difference
FROM cte
ORDER BY energy_difference DESC;

-- Q. 14 Find tracks where the energy-to-liveness ratio is greater than 1.2.

SELECT 
	track,
	energy_liveness
FROM spotify
WHERE energy_liveness > 1.2
ORDER BY energy_liveness;

-- Q. 15 Calculate the cumulative sum of likes for tracks ordered by the number of views, using window functions.

	-- SUM(likes): This is an aggregate function that sums up the likes column.
	-- OVER (...): This turns SUM(likes) into a window function, meaning it will calculate a cumulative sum for each row without collapsing rows like a normal SUM() with GROUP BY would.
	-- ORDER BY views: This orders the rows based on the views column before computing the cumulative sum.
SELECT 
    track,
    views,
    likes,
    SUM(likes) OVER (ORDER BY views) AS cumulative_likes
FROM spotify
WHERE likes <> 0;


-- -------------------------------------
-- Query Optimization Technique
-- -------------------------------------

 -- Initial Query Performance Analysis Using EXPLAIN

SELECT artist, COUNT(artist) AS no_of_track FROM spotify GROUP BY artist ORDER BY no_of_track DESC;

SELECT 
 	artist,
	track,
	views
FROM spotify
WHERE artist = 'A Day To Remember'
	AND
	most_played_on = 'Spotify'
ORDER BY stream DESC
LIMIT 8;


	-- EXPLAIN ANALYZE is a powerful SQL command used to understand how PostgreSQL executes a query and to analyze its performance. It helps in query optimization by showing execution plans, index usage, row estimations, and actual execution times.
EXPLAIN ANALYSE -- Planning Time: 0.109 ms -- Execution Time: 8.630 ms
SELECT 
 	artist,
	track,
	views
FROM spotify
WHERE artist = 'A Day To Remember'
	AND
	most_played_on = 'Spotify'
ORDER BY stream DESC
LIMIT 8;


CREATE INDEX artist_index ON spotify (artist);


EXPLAIN ANALYSE -- Planning Time: 0.183 ms -- Execution Time: 0.262 ms
SELECT 
 	artist,
	track,
	views
FROM spotify
WHERE artist = 'A Day To Remember'
	AND
	most_played_on = 'Spotify'
ORDER BY stream DESC
LIMIT 8;