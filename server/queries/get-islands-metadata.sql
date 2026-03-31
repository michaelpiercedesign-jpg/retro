select 
id,
name,
other_name,
st_asgeojson(st_centroid(geometry)) ::json as position
from
    islands
order by
    id asc;
