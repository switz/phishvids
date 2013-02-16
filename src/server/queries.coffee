store = require('./index').pvStore

store.accessControl = true

store.readPathAccess 'videos.*', () -> #captures, next) ->
  next = arguments[arguments.length-1]
  next(true)

store.readPathAccess 'years.*', () -> #captures, next) ->
  next = arguments[arguments.length-1]
  next(true)

store.readPathAccess 'setlists.*', () -> #captures, next) ->
  next = arguments[arguments.length-1]
  next(true)

## Query Motifs

store.query.expose 'years', 'getYearsShows', (year) ->
  @where('year').equals(year)

store.query.expose 'videos', 'checkIfVideosExist', (year) ->
  @where('year').equals(year)
    .where('approved').equals(true)
    .one

store.query.expose 'videos', 'checkIfVideosExistForSetlist', (showid) ->
  @where('showid').equals(showid)
  .where('approved').equals(true)

store.query.expose 'videos', 'getVideos', (year, month, day, number) ->
  @where('year').equals(year)
    .where('month').equals(month)
    .where('day').equals(day)
    .where('number').equals(number)
    .where('approved').equals(true)

store.query.expose 'videos', 'tiph', ->
  today = new Date()
  @where('month').equals(today.getMonth()+1)
    .where('day').equals(today.getDate())

store.query.expose 'setlists', 'getSetlist', (year, month, day) ->
  @where('year').equals(year)
    .where('month').equals(month)
    .where('day').equals(day)
    .one

## Give query access

giveQueryAccess = (col, fn) ->
  store.queryAccess col, fn, (methodArgs) ->
    accept = arguments[arguments.length - 1]
    accept true # for now

obj =
  years: ['getYearsShows']
  videos: ['checkIfVideosExist', 'checkIfVideosExistForSetlist', 'getVideos', 'tiph']
  setlists: ['getSetlist']

for col of obj
  obj[col].map (fn) -> giveQueryAccess col, fn
