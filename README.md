# PhishVids

## More here soon!
If you have any questions in the meantime, you can email me at d@phishvids.com.

## Directory Structure
	/docs -- docco docs
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
	/ui -- derby components, ignore for now
	/views - derby html templates

## Tests
To run tests please install [Webspecter](https://github.com/jgonera/webspecter) and then execute the following command

    webspecter tests/test.coffee

