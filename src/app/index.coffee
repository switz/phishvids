derby = require('derby')

app = derby.createApp module
routes = require './routes.coffee'

app.use require('../../ui')
