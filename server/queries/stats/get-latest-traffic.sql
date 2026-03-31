SELECT t.id,
       t.parcel_id,
       t.visits,
       p.id                             as pid,
       p.name                           as name,
       p.description                    as description,
       p.address                        as address,
       p.geometry_json                  as geometry,
       st_area(p.geometry) * 100 * 100  as area,

       round(st_xmin(p.geometry) * 100) as x1,
       round(st_xmax(p.geometry) * 100) as x2,
       round(st_ymin(p.geometry) * 100) as z1,
       round(st_ymax(p.geometry) * 100) as z2
FROM traffic t
         left join
     properties p
     on t.parcel_id = p.id
ORDER BY t.id DESC limit 12

