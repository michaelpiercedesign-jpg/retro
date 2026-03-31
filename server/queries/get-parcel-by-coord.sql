select p.id,
       y2 - y1                                                                                                                 as height,
       p.token,
       p.name,
       address,
       p.kind,
       p.geometry_json                                                                                                         as geometry,
       st_area(p.geometry) * 100 * 100                                                                                         as area,
       round(st_xmin(p.geometry) * 100)                                                                                        as x1,
       round(st_xmax(p.geometry) * 100)                                                                                        as x2,
       y1,
       y2,
       y2 - y1                                                                                                                 as height,
       round(st_ymin(p.geometry) * 100)                                                                                        as z1,
       round(st_ymax(p.geometry) * 100)                                                                                        as z2,
       p.island,
       (select name from suburbs where p.suburb_id = suburbs.id)                                                               as suburb,
       memoized_hash                                                                                                           as hash,
       lower(p.owner)                                                                                                          as owner,
       -- Optimize: Use aggregated LEFT JOIN instead of correlated subquery for better performance
       COALESCE(pu_agg.parcel_users, '[]'::json)                                                                               as parcel_users,
       label,
       p.description,
       lightmap_url,
       content,
       p.settings,
       -- Optimize: Use subquery to force index usage on avatars lookup
       (SELECT name FROM avatars WHERE lower(owner) = lower(p.owner) LIMIT 1)                                                 as owner_name,
       visible
from properties p
         left join
     (select parcel_id, 
             array_to_json(array_agg(json_build_object('wallet', wallet, 'role', role))) as parcel_users
      from parcel_users
      group by parcel_id) pu_agg on pu_agg.parcel_id = p.id
where ($2 BETWEEN y1 and y2)
  and st_intersects(geometry, st_geomfromtext('point(' || $1 || ' ' || $3 || ' 0)', 3857))
ORDER BY ST_Area(geometry) limit
  1;