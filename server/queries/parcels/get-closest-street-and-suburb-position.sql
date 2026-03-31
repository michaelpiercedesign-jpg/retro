-- Query used for finding closest streets to the parcels and suburb center in case there are no streets around;
-- It is usef for Kicking the user outside the parcel

with suburb_query as (select st_asgeojson(s.position) ::json as position
from suburbs s
    INNER JOIN properties p
on s.id = p.suburb_id
where p.id = $1
    )
    , street_query AS (
SELECT ST_AsGeoJSON(ST_ClosestPoint(s.geometry, ST_Centroid(p.geometry)))::json AS position
FROM properties p, streets s
WHERE p.id = $1
ORDER BY ST_Distance(ST_ClosestPoint(s.geometry, ST_Centroid(p.geometry)), ST_Centroid(p.geometry)) ASC
    LIMIT 1
    )

SELECT street_query.position as street,
       suburb_query.position as suburb
from suburb_query
         LEFT JOIN street_query ON true;
