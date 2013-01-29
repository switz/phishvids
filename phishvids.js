if (process.env.NODE_ENV === 'production') {
  require('./src/bootstrap').listen(process.env.PORT || 3000);
} else {
  require('derby').run(__dirname + '/src/bootstrap', 3000);
}
