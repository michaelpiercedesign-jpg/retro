select properties.id                             as id,
       height,
       address,
       suburbs.name                              as suburb,
       properties.island,
       properties.name                           as name,
       geometry_json                             as geometry,
       st_area(properties.geometry) * 100 * 100  as area,
       properties.content                        as content,
       round(st_xmin(properties.geometry) * 100) as x1,
       round(st_xmax(properties.geometry) * 100) as x2,
       y1,
       y2,
       round(st_ymin(properties.geometry) * 100) as z1,
       round(st_ymax(properties.geometry) * 100) as z2
from properties
         left join suburbs on suburbs.id = properties.suburb_id
where minted = true
order by ID asc;
