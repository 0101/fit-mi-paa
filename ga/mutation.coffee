{Clone} = require '../knapsack'
{randomInteger, invert, popRandom} = require './utils'
{min, funcComp} = require '../common'


Mutation =

  # Apply opts.mutate on a random individual; repeat `count` times
  random: (count) -> (population, opts) ->
    population = population.sort funcComp (i) -> -opts.fitness i, opts
    eCount = opts.eliteCount or 0
    elites = population[...eCount]
    p = Clone.array2D population[...eCount]
    [0...count].map ->
      chosen = randomInteger 0, population.length
      p = p.map (individual, index) ->
        if index is chosen then opts.mutate individual else individual
    return [].concat elites, p

  randomClones: (count) -> (population, opts) ->
    p = Clone.array2D population
    [0...count].map ->
      chosen = randomInteger 0, population.length
      p.push opts.mutate p[chosen]
    return p

  # Mutate a binary-array type individual by flipping `count` random bits.
  invertBits: (count) -> (individual, opts) ->
    selected = [1..count].map -> randomInteger 0, individual.length
    individual.map (x, index) -> if index in selected then invert x else x

  invertRandomCountOfBits: (from, to) -> (individual, opts) ->
    indexes = [0...individual.length]
    count = min([randomInteger(from, to), indexes.length])
    selected = [1..count].map -> popRandom indexes
    individual.map (x, index) -> if index in selected then invert x else x



module.exports = Mutation
