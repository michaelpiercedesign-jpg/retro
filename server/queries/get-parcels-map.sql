/* Get parcels for the map; the purpose of this is to have a smaller query */
select properties.id                                                                                                                    as id,
       address,
       properties.name                                                                                                                  as name,
       properties.description                                                                                                           as description,
       properties.is_common                                                                                                             as is_common,
       suburbs.name                                                                                                                     as suburb,
       (select array_to_json(array_agg(row_to_json(t)))
        from (select wallet, role from parcel_users where parcel_id = properties.id) t)                                                 as parcel_users,
       properties.settings,
       island,
       (select name from suburbs where id = properties.suburb_id)                                                                       as suburb,
       geometry_json                                                                                                                    as geometry,
       lower(properties.owner)                                                                                                          as owner,
       avatars.name                                                                                                                     as owner_name,
       round(st_xmin(properties.geometry) * 100)                                                                                        as x1,
       round(st_xmax(properties.geometry) * 100)                                                                                        as x2,
       label,
       y2 - y1                                                                                                                          as y2,
       round(st_ymin(properties.geometry) * 100)                                                                                        as z1,
       round(st_ymax(properties.geometry) * 100)                                                                                        as z2,
       (listed_at >= (NOW() - interval '4 days')) ::boolean as on_sale
from properties
         left join suburbs on properties.suburb_id = suburbs.id
         left join
     avatars on avatars.owner = lower(properties.owner)
where minted = true
order by ID asc;
