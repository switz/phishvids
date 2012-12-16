http = require 'http'
path = require 'path'
express = require 'express'
gzippo = require 'gzippo'
derby = require 'derby'
app = require '../app'
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
    uri: process.env.pv_uri
    safe: true

ONE_YEAR = 1000 * 60 * 60 * 24 * 365
root = path.dirname path.dirname __dirname
publicPath = path.join root, 'public'

expressApp
  .use(express.favicon())
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
    cookie: {maxAge: ONE_YEAR}
  )

  # Adds req.getModel method
  .use(store.modelMiddleware())
  # Creates an express middleware from the app's routes
  .use(app.router())
  .use(expressApp.router)
  .use(serverError root)

## Routes

controller = require './controller'

expressApp.post '/api/v1/video/youtube', controller.api.v1.video.youtube.POST
expressApp.post '/api/v1/video/add', controller.api.v1.video.add.POST
expressApp.put '/api/v1/video/incorrect', controller.api.v1.video.incorrect.PUT
expressApp.put '/api/v1/video/audioOnly', controller.api.v1.video.audioOnly.PUT
expressApp.put '/api/v1/video/updateInfo', controller.api.v1.video.updateInfo.PUT
expressApp.all '/status', controller.status
expressApp.all '*', controller.all

queries = require './queries'

# Infinite stack trace
Error.stackTraceLimit = Infinity

if process.env.NODE_ENV is "production"
  io.configure ->
    io.enable "browser client etag"
    io.set "log level", 2
    io.set "transports", ["websocket", "flashsocket", "xhr-polling", "jsonp-polling", "htmlfile"]
  # If error is thrown, don't crash the server
  process.on 'uncaughtException', (err) ->
    console.log err.stack
    console.log "Node NOT Exiting..."
