-- get a list of 20 latest unique parcels (really their geometries)
with womped_parcels as (SELECT p.geometry
                        FROM womps AS w
                                 INNER JOIN properties AS p ON w.parcel_id = p.id
                        GROUP BY p.geometry
                        ORDER by max(w.id) DESC
    LIMIT 20
    )

-- get all streets that intersects the parcel that the womp is pointing at
SELECT streets.name,
       st_asgeojson(streets.geometry)::json as geometry, streets.visible,
       streets.kind,
       streets.island,
       streets.id
FROM womped_parcels as p
         INNER JOIN streets ON st_intersects(streets.geometry, st_buffer(p.geometry, 0.04))
GROUP by streets.id;
