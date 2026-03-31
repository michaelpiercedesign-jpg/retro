select properties.id                            as id,
       y2 - y1                                  as height,
       address,
       properties.name                          as name,
       geometry_json                            as geometry,
       st_area(properties.geometry) * 100 * 100 as area,
       CAST(distance_to_center as double precision),
       CAST(distance_to_ocean as double precision),
       CAST(distance_to_closest_common as double precision),
       suburbs.name                             as suburb,
       lower(properties.owner)                  as owner
from properties
         left join suburbs on suburbs.id = properties.suburb_id
where st_intersects(properties.geometry, st_geomfromtext('point(' || $1 || ' ' || $2 || ' 0)', 3857)) limit
  1;