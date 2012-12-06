# PhishVids

## More here soon!
If you have any questions in the meantime, you can email me at d@phishvids.com.

## Directory Structure
	/public -- public files served through express
	/src -- coffeescript source
 	  /api -- external APIs
	  /app -- derby app
	    functions -- route functions "controller"
	    index -- setup
	    routes -- routes
	  /extras -- extraneous scripts
	  /lib -- external modules
	  /server -- server files (express, derby server)
	  	index -- setup
	  	queries -- derby queries
	  	functions -- route functions
	/styles -- stylus css
	/ui -- derby components
	/views - derby html templates

## Tests
To run tests please install [Webspecter](https://github.com/jgonera/webspecter) and then execute the following command

	  webspecter tests/test.coffee

We have to set a slightly larger timeout to handle some of my rendering bugs.

## Config
This will not run without a file at `src/api/config.json`.

	{
	  "phishnetAPI":"",
	  "youtubeAPI":""
	}

You can get a Phish.net API key from [here](http://api.phish.net/).

## Setlist data
All setlist data is courtesy of the Mockingbird Foundation. Thanks to them, this is all possible.
