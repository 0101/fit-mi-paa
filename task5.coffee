_ = require 'underscore'
{sum, print, funcComp, setDebug, allEqual} = require './common'
knap = require './knapsack'
{ifn, sfn, relativeError, loadInstances, loadSolutions} = knap
{BinaryGASolver} = require './ga/solver'
{randomBinArray} = require './ga/utils'
Selection = require './ga/selection'
Crossover = require './ga/crossover'


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

      selection: Selection.first 40

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
  {value, stats} = solver instance
  callback
    label: label
    error: relativeError value, optimal.value
    history: stats.history.map (v) -> relativeError v, optimal.value

printMeasurements = ({label, history}) ->
  print "#{label}:\t#{history.join '\t'}".replace /\./g, ','


loadTestingInstances = (n, callback) ->
  loadSolutions sfn(n), (solutions) ->
    loadInstances ifn(n), 0, (instances) ->
      callback instances, solutions


if process.argv.length > 2
  instanceIndex = process.argv[2]
  loadTestingInstances 40, (instances, solutions) ->
    instance = instances[instanceIndex]
    solution = solutions[instance.id]
    measure("Default, instance #{instanceIndex}", KnapsackGASolver(
      crossover: Crossover.randomPairsReplace 30
      selection: Selection.first 30
      maxCycles: 100
    ), instance, solution, printMeasurements)



