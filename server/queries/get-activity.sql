select p1.parcel_id,
       p1.content,
       (select p2.content
        from property_versions p2
        where p2.parcel_id = p1.parcel_id
          and p2.updated_at < p1.updated_at
        order by p2.updated_at DESC
           limit
    1) as prior_content,
  p1.updated_at,
  p.address,
  p.name,
  round(st_xmin(p.geometry) * 100) as x1,
  round(st_xmax(p.geometry) * 100) as x2,
  round(st_ymin(p.geometry) * 100) as z1,
  round(st_ymax(p.geometry) * 100) as z2
from
    property_versions p1
    inner join
    properties p
on p.id = p1.parcel_id
order by
    p1.updated_at desc
    limit
    40;
