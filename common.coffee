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


sum = (array) -> array.reduce ((a, b) -> a + b), 0


average = (array) -> sum(array) / array.length


max = (array) -> Math.max array...


allEqual = (array) -> array.reduce ((a, b) -> a and b is array[0]), true


equalNumbers = (array, brray) ->
  if array.length isnt brray.length then return false
  for a, index in array
    if a isnt brray[index] then return false
  true


funcComp = (func, reverse=false) ->
  coef = if reverse then -1 else 1
  (a, b) -> coef * (func(a) - func(b))


module.exports = {print, debug, setDebug, readTextFile, parseNubmers,
  sum, average, max, equalNumbers, funcComp, allEqual}
