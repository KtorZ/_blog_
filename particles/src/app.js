'use strict'

require('./index.html')
require('./main.css')
var Elm = require('./Main.elm')
Elm.embed(Elm.Main, document.getElementById('main'))
