-- Lets work with AirBnB's data about hosts in Paris.

DROP TABLE IF EXISTS paris;

-- At first I'd like to add an id coolumn.

ALTER TABLE paris ADD  id int IDENTITY(1,1);

-- And set it as a PK for this dataset.

ALTER TABLE paris
ADD CONSTRAINT PK_paris PRIMARY KEY(ID);

-- Some of the columns are not the data type I need so let's change it.

ALTER TABLE paris ALTER COLUMN room_shared bit
ALTER TABLE paris ALTER COLUMN room_private bit
ALTER TABLE paris ALTER COLUMN host_is_superhost bit
ALTER TABLE paris ALTER COLUMN bedrooms int
ALTER TABLE paris ALTER COLUMN cleanliness_rating real;

-- By the way, what is the average guest_satisfaction rate in Paris?

SELECT AVG(CAST(guest_satisfaction as real)) AS average_sat_level
FROM paris;

--What host types are there?

SELECT DISTINCT room_type 
FROM paris;

--Let's filter some of the results. I need closest to the city center host with some additional conditions.

SELECT id, dist, metro_dist, superhost, guest_satisfaction, room_type
FROM paris 
WHERE cleanliness_rating > 8.0 AND bedrooms IN (1,2) AND superhost = 1 AND guest_satisfaction > '88'
GROUP BY  id, dist, metro_dist, superhost, guest_satisfaction, room_type
HAVING room_type <> 'Shared room'
ORDER BY guest_satisfaction DESC, dist;

-- Good. Let's save it as a view.

CREATE VIEW paris_filtered AS
SELECT id, dist, metro_dist, superhost, guest_satisfaction, room_type
FROM paris 
where cleanliness_rating > 8.0 AND bedrooms IN (1,2) AND superhost = 1 AND guest_satisfaction > '88'
GROUP BY  id, dist, metro_dist, superhost, guest_satisfaction, room_type
HAVING room_type <> 'Shared room';

--Let's play with some window functions.

SELECT *, COUNT(id) OVER (partition by room_type) AS acceptable_count
FROM paris_filtered;

-- Here I'd like to add location information to my view. I join "paris" and "paris_filtered" by dist because it is obvious that with that precision there are no two same locations.

SELECT paris.id, paris.dist, paris.metro_dist, paris.superhost, paris.guest_satisfaction, paris.room_type, CONCAT(lat, ', ', lng) AS location FROM paris_filtered
	LEFT JOIN paris on paris_filtered.dist = paris.dist
ORDER BY guest_satisfaction DESC, dist; 

-- Let's find out wether city center is too destinated from the host. 

SELECT id, dist, CONCAT(lat, ', ', lng) AS location,
	CASE
	WHEN dist > 4.0 THEN 'too far'
	WHEN dist > 1.5  THEN 'just fine'
	ELSE 'looks great'
	END AS center_distance
FROM paris 
order by dist;

--Let's filter our database by guest satisfaction rate with some subquery.

SELECT id, cleanliness_rating, guest_satisfaction, CONCAT(ROUND(dist,3),' ',  'km') AS distance_from_center
FROM paris
WHERE guest_satisfaction > (SELECT ROUND(AVG(CAST(guest_satisfaction as real)),3) FROM paris)
ORDER BY guest_satisfaction DESC;


-- And to finish with, lets create a function.

CREATE FUNCTION hostID (@id int)
RETURNS TABLE
AS
RETURN
(SELECT * FROM paris
WHERE id = @id);

SELECT * FROM hostID (188);
