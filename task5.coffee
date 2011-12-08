_ = require 'underscore'
{sum, print, funcComp, setDebug, allEqual} = require './common'
knap = require './knapsack'
{ifn, sfn, relativeError, loadInstances, loadSolutions} = knap
{BinaryGASolver} = require './ga/solver'
{randomBinArray} = require './ga/utils'
Selection = require './ga/selection'
Crossover = require './ga/crossover'
Mutation = require './ga/mutation'


selected = (items, mapping) ->
  items.filter ([weight, value, index]) -> mapping[index]

weight = (items, mapping) ->
  sum selected(items, mapping).map ([weight, value, index]) -> weight

value = (items, mapping) ->
  sum selected(items, mapping).map ([weight, value, index]) -> value


KnapsackGASolver = (options) ->

  ({maxWeight, items}) ->

    size = items.length

    stats = cycles: 0, history: []

    defaults =
      initialPopulationSize: 40

      getInitialPopulation: (opts) ->
        [1..opts.initialPopulationSize].map -> randomBinArray size

      terminationCondition: (population, opts) ->
        if stats.cycles >= opts.maxCycles then return true
        if stats.cycles >= opts.quitIfNoChangeIn
          lastX = stats.history[stats.history.length - opts.quitIfNoChangeIn..]
          if allEqual lastX then return true
        return false
      maxCycles: 100
      quitIfNoChangeIn: 5

      notSolutionPenalty: Infinity

      fitness: (individual, opts) ->
        f = value(items, individual)
        if weight(items, individual) > maxWeight
          f -= opts.notSolutionPenalty
        return f

      cycleFinished: (population, opts) ->
        stats.cycles += 1
        best = population.sort(funcComp (i) -> -opts.fitness(i, opts))[0]
        stats.history.push value(items, best)

      processResults: (population, opts) ->
        solution = BinaryGASolver.defaults.processResults population, opts
        return solution: solution, value: value(items, solution), stats: stats

    BinaryGASolver _.extend defaults, options


setDebug true


measure = (label, solver, instance, optimal, callback) ->
  solution = solver instance
  callback
    label: label
    error: relativeError solution.value, optimal.value
    history: solution.stats.history.map (v) -> relativeError v, optimal.value

repeatedMeasure = (times, label, args...) ->
  measure("(#{i}) #{label}", args...) for i in [1..times]


printMeasurements = ({label, history}) ->
  print "#{label}:\t#{history.join '\t'}".replace /\./g, ','


loadTestingInstances = (n, callback) ->
  loadSolutions sfn(n), (solutions) ->
    loadInstances ifn(n), 0, (instances) ->
      callback instances, solutions


solvers =
  allCombinations: -> KnapsackGASolver
    selection: Selection.first 30
    crossover: Crossover.allCombinationsMixin

  randomMixin: -> KnapsackGASolver
    selection: Selection.first 50
    crossover: Crossover.randomMixin 250

  randomPairsReplace: -> KnapsackGASolver
    selection: Selection.first 50
    crossover: Crossover.randomPairsReplace 20

  heavyMutation: -> KnapsackGASolver
    selection: Selection.first 50
    crossover: Crossover.randomReplace 200
    mutation: Mutation.random 100
    mutate: Mutation.invertBits 10



if process.argv.length > 2
  solverId = process.argv[2]
  solver = solvers[solverId]
  instanceIndex = process.argv[3]
  loadTestingInstances 40, (instances, solutions) ->
    instance = instances[instanceIndex]
    solution = solutions[instance.id]
    repeatedMeasure(5, "#{solverId}, instance #{instanceIndex}",
      solver(), instance, solution, printMeasurements)



