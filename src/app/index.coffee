derby = require('derby')

app = derby.createApp module
routes = require './routes'

app.use require('../../ui')
