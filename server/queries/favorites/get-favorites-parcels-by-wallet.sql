select favorites.updated_at                                         as favorite_updated_at,
       p.id,
       y2 - y1                                                      as height,
       address,
       p.name,
       geometry_json                                                as geometry,
       st_area(p.geometry) * 100 * 100                              as area,
       CAST(distance_to_center as double precision),
       CAST(distance_to_closest_common as double precision),
       CAST(distance_to_ocean as double precision),

       round(st_xmin(p.geometry) * 100)                             as x1,
       round(st_xmax(p.geometry) * 100)                             as x2,
       y1,
       y2 - y1                                                      as y2,
       round(st_ymin(p.geometry) * 100)                             as z1,
       round(st_ymax(p.geometry) * 100)                             as z2,

       suburbs.name                                                 as suburb,
       p.island,

       description,
       json_build_object('features', (content ->>'features')::json) as content
from favorites
         join properties p on p.id = favorites.parcel_id
         left join suburbs on suburbs.id = p.suburb_id
where lower(wallet) = lower($1)