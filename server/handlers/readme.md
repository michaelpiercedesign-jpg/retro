# Server/handlers

This is the directory for handlers of specific requests coming from controllers.
For example, the route:
```
  app.post('/api/collectibles/create', createCollectible)
```
in `server/controllers/collectibles.ts`, calls the method **createCollectible** in `collectible-handler.ts`.

A handler method will typically handle the express parameters `req`,`res` given by the route.

A PUT,POST route will usually have data in **req.body**, but it can also have data passed as flags in **req.query**, although unusual.
A GET route will usually have data either in **req.params** (for example /api/parcels/:id, :id will be found in `params`), but it can also have data passed as flags in **req.query**.

Handler methods will then respond to the requester using the `res` parameter.

For example, for a failed task:

`res.status(200).send({success:false,.. any other data})`

for a successful task:

`res.status(200).send({success:true,.. any other data})`

for a bad request?:

`res.status(400).send({success:false,.. any other data})`