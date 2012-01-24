_ = require 'underscore'
{sum, print, funcComp, setDebug, allEqual, max} = require '../common'
{BinaryGASolver} = require '../ga/solver'
{randomBinArray} = require '../ga/utils'
Selection = require '../ga/selection'
Crossover = require '../ga/crossover'
Mutation = require '../ga/mutation'


satisfied = (clauses, mapping) ->
  # returns [ all satisfied: Boolean, sat. clauses: Number ]
  satClauses = clauses.filter (clause) ->
    clause.some ([neg, index]) ->
      neg ^ mapping[index - 1]
  return [satClauses.length is clauses.length, satClauses.length]


printInstance = ({clauses, weights}) ->
  console.log clauses.map((clause) ->
    "(#{clause.map(([neg, index]) -> "#{if neg then '!' else ''}#{index}").join ' + '})"
  ).join ' * '
  console.log 'weights:', (weights.map (w, index) -> "#{index + 1}: #{w}")


SatGASolver = (options) ->

  ({varCount, clauseCount, clauses, weights}) ->

    weight = (mapping) -> sum weights.filter (w, index) -> mapping[index]

    stats = cycles: 0, history: []

    defaults =
      initialPopulationSize: 500

      getInitialPopulation: (opts) ->
        [1..opts.initialPopulationSize].map -> randomBinArray varCount

      terminationCondition: (population, opts) ->
        if stats.cycles >= opts.maxCycles then return true
        if stats.cycles >= opts.quitIfNoChangeIn
          lastX = stats.history[stats.history.length - opts.quitIfNoChangeIn..]
          if allEqual lastX then return true
        return false
      maxCycles: 5000
      quitIfNoChangeIn: 15

      unsatPenalty: 1000

      fitness: _.memoize (individual, opts) ->
        [sat, satCount] = satisfied clauses, individual
        value = weight individual

        fit = value * satCount

        if not sat
          fit /= opts.unsatPenalty

        return fit

      cycleFinished: (population, opts) ->
        stats.cycles += 1
        best = population.sort(funcComp (i) -> -opts.fitness(i, opts))[0]
        [sat, satCount] = satisfied clauses, best
        entry =
          sat: sat
          satCount: satCount
          fitness: opts.fitness best, opts
          weight: weight best
        stats.history.push entry

      processResults: (population, opts) ->
        _.extend stats.history[stats.history.length - 1], stats: stats

      mutation: Mutation.randomClones 100

      mutate: Mutation.invertBits varCount / 3

      crossover: Crossover.randomPairsMixin 2

      selection: Selection.first 40

    BinaryGASolver _.extend defaults, options


module.exports = {SatGASolver}


EvolvedSolver = SatGASolver
  quitIfNoChangeIn: 372
  unsatPenalty: 4655
  mutation: Mutation.randomClones 68
  mutate: Mutation.invertRandomCountOfBits 0, 33
  crossover: Crossover.randomMixin 20
  selection: Selection.random 50
  eliteCount: 4


instanceFilename = process.argv[2]
instance = require "./#{instanceFilename}"
{stats}= EvolvedSolver instance

last = null
print 'generation\tsat\tsatCount\tweight\tfitness'
for {              sat, satCount, weight, fitness}, index in stats.history
  x = [            sat, satCount, weight, fitness].join '\t'
  x = x.replace '\.', ','
  if x is last then continue
  last = x
  print "#{index}\t#{x}"
print "#{index}\t#{x}"
