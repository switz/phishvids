if (process.env.NODE_ENV === 'production') {
  require('./src/bootstrap').listen(process.env.PORT || 3000);
} else {
  // Follow these instructions for profiling / debugging leaks
  // * https://developers.google.com/chrome-developer-tools/docs/heap-profiling
  // * https://developers.google.com/chrome-developer-tools/docs/memory-analysis-101
  agent = require('webkit-devtools-agent');
  console.log("To debug memory leaks:" +
      "\n\t(1) Run `kill -SIGUSR2 " + process.pid + "`" +
      "\n\t(2) open http://c4milo.github.com/node-webkit-agent/21.0.1180.57/inspector.html?host=localhost:1337&page=0");
  require('derby').run(__dirname + '/src/bootstrap', 3000);
}
