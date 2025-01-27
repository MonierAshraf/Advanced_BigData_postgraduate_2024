-- Query 3:
-- 1-	Create View for profit per area by joining rides table with fares and calculating profit per -- area according to provided calculations


CREATE VIEW PROFIT_PER_AREA_VIEW AS SELECT toAreaId(r.lon, r.lat) AS areaId, (AVG(f.fare) + SUM(f.tip)) AS profit, TUMBLE_END(r.rideTime,INTERVAL '15' MINUTE) as window_end
FROM Rides r, Fares f
WHERE r.rideId = f.rideId
AND NOT r.isStart
AND f.payTime BETWEEN r.rideTime - INTERVAL '10' MINUTE AND r.rideTime
GROUP BY toAreaId(r.lon, r.lat), TUMBLE(r.rideTime,INTERVAL '15' MINUTE);


-- SELECT from VIEW to check if the View created Successfully
SELECT * FROM PROFIT_PER_AREA_VIEW;


-- Final Query:
-- Subquery that uses match recognize to calculate number of 
-- taxi drivers per area who ended a ride and didn't pick up a new one for at least 30 minutes and 
-- then grouped them per area and every 15 minutes based on the match time.
-- joined the created view with this subquery over areaId and window_end to calculate profitability


SELECT s.areaId,s.window_end, (s.profit/e.empty_taxis) as profitability
FROM (SELECT * FROM PROFIT_PER_AREA_VIEW) AS s,
(
SELECT areaId, COUNT(taxiId) AS empty_taxis, TUMBLE_END(match_time, INTERVAL '15' MINUTE) AS window_end
FROM Rides
MATCH_RECOGNIZE (
PARTITION BY taxiId
ORDER BY rideTime
MEASURES
P.rideId AS rideId,
toAreaId(P.lon,P.lat) AS areaId,
D.rideTime + INTERVAL '30' MINUTE AS limit_time,
MATCH_ROWTIME() AS match_time
AFTER MATCH SKIP PAST LAST ROW
PATTERN (D P)
DEFINE
D AS NOT D.isStart,
P AS P.rideTime>D.rideTime + INTERVAL '30' MINUTE)
group by areaId,
TUMBLE(match_time, INTERVAL '15' MINUTE)
) AS e
WHERE e.areaId = s.areaId
AND e.window_end = s.window_end;