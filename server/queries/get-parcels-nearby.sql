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
       lower(properties.owner)                  as owner,
       avatars.name                             as owner_name
from properties
         left join
     avatars on avatars.owner = lower(properties.owner)
         left join
     suburbs on suburbs.id = properties.suburb_id
where st_distance(properties.geometry, (select geometry from properties where id = $1)) < $2
  and properties.id <> $1
  and ($3 or properties.name is not null)
order by st_distance(properties.geometry, (select geometry from properties where id = $1)) asc limit
  $4;
