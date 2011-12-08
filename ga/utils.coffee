
Utils =

  randomInteger: (from, to) -> Math.floor Math.random() * (to - from) + from

  randomBinArray: (length) -> [0...length].map -> Utils.randomInteger 0, 2

  selectRandom: (array) -> array[Utils.randomInteger 0, array.length]

  popRandom: (array) -> (array.splice Utils.randomInteger(0, array.length), 1)[0]

  invert: (x) -> if x is 0 then 1 else 0


module.exports = Utils
