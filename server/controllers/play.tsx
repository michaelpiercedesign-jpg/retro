import { h } from 'preact'
import { decodeCoords, encodeCoords } from '../../common/helpers/utils'
import ClientRoot from '../../web/src/client-root'
import JsonData from '../../web/src/components/json-data'
import authParcel, { authParcelByNFT } from '../auth-parcel'
import cache from '../cache'
import renderRoot from '../handlers/render-root'
import { Islands } from '../islands'
import Parcel from '../parcel'
import db, { Db } from '../pg'
import { PassportStatic } from 'passport'
import { Express } from 'express'
import 'babylonjs' // BABYLON
import fs from 'fs'
import path from 'path'
import url from 'url'
import type { ParsedUrlQueryInput } from 'querystring'
import { VoxelsUser } from '../user'

const isProduction = process.env.NODE_ENV === 'production'

export default function PlayController(db: Db, passport: PassportStatic, app: Express) {
  app.get('/play', cache('60 seconds'), passport.authenticate(['jwt', 'anonymous'], { session: false }), async (req, res) => {
    const islands = await Islands.fetch()
    const coords = req.query.coords
    const mode = req.query.mode

    let parcel

    if (coords && typeof coords === 'string') {
      // parcel used for fastboot
      try {
        parcel = await Parcel.loadFromCoords(coords)
      } catch (e) {
        parcel = null
      }
    }

    let nftAuth = false
    // If fastboot parcel and parcel only allows entry if NFTs are owned check if user fills conditions of entry
    // Dont redirect if orbit mode
    if (parcel && mode !== 'orbit' && parcel.onlyTokenHoldersCanEnter) {
      nftAuth = await doesUserOwnsNFTs(parcel, req.user ?? null)

      if (!nftAuth) {
        // user is not allowed inside parcel
        const newPosition = await getSuburbCenterOfParcel(parcel)

        const previousCoords = decodeCoords(coords as string)
        previousCoords.position = newPosition
        delete req.query.coords
        req.query.coords = encodeCoords(previousCoords)
        req.query.rejectedFrom = parcel.id.toString() // this is to know that the user has been redirected
        // Redirect user (kick user out of the parcel)
        res.redirect(
          url.format({
            pathname: `/play`,
            query: req.query as ParsedUrlQueryInput,
          }),
        )
        return
      }
    }

    // user was rejected from a parcel,
    // get the parcel that rejected the user as fastboot so the bouncer can show the UI saying the user got kickedout
    if (!parcel && req.query.rejectedFrom && !isNaN(parseInt(req.query.rejectedFrom as string))) {
      try {
        parcel = await Parcel.load(parseInt(req.query.rejectedFrom as string))
      } catch (e) {
        parcel = null
      }
    }

    const windowTitle = isProduction ? 'Voxels' : '⚙️ Voxels local'
    const ogTitle = `${parcel?.name || parcel?.address || 'In-world'} | Voxels`
    const ogDescription = parcel?.description ? parcel.description : 'Visit this Voxels Parcel!'
    // Add 'bouncerShouldAllowUser' to the parcel summary
    const summary = (parcel && { ...parcel.summary, ...(nftAuth ? { bouncerShouldAllowUser: true } : {}) }) || {}

    const html = (
      <ClientRoot title={windowTitle} ogTitle={ogTitle} ogDescription={ogDescription}>
        <JsonData id="islands" data={islands} />
        {!!parcel && <JsonData id="parcel" data={summary} dataId={parcel.id} />}
      </ClientRoot>
    )

    res.send(renderRoot(html))
  })
}

const doesUserOwnsNFTs = async (parcel: Parcel, user: VoxelsUser | null) => {
  const auth = await authParcel(parcel, user)
  return auth && auth !== 'Sandbox' ? true : await authParcelByNFT(parcel, user)
}

type point = { type: 'Point'; coordinates: any[] }

const getSuburbCenterOfParcel = async (parcel: Parcel): Promise<BABYLON.Vector3> => {
  // Fallback position, the user just gets kicked outside the parcel boundaries
  const fallbackPosition = new BABYLON.Vector3(parcel.x1 - 0.25, parcel.y1 + 0.75, parcel.z1 - 0.25)

  const CLOSEST_ST_QUERY = fs.readFileSync(path.join(__dirname, 'queries/parcels', 'get-closest-street-and-suburb-position.sql')).toString()

  const res = await db.query('embedded/get-closest-street-suburb', CLOSEST_ST_QUERY, [parcel.id])

  const response = res?.rows[0] as { street: point | null; suburb: point }

  if (response) {
    const position = response.street || response.suburb

    return new BABYLON.Vector3(position.coordinates[0] * 100, 2.5, position.coordinates[1] * 100)
  } else {
    return fallbackPosition
  }
}
