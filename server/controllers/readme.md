# Server/Controllers

This is the directory for controllers of routes for specific features.

for example, all routes for collectibles `api/collectibles/...` will be found in `collectibles.ts`, such as

```js
  app.post('/api/collectibles/create', createCollectible)
```
which is a POST route `/api/collectibles/create` and receives data in its req.body. This data is then `handled` by the `handler` which can be found in the directory **server/handlers**.

A route doesn't always call a handler. A few routes will use `createRequestHandlerForQuery` or `queryAndCallback` which are functions calling specific queries in **server/queries** and then returning them straight back to the client. 
For example:
```js
createRequestHandlerForQuery(db, 'collectibles/get-collectibles-info', 'info')
```
will query the database using the query in `get-collectibles-info.sql`, and will respond `{success:boolean, info:{}}`.

Each controller is then called in `server.ts`:

eg:
```
// parcels controller
ParcelsController(db, passport, app)
// Womps
WompsController(db, passport, app)
// Spaces
SpacesController(db, passport, app)
// collections
CollectionsController(db, passport, app)
// collectibles
CollectiblesController(db, passport, app)
//stats
StatsController(db, passport, app)
//Events
EventsController(db, passport, app)
// Emoji Badges
EmojiBadgeController(db, passport, app)
// Mails controller
MailsController(db, passport, app)
```
