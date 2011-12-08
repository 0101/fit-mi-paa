{Clone} = require '../knapsack'
{randomInteger, invert} = require './utils'


Mutation =

  # Apply opts.mutate on a random individual; repeat `count` times
  random: (count) -> (population, opts) ->
    p = Clone.array2D population
    [0...count].map ->
      chosen = randomInteger 0, population.length
      p = p.map (individual, index) ->
        if index is chosen then opts.mutate individual else individual
    return p


  # Mutate a binary-array type individual by flipping `count` random bits.
  invertBits: (count) -> (individual, opts) ->
    alterBitAt = randomInteger 0, individual.length
    individual.map (x, index) -> if alterBitAt is index then invert x else x


module.exports = Mutation
