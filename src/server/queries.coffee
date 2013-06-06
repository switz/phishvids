store = require('./index').pvStore

{ deepCopy } = require 'racer-util/object'

COLLECTIONS = ['years', 'videos', 'setlists']

## Give query access

store.shareClient.use "connect", (shareRequest, next) ->
  req = shareRequest.req
  shareRequest.agent.connectSession = req.session  if req
  next()

###
A convenience method for declaring access control on queries. For usage, see
the example code below (`store.onQuery('items', ...`)). This may be moved
into racer core. We'll want to experiment to see if this particular
interface is sufficient, before committing this convenience method to core.
###
store.onQuery = (collectionName, callback) ->
  @shareClient.use "query", (shareRequest, next) ->
    return next()  if collectionName isnt shareRequest.collection
    session = shareRequest.agent.connectSession
    shareRequest.query = deepCopy(shareRequest.query)
    callback shareRequest.query, session, next

###
A convenience method for declaring access control on writes. For usage, see
the example code below (`store.onChange('users', ...`)). This may be moved
into racer core. We'll want to experiment to see if this particular
interface is sufficient, before committing this convenience method to core.
###
store.onChange = (collectionName, callback) ->
  @shareClient.use "validate", (shareRequest, next) ->
    collection = shareRequest.collection
    return next() if collection isnt collectionName
    agent = shareRequest.agent
    action = shareRequest.action
    docName = shareRequest.docName
    backend = shareRequest.backend

    # opData represents the ShareJS operation
    opData = shareRequest.opData

    # snapshot is the snapshot of the data after the opData has been applied
    snapshot = shareRequest.snapshot
    snapshotData = (if (opData.del) then opData.prev.data else snapshot.data)
    isServer = shareRequest.agent.stream.isServer
    callback docName, opData, snapshotData, agent.connectSession, isServer, next


store.shareClient.use "validate", (shareRequest, next) ->
  collection = shareRequest.collection
  return next() if COLLECTIONS.indexOf(collection) >= 0
  next(new Error("you can't write to any other collections."))

for collection in COLLECTIONS
  store.onQuery collection, (sourceQuery, session, next) -> next()
  store.onChange collection, (docId, opData, snapshotData, session, isServer, next) ->
    return next(new Error("you can't modify shit, yet.")) unless isServer
    next()
