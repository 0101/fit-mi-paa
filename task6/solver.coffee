_ = require 'underscore'
{sum, print, funcComp, setDebug, allEqual, max} = require '../common'
{BinaryGASolver} = require '../ga/solver'
{randomBinArray} = require '../ga/utils'
Selection = require '../ga/selection'
Crossover = require '../ga/crossover'
Mutation = require '../ga/mutation'


satisfied = (clauses, mapping) ->
  clauses.every (clause) ->
    clause.some ([neg, index]) -> neg ^ mapping[index - 1]


printInstance = ({clauses, weights}) ->
  console.log clauses.map((clause) ->
    "(#{clause.map(([neg, index]) -> "#{if neg then '!' else ''}#{index}").join ' + '})"
  ).join ' * '
  console.log 'weights:', (weights.map (w, index) -> "#{index + 1}: #{w}")


SatGASolver = (options) ->

  ({varCount, clauseCount, clauses, weights}) ->

    weight = (mapping) ->
      sum weights.filter (w, index) -> mapping[index]

    stats = cycles: 0, history: []

    defaults =
      initialPopulationSize: 40

      getInitialPopulation: (opts) ->
        [1..opts.initialPopulationSize].map -> randomBinArray varCount

      terminationCondition: (population, opts) ->
        if stats.cycles >= opts.maxCycles then return true
        if stats.cycles >= opts.quitIfNoChangeIn
          lastX = stats.history[stats.history.length - opts.quitIfNoChangeIn..]
          if allEqual lastX then return true
        return false
      maxCycles: 100
      quitIfNoChangeIn: 5

      notSolutionPenalty: varCount * max weights

      fitness: (individual, opts) ->
        f = weight individual

        if not satisfied clauses, individual
          f -= opts.notSolutionPenalty

        return f

      cycleFinished: (population, opts) ->
        stats.cycles += 1
        best = population.sort(funcComp (i) -> -opts.fitness(i, opts))[0]
        stats.history.push weight best

      processResults: (population, opts) ->
        solution = BinaryGASolver.defaults.processResults population, opts
        return solution: solution, weight: weight(solution), stats: stats

    BinaryGASolver _.extend defaults, options


instanceFilename = process.argv[2]
instance = require "./#{instanceFilename}"
#printInstance instance
console.log SatGASolver()(instance).stats

