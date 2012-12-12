{ addZero } = require './utils'

jsonToSetlist = (json, blue) ->
  # Each song recieves an incremented number
  number = 1
  # Break up each link and extract information
  # Grab title, url, segue (from previous song), sup (from previous song), and number
  #
  # TODO: There's an extra EMPTY link that's being caught, which is causing (number) to be mismatched and plus an extra one on every set past 1
  destructure = (s) ->
    # Crappy hack to realign numbers every set passed 1
    number--
    # try splitting with /(-?>)|,/
    s.split("</a>").map (x) ->
      title: x[x.lastIndexOf('>')+1..]
      url: x.match(/href="([^"]+)"/)?[1]
      segue: x.match(/(,|>|->)/)?[0]
      sup: x.match(/\[[0-9]{1,2}\]/)?[0]
      number: addZero ++number
      blue: if blue[number] then ' blue' else ''
  # Put into an object
  reduceCb = (mem, curr) ->
    mem[curr[0...curr.indexOf ':']] = destructure curr; mem
  # Split by set number and pass in to reduce function
  json.setlistdata.split(/<span[^>]+>Set /)[1..].reduce reduceCb, {}

# ### fixSegue(arr)
# arr: (array) single set returned from PhishAPI
#
# Return (array) arr
fixSegue = (arr) ->
  for j of arr
    for i of arr[j]
      current = arr[j][i]
      # If title doesn't exist, then it's not a real song -> remove
      unless current.title
        arr[j].splice i, i
      # Skip first song
      else if i > 0
        # If segue is a comma, remove it
        if current.segue is ','
          current.segue = ''
        # Replace last song's segue and sup with the current
        arr[j][i-1].segue = current.segue
        arr[j][i-1].sup = current.sup
    # Remove segue and sup from last song
    # TODO: If last song has a sup, then we need to check and make sure it stays
    last = arr[j].length-1
    arr[j][last].segue = ''
    arr[j][last].sup = ''
  # Return (array) arr
  arr

getShow = (show, callback) ->
  PhishAPI = require '../api/external_apis/phish_net'
  if show.showDate is undefined
    return callback {error:'No Date'}, show

  showDate = "#{show.showDate.year}-#{addZero(show.showDate.month)}-#{addZero(show.showDate.day)}"
  PhishAPI.get showDate, (json) ->
    if json is undefined or json.success is 0
      return callback("Could not find a show on <em>#{addZero(show.showDate.month)}/#{addZero(show.showDate.day)}/#{show.showDate.year}</em>. (Or Phish.net is down)", show)
    callback undefined, show, json

compareTitleToSetlist = (setlist, title) ->
  title = title.replace(/[^a-zA-Z -]/g, '').toLowerCase()
  for i of setlist
    for j of setlist[i]
      if title.indexOf(setlist[i][j].title.replace(/[^a-zA-Z -]/g,'').toLowerCase()) >= 0
        setlist[i][j].selected = true
  setlist

module.exports =
  {
    jsonToSetlist
    fixSegue
    getShow
    compareTitleToSetlist
  }
