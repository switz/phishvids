monthNames = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"]

regexp = new RegExp([
  '(?:', #Short format
    '\\b',
    '(\\d{4}|\\d{1,2})',    #field.short_value_1
    '\\s*([./\-\\s])\\s*',      #field.short_del_1
    '(\\d{1,2})',           #field.short_value_2
    '\\s*([./\-\\s])\\s*',      #field.short_del 2
    '(\\d{4}|\\d{1,2})',    #field.short_value_3
    '\\b',
  ')|(?:',                  #Long format
    '\\b',
    '(',                    #field.long_month
    'jan(?:uary)?|',
    'feb(?:ruary)?|',
    'mar(?:ch)?|',
    'apr(?:il)?|',
    'may|',
    'jun(?:e)?|',
    'jul(?:y)?|',
    'aug(?:ust)?|',
    'sep(?:tember)?|',
    'oct(?:ober)?|',
    'nov(?:ember)?|',
    'dec(?:ember)?',
    ')',
    '\\s+',                 #required space
    '(\\d{1,2})',           #field.long_date
    '(?:st|rd|th)?\\b'
    '\\s*',                 #optional space
    ',?',                   #optional delimiter
    '\\s*',                 #optinal space
    '(\\d{4}|\\d{2})\\b',   #field.long_year
  ')'
].join(''),'i')

extractDate = (str) ->
  m = str.match(regexp)
  date = undefined
  if m
    idx = -1

    #Convert array form regexp result to named variables.
    #Makes it so much easier to change the regexp wihout
    #changing the rest of the code.
    field =
      all: m[++idx]
      short_value_1: m[++idx]
      short_del_1: m[++idx]
      short_value_2: m[++idx]
      short_del_2: m[++idx]
      short_value_3: m[++idx]
      long_month: m[++idx]
      long_date: m[++idx]
      long_year: m[++idx]

    #If field.long_month is set it is a date formated with named month
    if field.long_month then longDate field else shortDate field

longDate = (field) ->
  month = monthNames.indexOf(field.long_month.slice(0, 3).toLowerCase())

  # TODO: Add test for sane year
  # TODO: Add test for sane month
  # TODO: Add test for sane date
  date =
    date: new Date(field.long_year, month, field.long_date)
    month: month + 1
    day: +field.long_date
    year: +field.long_year

shortDate = (field) ->
  # Short format: value_1 del_1 value_2 del_2 value_3
  year = undefined
  month = undefined
  day = undefined

  unless field.short_del_1 is field.short_del_2
    # TODO: improve date catching
    if field.short_del_1 is "/" and field.short_del_2 is "-"

      # DD/MM-YYYY
      year = field.short_value_3
      month = field.short_value_2
      day = field.short_value_1
      #console.log "DMY", field.all, +year, +month, +day
    else

      # TODO: Add other formats here.
      # If delimiters don't match it isn't a sane date.
  else
    # 6/18/94 - 6/18/1994 MDY
    if (field.short_value_1.length is 1) and field.short_value_3.length > 1
      # MDY
      year = field.short_value_3
      month = field.short_value_1
      day = field.short_value_2
    # assmume YMD if
    #   or (value_1 > 31)
    else if (field.short_value_1 > 31) and (field.short_value_2 < 13) and (field.short_value_3 < 32)
      # YMD
      year = field.short_value_1
      month = field.short_value_2
      day = field.short_value_3
    else
      # MDY
      year = field.short_value_3
      month = field.short_value_1
      day = field.short_value_2
  if year isnt `undefined`
    year = +year
    #Handle years without a century
    #year 00-49 = 2000-2049, 50-99 = 1950-1999
    year += (if year < 50 then 2000 else 1900) if year < 100
    date =
      date: new Date(year, +month - 1, +day)
      month: +month
      day: +day
      year: year

module.exports = extractDate
