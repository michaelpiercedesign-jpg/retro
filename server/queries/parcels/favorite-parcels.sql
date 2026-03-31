select properties.id                                   as id,
       y2 - y1                                         as height,
       address,
       suburbs.name                                    as suburb,
       properties.island,
       properties.name                                 as name,
       geometry_json                                   as geometry,
       round(st_area(properties.geometry) * 100 * 100) as area,
       CAST(distance_to_center as double precision),
       CAST(distance_to_ocean as double precision),
       CAST(distance_to_closest_common as double precision),
       lower(properties.owner)                         as owner,
       avatars.name                                    as owner_name,
       round(st_xmin(properties.geometry) * 100)       as x1,
       round(st_xmax(properties.geometry) * 100)       as x2,
       y1,
       label,
       y2 - y1                                         as y2,
       round(st_ymin(properties.geometry) * 100)       as z1,
       round(st_ymax(properties.geometry) * 100)       as z2
from properties
         join
     favorites on favorites.parcel_id = properties.id
         join
     suburbs on suburbs.id = properties.suburb_id
         join
     avatars on lower(avatars.owner) = lower(properties.owner)
where lower(favorites.wallet) like lower($1)
order by (CASE WHEN ($4::text = 'id' AND $5::boolean) THEN properties.id::varchar::int END) ASC,
         (CASE WHEN ($4::text = 'id' AND NOT $5::boolean) THEN properties.id::varchar::int END) DESC,
         (CASE WHEN ($4::text = 'name' AND $5::boolean) THEN properties.name::varchar END) ASC,
         (CASE WHEN ($4::text = 'name' AND NOT $5::boolean) THEN properties.name::varchar END) DESC,
         (CASE WHEN ($4::text = 'height' AND $5::boolean) THEN properties.y2::varchar::int END) ASC,
         (CASE WHEN ($4::text = 'height' AND NOT $5::boolean) THEN properties.y2::varchar::int END) DESC,
         (CASE WHEN ($4::text = 'island' AND $5::boolean) THEN properties.island::varchar END) ASC,
         (CASE WHEN ($4::text = 'island' AND NOT $5::boolean) THEN properties.island::varchar END) DESC,
         (CASE
              WHEN ($4::text = 'suburb' AND $5::boolean)
                  THEN (select name from suburbs where properties.suburb_id = suburbs.id)::varchar END) ASC,
         (CASE
              WHEN ($4::text = 'suburb' AND NOT $5::boolean)
                  THEN (select name from suburbs where properties.suburb_id = suburbs.id)::varchar END) DESC,
         (CASE WHEN ($4::text = 'area' AND $5::boolean) THEN st_Area(properties.geometry) END) ASC,
         (CASE WHEN ($4::text = 'area' AND NOT $5::boolean) THEN st_Area(properties.geometry) END) DESC,
         (CASE
              WHEN ($4::text = 'distance' AND $5::boolean)
                  THEN (st_distance(properties.geometry, st_geomfromtext('point(0 0)', 3857)) * 100) END) ASC,
         (CASE
              WHEN ($4::text = 'distance' AND NOT $5::boolean)
                  THEN (st_distance(properties.geometry, st_geomfromtext('point(0 0)', 3857)) * 100) END) DESC limit
  $2
offset coalesce(($2::integer * $3::integer),0);
