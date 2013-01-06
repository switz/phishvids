var customRenderFunction = function(document_type, item) {
  var out = '<p class="title">' + item['title'] + '</p>';
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

window.onerror = function(message, file, line) {
  return _gaq.push(['_trackEvent', 'error', "(window) " + message + " [" + file + " (" + line + ")]"]);
};

$(document).ajaxError(function(event, xhr, ajaxOptions, thrownError) {
  var responseText;
  if ((xhr != null ? xhr.status : void 0) === 404) {
    return;
  }
  responseText = $.parseJSON(xhr.responseText);
  if (responseText) {
    _gaq.push(['_trackEvent', 'error', "(ajax " + xhr.status + ") " + thrownError + " " + responseText.message + " [" + ajaxOptions.url + "]"]);
  }
});
