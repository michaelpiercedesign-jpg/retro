update
    streets s
set visible = st_intersects(
        s.geometry,
        (select st_union(st_buffer(p.geometry, 0.04)) from properties p where minted = true)
              ) returning s.name;