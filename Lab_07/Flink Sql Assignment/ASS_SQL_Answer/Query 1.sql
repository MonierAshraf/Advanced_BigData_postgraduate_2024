-- Query 1:

-- using match recognize to determine the end timestamp of every ride and start timestamp of the next one and calculating the difference between those timestamps to get idle time which is used to 
-- calculate average idle time in minutes per areaId and 1 hour group based on match time

-- without using within statement

SELECT  AreaId, TUMBLE_END(match_time, INTERVAL '1' HOUR) AS window_end, AVG(idle_time) AS avg_idle_time
FROM Rides
MATCH_RECOGNIZE (
PARTITION BY taxiId
ORDER BY rideTime
MEASURES
P.rideId AS rideId,
toAreaId(P.lon, P.lat) AS AreaId,
D.rideTime AS drop_time,
P.rideTime AS next_trip_time,
TIMESTAMPDIFF(MINUTE, D.rideTime, P.rideTime) AS idle_time,
MATCH_ROWTIME() AS match_time
AFTER MATCH SKIP PAST LAST ROW
PATTERN (D P)
DEFINE
D AS NOT D.isStart,
P AS P.isStart)
GROUP BY AreaId, TUMBLE(match_time, INTERVAL '1' HOUR);



-- using within statement

SELECT  AreaId, TUMBLE_END(match_time, INTERVAL '1' HOUR) AS window_end, AVG(idle_time) AS avg_idle_time
FROM Rides
MATCH_RECOGNIZE (
PARTITION BY taxiId
ORDER BY rideTime
MEASURES
P.rideId AS rideId,
toAreaId(P.lon, P.lat) AS AreaId,
D.rideTime AS drop_time,
P.rideTime AS next_trip_time,
TIMESTAMPDIFF(MINUTE, D.rideTime, P.rideTime) AS idle_time,
MATCH_ROWTIME() AS match_time
AFTER MATCH SKIP PAST LAST ROW
PATTERN (D P) WITHIN INTERVAL '1' HOUR
DEFINE
D AS NOT D.isStart,
P AS P.isStart)
GROUP BY AreaId, TUMBLE(match_time, INTERVAL '1' HOUR);