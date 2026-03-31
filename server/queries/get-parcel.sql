select p.id,
       y2 - y1                                                                                                                 as height,
       p.token,
       p.name,
       p.traffic_visits,
       address,
       p.visible,
       p.geometry_json                                                                                                         as geometry,
       st_area(p.geometry) * 100 * 100                                                                                         as area,
       array_to_json(array_agg(s))                                                                                             as streets,
       CAST(distance_to_center as double precision),
       CAST(distance_to_closest_common as double precision),
       CAST(distance_to_ocean as double precision),

       round(st_xmin(p.geometry) * 100)                                                                                        as x1,
       round(st_xmax(p.geometry) * 100)                                                                                        as x2,
       y1,
       y2,
       round(st_ymin(p.geometry) * 100)                                                                                        as z1,
       round(st_ymax(p.geometry) * 100)                                                                                        as z2,

       suburbs.name                                                                                                            as suburb,

       is_common,
       lower(p.owner)                                                                                                          as owner,
       a.name                                                                                                                  as owner_name,
       p.updated_at,
       (select array_to_json(array_agg(row_to_json(t)))
        from (select wallet, role from parcel_users where parcel_id = p.id) t)                                                 as parcel_users,
       label,
       p.description,
       lightmap_url,
       content,
       p.settings,
       p.island,
       p.kind                                                                                                                  as kind,
       p.minted                                                                                                                as minted
from properties p
         left join avatars a on lower(a.owner) = lower(p.owner)
         left join streets s on st_intersects(s.geometry, st_buffer(p.geometry, 0.04))
         left join suburbs on suburbs.id = p.suburb_id
where p.id = $1
  AND (p.minted = true OR p.visible or $2)
group by p.id, a.name, suburbs.name

