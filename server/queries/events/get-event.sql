SELECT parcel_events.*,
       (SELECT name FROM avatars WHERE lower(avatars.owner) = lower(parcel_events.author)) AS author_name,
       (SELECT name FROM avatars WHERE lower(avatars.owner) = lower(properties.owner))     AS parcel_owner_name,
       properties.address                                                                  AS parcel_address,
       properties.description                                                              AS parcel_description,
       properties.geometry_json                                                            AS geometry,
       round(st_xmin(properties.geometry) * 100)                                           AS x1,
       round(st_xmax(properties.geometry) * 100)                                           AS x2,
       properties.y1,
       properties.y2,
       properties.y2                                                                       AS height,
       round(st_ymin(properties.geometry) * 100)                                           AS z1,
       round(st_ymax(properties.geometry) * 100)                                           AS z2
FROM parcel_events
         LEFT JOIN
     properties ON parcel_events.parcel_id = properties.id
WHERE parcel_events.id = $1
ORDER BY parcel_events.id DESC LIMIT 1;
