_ = require 'underscore'
{funcComp} = require '../common'
{randomInteger, randomBinArray, invert} = require './utils'
Selection = require './selection'
Crossover = require './crossover'
Mutation = require './mutation'


GASolver = (options) ->
  # Universal GA solver template

  opts = _.extend {}, GASolver.defaults, options

  population = opts.getInitialPopulation opts
  while not opts.terminationCondition population, opts
    for step in ['selection', 'crossover', 'mutation']
      population = opts[step] population, opts
      if population.length is 0
        throw "POPULATION VANISHED DURING #{step}"

    opts.cycleFinished population, opts
  opts.processResults population, opts

GASolver.defaults =

  getInitialPopulation: (opts) ->
    # Create initial population from `instance`

  terminationCondition: (population, opts) ->
    # Should the computation be terminated?

  fitness: (individual, opts) ->
    # Return the optimization criterion for given `individual`

  selection: (population, opts) ->
    # Return new population after selection

  crossover: (population, opts) ->
    # Return new population after crossover

  mutation: (population, opts) ->
    # Return new population after mutation

  mutate: (individual, opts) ->
    # Return mutated individual

  cycleFinished: (population, opts) ->
    # Called when a generation cycle is finished

  processResults: (population, opts) ->
    # This will be returned from the solver
    population.sort(funcComp ((i) -> opts.fitness(i, opts)), true)[0]


BinaryGASolver = (options) ->
  # Default implementation of crossover and mutation
  # for binary-array type individuals
  GASolver _.extend {}, BinaryGASolver.defaults, options

BinaryGASolver.defaults = _.extend {}, GASolver.defaults,

  selection: Selection.first 30

  crossover: Crossover.allCombinationsMixin

  cross: Crossover.uniform

  mutation: Mutation.random 3

  mutate: Mutation.invertBits 1


module.exports = {GASolver, BinaryGASolver}


