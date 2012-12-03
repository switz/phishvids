feature "Check Vitals", (context, browser, $) ->
  browser.page.onConsoleMessage = (msg, lineNum, sourceId) ->
    console.log "CONSOLE: " + msg + " (from line #" + lineNum + " in \"" + sourceId + "\")"

  browser.page.onError = (msg, trace) ->
    console.log msg
    trace.forEach (item) ->
      console.log "  ", item.file, ":", item.line

  describe "Index Column", ->
    before (done) ->
      browser.visit "http://localhost:3000", -> done()

    it "loads javascript", (done) ->
      js = -> browser.evaluate -> window.DERBY.model?
      wait.until js, ->
        js().should.be.true
        done()

    it "has the correct title", ->
      title = browser.evaluate -> document.title
      assert.equal title, 'Phish Videos'
    it "contains #year-list-container div", ->
      assert.ok $("#year-list-container").length
    it "contains 21 years", ->
      assert.equal $("#year-list-container ul li").length, 20

  describe "Add a video", ->
    before (done) ->
      browser.visit "http://localhost:3000", -> done()

    it "has the correct date", ->
      date = $('.span10 .validate .validate-video')
      assert.ok true


  describe "Year Column", ->
    before (done) ->
      browser.visit "http://localhost:3000/2010", -> done()

    it "has the correct title", ->
      title = browser.evaluate -> document.title
      assert.equal title, '2010 Phish Videos'
    it "contains #year-container", ->
      $("#year-container").length.should.be.above 0
    it "2010 contains 51 shows", ->
      assert.equal $("#year-container ul li").length, 51

  describe "Setlist Column", ->
    before (done) ->
      browser.visit "http://localhost:3000/2010/10/20", -> done()

    it "has the correct title", ->
      title = browser.evaluate -> document.title
      title.should.equal '10/20/2010 | Phish Videos'
    it "contains #show-container", ->
      $("#show-container").length.should.be.above 0
    it "10/20/10 contains 21 songs", ->
      assert.equal $("#show-container ul li").length, 27

  describe "Song Column", ->
    before (done) ->
      browser.visit "http://localhost:3000/2010/10/20/01", -> done()

    it "loads javascript", (done) ->
      js = -> browser.evaluate -> window.DERBY.view._appExports.report?
      wait.until js, ->
        js().should.be.true
        done()

    it "has the correct title", ->
      title = browser.evaluate -> document.title
      assert.equal title, 'My Soul 10/20/2010 | Phish Videos'
    it "contains #song-container", ->
      $("#song-container").length.should.be.above 0
    it "10/20/10 My Soul contains > 0 videos", ->
      $("#song-container ul li").length.should.be.above 0

    it "can report incorrect video", ->
      browser.evaluate -> window.DERBY.view._appExports.report(null, $('.report')[0])
      wait.until $("#song-container ul li .report-actions .incorrect-link").is.visible, ->
        $("#song-container ul li .report-actions .incorrect-link").is.visible().should.be.true
        del = browser.evaluate -> window.DERBY.model.at('_song.'+window.DERBY.model.at($("#song-container ul li")[1]).path()).get('del')
        del.should.be.true
        browser.page.render('pv.jpg')

  describe "tiph", ->
    before (done) ->
      browser.visit "http://localhost:3000/tiph", -> done()

    it "has the correct title", ->
      title = browser.evaluate -> document.title
      assert.equal title, 'Today in Phish History | Phish Videos'
    it "contains #tiph-container", ->
      $("#tiph-container").length.should.be.above 0
    it "contains an h2", ->
      $('#tiph-container h2').text.should.equal 'Today In Phish History'
    it "has videos", ->
      today = new Date()
      if $('#tiph-container h3').is.present()
        $('#tiph-container h3').text.should.equal "Sorry, there were no videos found on #{today.getMonth()+1}/#{today.getDate()}."
      else
        # untested at the moment
        $('#tiph-container .tiph').length.should.be.above 0

  describe "Add a video", ->
    before (done) ->
      browser.visit "http://localhost:3000", -> done()

    it "loads javascript", (done) ->
      js = -> browser.evaluate -> window.DERBY.model?
      wait.until js, ->
        js().should.be.true
        done()

    it "Boogie On", (done) ->
      js = -> browser.evaluate ->
        window.DERBY.model.set('_newVideo', 'http://www.youtube.com/watch?v=tzP0CnYhSdQ')
        window.DERBY.model.get('_newVideo')?
      wait.until js, ->
        browser.evaluate -> window.DERBY.view._appExports.add()
        wait.until $(".span10 .validate .validate-video").is.present, ->
          $(".span10 .validate .validate-video").length.should.be.above 0
          done()

    it "has the correct date", ->
      date = $('.span10 .validate .validate-video .date-approval-container option[selected]')
      date[0].text.should.equal '6'
      date[1].text.should.equal '7'
      date[2].text.should.equal '2012'
