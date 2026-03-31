SELECT parcel_events.*,
       (SELECT name FROM avatars WHERE lower(avatars.owner) = lower(parcel_events.author)) AS author_name,
       properties.name                                                                     AS parcel_name,
       properties.address                                                                  AS parcel_address,
       (SELECT name FROM suburbs WHERE properties.suburb_id = suburbs.id)                  AS parcel_suburb,
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
WHERE parcel_events.expires_at > NOW()
ORDER BY parcel_events.starts_at ASC LIMIT
    $1::integer
OFFSET $2::integer * $1::integer;
