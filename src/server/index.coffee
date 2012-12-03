http = require 'http'
path = require 'path'
express = require 'express'
gzippo = require 'gzippo'
derby = require 'derby'
app = require '../app'
config = require './config'
serverError = require './serverError'
io = require('derby/node_modules/racer').io

## SERVER CONFIGURATION ##

expressApp = express()
server = module.exports = http.createServer expressApp

derby.use derby.logPlugin
derby.use require('racer-db-mongo')

store = module.exports.pvStore = derby.createStore
  listen: server
  db:
    type: 'Mongo'
    uri: config.uri
    safe: true

ONE_YEAR = 1000 * 60 * 60 * 24 * 365
root = path.dirname path.dirname __dirname
publicPath = path.join root, 'public'

expressApp
  .use(express.favicon())
  # Gzip static files and serve from memory
  .use(gzippo.staticGzip publicPath, maxAge: ONE_YEAR)
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
    cookie: {maxAge: ONE_YEAR}
  )

  # Adds req.getModel method
  .use(store.modelMiddleware())
  # Creates an express middleware from the app's routes
  .use(app.router())
  .use(expressApp.router)
  .use(serverError root)

## Routes

functions = require './functions'

expressApp.post '/api/v1/video/youtube', functions.api.v1.video.youtube.POST
expressApp.post '/api/v1/video/add', functions.api.v1.video.add.POST
expressApp.put '/api/v1/video/incorrect', functions.api.v1.video.incorrect.PUT
expressApp.put '/api/v1/video/audioOnly', functions.api.v1.video.audioOnly.PUT
expressApp.put '/api/v1/video/updateInfo', functions.api.v1.video.updateInfo.PUT
expressApp.all '/status', functions.status
expressApp.all '*', functions.all

queries = require './queries'

# to stop from the memory leak warnings
# temporary fix until I figure out a solution to stop it from breaking
# process.setMaxListeners(0)

if process.env.NODE_ENV is "production"
  io.configure ->
    io.enable "browser client etag"
    io.set "log level", 2
    io.set "transports", ["websocket", "flashsocket", "xhr-polling", "jsonp-polling", "htmlfile"]
  # If error is thrown, don't crash the server
  process.on 'uncaughtException', (err) ->
    console.log err.stack
    console.log "Node NOT Exiting..."
