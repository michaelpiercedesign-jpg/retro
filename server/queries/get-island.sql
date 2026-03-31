select s.id,
       s.name,
       st_asgeojson(st_centroid(s.geometry)) ::json as position,
  array_to_json(array_agg(p)) as parcels
from
    islands s
    left join
    properties p
on
    st_intersects(p.geometry, st_buffer(st_centroid(s.geometry), 0.5))
where
    regexp_replace(lower (s.name)
    , ' +'
    , '-'
    , 'g') = $1::text
group by
    s.id;


