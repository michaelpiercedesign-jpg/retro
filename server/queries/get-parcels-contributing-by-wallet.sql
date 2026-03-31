select properties.id                             as id,
       y2 - y1                                   as height,
       address,
       properties.name,
       properties.owner,
       avatars.name                              as owner_name,
       geometry_json                             as geometry,
       st_area(properties.geometry) * 100 * 100  as area,
       CAST(distance_to_center as double precision),
       CAST(distance_to_ocean as double precision),
       CAST(distance_to_closest_common as double precision),
       suburbs.name                              as suburb,
       round(st_xmin(properties.geometry) * 100) as x1,
       round(st_xmax(properties.geometry) * 100) as x2,
       y1,
       y2 - y1                                   as y2,
       round(st_ymin(properties.geometry) * 100) as z1,
       round(st_ymax(properties.geometry) * 100) as z2,
       properties.island                         as island
from properties
         left join avatars on lower(avatars.owner) = lower(properties.owner)
         left join suburbs on suburbs.id = properties.suburb_id
where $1::text ILIKE 
any(
  ARRAY[
    (select array_agg(parcel_users.wallet) 
    from parcel_users 
    where parcel_users.parcel_id = properties.id 
    and parcel_users.role<>'excluded'
    )
    ]
    );