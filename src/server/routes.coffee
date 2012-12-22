{ expressApp } = require './index'
## Routes

controller = require './controller'

expressApp.post '/api/v1/video/youtube', controller.api.v1.video.youtube.POST
expressApp.post '/api/v1/video/add', controller.api.v1.video.add.POST
expressApp.put '/api/v1/video/incorrect', controller.api.v1.video.incorrect.PUT
expressApp.put '/api/v1/video/audioOnly', controller.api.v1.video.audioOnly.PUT
expressApp.put '/api/v1/video/updateInfo', controller.api.v1.video.updateInfo.PUT
expressApp.all '/status', controller.status
expressApp.all '*', controller.all
