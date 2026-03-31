import { Express } from 'express'

import cache from '../cache'

import { Db } from '../pg'
import { PassportStatic } from 'passport'
import { isAdmin } from '../lib/helpers'

function assert(condition: any, message: string) {
  if (!condition) {
    throw new Error(message)
  }
}

function isInteger(value: any) {
  return typeof value === 'number' && Number.isInteger(value) && isFinite(value)
}

function isFloat(value: any) {
  return typeof value === 'number' && isFinite(value)
}

export default function AdminController(db: Db, passport: PassportStatic, app: Express) {
  // Get the top parcel id
  app.get('/api/admin/parcels/top', cache(false), async (req, res) => {
    const result = await db.query(
      'sql/get-top-parcel-id',
      `
      select
        id
      from
        properties
      order by
        id desc
      limit 1`,
    )

    const id = result.rows[0].id

    res.status(200).json({ success: true, id })
  })

  app.post('/api/admin/parcels/create', passport.authenticate('jwt', { session: false }), async (req, res) => {
    if (!isAdmin(req)) {
      res.status(403).json({ success: false, message: 'Unauthorized' })
      return
    }

    const { id, address, owner, island, x1, y1, z1, x2, y2, z2 } = req.body

    // console.log(JSON.stringify(req.body, null, 2))

    try {
      assert(isFloat(x1) && isFloat(y1) && isFloat(z1) && isFloat(x2) && isFloat(y2) && isFloat(z2), 'Invalid coordinates')
      assert(typeof address === 'string', 'Invalid address')
      assert(isInteger(id), 'Invalid id')
      assert(typeof island === 'string', 'Invalid island')
      assert(typeof owner === 'string', 'Invalid owner')
    } catch (e: any) {
      res.status(400).json({ success: false, message: e.message })
      return
    }

    // Create WKT POLYGON from x/z bounds (Y is height, ignored here)
    const scale = 1
    const minX = Math.min(x1, x2) * scale
    const maxX = Math.max(x1, x2) * scale
    const minZ = Math.min(z1, z2) * scale
    const maxZ = Math.max(z1, z2) * scale

    const polygon = `POLYGON((
      ${minX} ${minZ},
      ${minX} ${maxZ},
      ${maxX} ${maxZ},
      ${maxX} ${minZ},
      ${minX} ${minZ}
    ))`

    console.log(polygon)

    const kind = 'plot'

    try {
      var result = await db.query(
        'sql/create-parcel',
        `
        INSERT INTO 
          properties (id, address, owner, y1, y2, geometry, geometry_json, visible, island, kind)
        VALUES 
          ($1, $2, $3, $4, $5, ST_GeomFromText($6, 3857), ST_AsGeoJSON(ST_GeomFromText($6, 3857))::jsonb, true, $7, $8)
      `,
        [id, address, owner, y1, y2, polygon.replace(/\s+/g, ' ').trim(), island, kind],
      )
    } catch (e: any) {
      console.log(e)
      res.status(500).json({ success: false, message: e.message })
      return
    }

    res.status(200).json({ success: true })
  })

  // Upsert island
  app.post('/api/admin/islands', passport.authenticate('jwt', { session: false }), async (req, res) => {
    if (!isAdmin(req)) {
      res.status(403).json({ success: false, message: 'Unauthorized' })
      return
    }

    const { name, geometry, content } = req.body

    console.log(name, geometry, content)

    console.log(JSON.stringify(geometry, null, 2))

    try {
      var result = await db.query(
        'sql/upsert-island',
        `
      WITH upsert AS (
        UPDATE
          islands
        SET
          geometry = ST_SetSRID(ST_GeomFromGeoJSON($2), 3857),
          content = $3
        WHERE
          name = $1
        RETURNING *
      )

      INSERT INTO
        islands (name, geometry, content)
      SELECT
        $1, ST_SetSRID(ST_GeomFromGeoJSON($2), 3857), $3
      WHERE
        NOT EXISTS (SELECT 1 FROM upsert);
    `,
        [name, JSON.stringify(geometry), content],
      )
    } catch (e: any) {
      console.log(e)

      res.status(500).json({ success: false, message: e.toString() })
      return
    }

    console.log(result)

    res.status(200).json({ success: true })
  })
}
