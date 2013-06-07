http = require 'http'
path = require 'path'
express = require 'express'
derby = require 'derby'
racer = require 'racer'
liveDbMongo = require 'livedb-mongo'
coffeeify = require 'coffeeify'
redis = require 'redis'
racerBrowserChannel = require 'racer-browserchannel'
MongoStore = require('connect-mongo')(express)
app = require '../app'
serverError = require './serverError'

## SERVER CONFIGURATION ##

expressApp = express()
server = module.exports = http.createServer expressApp
module.exports.expressApp = expressApp

if process.env.REDIS_URI
  redisUrl = require('url').parse process.env.REDIS_URI
  redis = redis.createClient redisUrl.port, redisUrl.hostname
  redis.auth redisUrl.auth.split(":")[1]
else
  redis = redis.createClient()
  redis.select 1

store = module.exports.pvStore = derby.createStore
  listen: server
  db: liveDbMongo(process.env.pv_uri + '?auto_reconnect', safe: true)
  redis: redis

store.on 'bundle', (browserify) ->
  # Add support for directly requiring coffeescript in browserify bundles
  browserify.transform coffeeify

createUserId = (req, res, next) ->
  model = req.getModel()
  userId = req.session.userId ||= model.id()
  model.set '_session.userId', userId
  next()

ONE_DAY = 1000 * 60 * 60 * 24
root = path.dirname path.dirname __dirname
publicPath = path.join root, 'public'

mongo_store = new MongoStore url: process.env.pv_uri, ->
  expressApp
    .use(express.favicon("#{publicPath}/img/favicon.ico"))
    # Gzip dynamically rendered content
    .use(express.compress())
    .use(app.scripts store)

    # Gzip static files and serve from memory
    .use(express.static publicPath)

    .use(racerBrowserChannel store)
    # Adds req.getModel method
    .use(store.modelMiddleware())

    # Uncomment to add form data parsing support
    .use(express.bodyParser())
    .use(express.methodOverride())

    # Uncomment and supply secret to add Derby session handling
    # Derby session middleware creates req.session and browser channel sessions
    .use(express.cookieParser())
    .use(express.session
      secret: process.env.SESSION_SECRET || 'YOUR SECRET HERE'
      store: mongo_store
    )
    .use(createUserId)
    # Creates an express middleware from the app's routes
    .use(app.router())
    .use(expressApp.router)
    .use(serverError root)

  routes = require './routes'

  queries = require './queries'

# Infinite stack trace
Error.stackTraceLimit = Infinity
