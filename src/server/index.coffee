http = require 'http'
path = require 'path'
express = require 'express'
derby = require 'derby'
racer = require 'racer'
MongoStore = require('connect-mongo')(express)
app = require '../app'
serverError = require './serverError'
io = racer.io

## SERVER CONFIGURATION ##

expressApp = express()
server = module.exports = http.createServer expressApp
module.exports.expressApp = expressApp

derby.use require('racer-db-mongo')

unless process.env.NODE_ENV is 'production'
  racer.use racer.logPlugin
  derby.use derby.logPlugin

store = module.exports.pvStore = derby.createStore
  listen: server
  db:
    type: 'Mongo'
    uri: process.env.pv_uri
    safe: true

ONE_DAY = 1000 * 60 * 60 * 24
root = path.dirname path.dirname __dirname
publicPath = path.join root, 'public'

expressApp
  .use(express.favicon("#{publicPath}/img/favicon.ico"))
  # Gzip static files and serve from memory
  .use(express.static publicPath)
  # Gzip dynamically rendered content
  .use(express.compress())

  # Uncomment to add form data parsing support
  .use(express.bodyParser())
  .use(express.methodOverride())

  # Uncomment and supply secret to add Derby session handling
  # Derby session middleware creates req.session and socket.io sessions
  .use(express.cookieParser())
  .use(store.sessionMiddleware
    secret: process.env.SESSION_SECRET || 'harryhood'
    cookie: {maxAge: ONE_DAY}
    store: new MongoStore
      url: process.env.pv_uri
  )
  # Adds req.getModel method
  .use(store.modelMiddleware())
  # Creates an express middleware from the app's routes
  .use(app.router())
  .use(expressApp.router)
  .use(serverError root)

routes = require './routes'

queries = require './queries'

# Infinite stack trace
Error.stackTraceLimit = Infinity

io.configure 'production', ->
  io.set "transports", ["xhr-polling", "jsonp-polling", "htmlfile"]

io.configure 'development', ->
  io.set "transports", ["websocket", "xhr-polling", "jsonp-polling", "htmlfile"]
