-- Query 2:

-- Get Frequent Routes

SELECT *
FROM (
SELECT
pickupAreaId,
dropoffAreaId,
TUMBLE_END(matchTime, INTERVAL '30' MINUTE) AS endTime,
COUNT(pickupAreaId) AS noRides,
ROW_NUMBER() OVER (PARTITION BY pickupAreaId ORDER BY COUNT(pickupAreaId) DESC) AS Ranking
FROM Rides
MATCH_RECOGNIZE(
PARTITION BY taxiId, rideId
ORDER BY rideTime
MEASURES
toAreaId(S.lon, S.lat) AS pickupAreaId,
toAreaId(E.lon, E.lat) AS dropoffAreaId,
MATCH_ROWTIME() AS matchTime
AFTER MATCH SKIP PAST LAST ROW
PATTERN(S E)
DEFINE
S AS S.isStart = true,
E AS E.isStart = false
)
GROUP BY pickupAreaId, dropoffAreaId, TUMBLE(matchTime, INTERVAL '30' MINUTE))
WHERE Ranking <= 10;