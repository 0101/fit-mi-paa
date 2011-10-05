# Common PAA utils

fs = require 'fs'


DEBUG = false
setDebug = (x) -> DEBUG = x

print = (args...) -> console.log args...
debug = (args...) -> console.log args... if DEBUG


readTextFile = (filename, callback) ->
  fs.readFile filename, 'utf-8', (err, data) ->
    if err then throw err
    callback (line for line in data.split '\n' when line.trim())


parseNubmers = (text) -> (parseInt x for x in text.split /\s+/)


module.exports = {print, debug, setDebug, readTextFile, parseNubmers}
