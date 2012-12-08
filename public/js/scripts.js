var customRenderFunction = function(document_type, item) {
  var out = '<p class="title">' + item['title'] + '</p>';
  window.A = item
  if (item.sections && item.sections.length && !item.sections[0].match(/(^Paste in links)/i))
    return out.concat('<p class="section">' + item.sections[0].replace(/null(.*)$/, '') + '</p>');
  else
    return out;
}

var PhishVids = function() {
  $('#st-search-input').swiftype({
    renderFunction: customRenderFunction,
    engineKey: '2q5QqEPzcuk6Y2oq1vWv'
  });
}
