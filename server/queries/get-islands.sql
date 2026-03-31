select *,
       st_asgeojson(st_centroid(geometry)) ::json as position,
  st_asgeojson(geometry)::json as geometry
from
    islands
order by
    id asc;
