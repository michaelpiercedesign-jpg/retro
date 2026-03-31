SELECT streets.name,
       st_asgeojson(streets.geometry)::json as geometry, streets.visible,
       streets.kind,
       streets.island,
       streets.id
FROM streets
ORDER BY random() LIMIT 20;