{Clone} = require '../knapsack'
{randomBinArray, selectRandom, popRandom} = require './utils'


allCombinations = (population, opts) ->
  newIndividuals = []
  for a, i in population
    for b in population[i+1..]
      newIndividuals.push opts.cross a, b, opts
  return newIndividuals


random = (count) -> (population, opts) ->
  [0...count].map ->
    a = selectRandom(population)
    b = selectRandom(population)
    opts.cross a, b, opts


randomPairs = (repeat) -> (population, opts) ->
  results = [0...repeat].map ->
    p = [].concat population
    [0...population.length/2].map ->
      opts.cross popRandom(p), popRandom(p), opts
  [].concat results...


mixin = (func) ->
  (population, opts) -> [].concat population, func(population, opts)


argsMixin = (func) -> (args...) ->
  (population, opts) -> [].concat population, func(args...)(population, opts)


Crossover =

  # population crossover
  # expecting opts.cross to be individual corssover function

  allCombinationsReplace: allCombinations

  allCombinationsMixin: mixin allCombinations

  randomReplace: random

  randomMixin: argsMixin random

  randomPairsReplace: randomPairs

  randomPairsMixin: argsMixin randomPairs


  # individual crossover
  # (for binary-array type individuals)

  uniform: (a, b) ->
    randomBinArray(a.length).map (x, i) -> if x then a[i] else b[i]


module.exports = Crossover
