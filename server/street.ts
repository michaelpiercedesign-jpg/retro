import log from './lib/logger'

import db from './pg'
import 'babylonjs' // BABYLON

const SRID = 3857
const DEGREES_TO_METRES = 100

export default class Street {
  id: number = undefined!
  name: string = undefined!
  geometry: any

  constructor(row: any) {
    if (row) {
      Object.assign(this, row)
    }
  }

  // in world space / meters
  get start() {
    return new BABYLON.Vector2(
      Math.round(Math.min(this.geometry.coordinates[0][0] * DEGREES_TO_METRES, this.geometry.coordinates[1][0] * DEGREES_TO_METRES)),
      Math.round(Math.min(this.geometry.coordinates[0][1] * DEGREES_TO_METRES, this.geometry.coordinates[1][1] * DEGREES_TO_METRES)),
    )
  }

  // in world space / meters
  get end() {
    return new BABYLON.Vector2(
      Math.round(Math.max(this.geometry.coordinates[0][0] * DEGREES_TO_METRES, this.geometry.coordinates[1][0] * DEGREES_TO_METRES)),
      Math.round(Math.max(this.geometry.coordinates[0][1] * DEGREES_TO_METRES, this.geometry.coordinates[1][1] * DEGREES_TO_METRES)),
    )
  }

  static async load() {
    const result = await db.query(
      'embedded/get-streets', // This query is "streets ahead"
      `
      SELECT
        *, st_asgeojson(geometry)::json as geometry
      FROM
        streets
      WHERE
        visible = true`,
    )

    log.info(`[Street] Loaded ${result.rows.length} streets.`)

    return result.rows.map((row: any) => new Street(row))
  }

  async save() {
    const result = await db.query(
      'embedded/insert-street',
      `
      INSERT INTO
        streets (name, geometry)
      VALUES
        ($1, ST_SnapToGrid(ST_SetSRID(ST_GeomFromGeoJSON($2), ${SRID}), 0.01))
      RETURNING
        id
      `,
      [this.name, JSON.stringify(this.geometry)],
    )

    this.id = result.rows[0].id
  }
}
