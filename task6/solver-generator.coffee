fs = require 'fs'
_ = require 'underscore'

{print, mergeArrays, sum, averageInteger, dict} = require '../common'
{GASolver} = require '../ga/solver'
{selectRandom, randomInteger} = require '../ga/utils'
{SatGASolver} = require './solver'
Selection = require '../ga/selection'
Crossover = require '../ga/crossover'
Mutation = require '../ga/mutation'


outputFile = 'configurations.txt'
resultsFile = 'results.txt'


testInstances = ([name, require "./instances/#{name}.json"] for name in [
  '20-2', '20-3', '20-5'
  '35-2', '35-3', '35-4'
  '50-1', '50-2'
  '75-1', '75-2'
  '100-1',
])


# clear files
fs.writeFileSync outputFile, ''
instanceNames = (name for [name, instance] in testInstances)
statNames = ['sat', 'satCount', 'weight', 'cycles']
# results csv header
fs.writeFileSync resultsFile, _.flatten(['generation'].concat (
  ("#{i} #{s}" for s in statNames) for i in instanceNames)).join('\t') + '\n'


appendToFile = (filename, content) ->
  file = fs.openSync filename, 'a'
  fs.writeSync file, content
  fs.closeSync file


saveConfiguration = (generation, configuration, filename=outputFile) ->
  content = "#{generation}. generation best conf.:\n#{confToString configuration}\n\n"
  appendToFile filename, content


saveResults = (generation, configuration, filename=resultsFile) ->
  results = configuration._results
  appendToFile filename, _.flatten([generation].concat (
    (results[i][s] for s in statNames) for i in instanceNames)).join('\t') + '\n'


solverParams =
  # each value is an array of arrays: [the actual value, description]
  # so we'll be able to reconstruct the configuration
  # (since some of the values will be functions)

  quitIfNoChangeIn: ([x, x] for x in [50..500])

  unsatPenalty: ([x, x] for x in [10..10000])

  mutation: mergeArrays [
    ([Mutation.random(x), "random #{x}"] for x in [0..100])
    ([Mutation.randomClones(x), "randomClones #{x}"] for x in [0..100])
  ]

  mutate: ([Mutation.invertRandomCountOfBits(0, x), "invertRandomCountOfBits 0, #{x}"]\
    for x in [20..100])

  crossover: mergeArrays [
    ([Crossover.randomReplace(x), "randomReplace #{x}"] for x in [20..120] by 20)
    ([Crossover.randomMixin(x), "randomMixin #{x}"] for x in [0..100] by 20)
    ([Crossover.randomPairsReplace(x), "randomPairsReplace #{x}"] for x in [2..6])
    ([Crossover.randomPairsMixin(x), "randomPairsMixin #{x}"] for x in [1..5])
  ]

  selection: mergeArrays [
    ([Selection.first(x), "first #{x}"] for x in [10..110] by 10)
    ([Selection.tournament((->tsize), count), "tournament #{tsize}, #{count}"]\
      for [tsize, count] in mergeArrays ([ts, c] for ts in [2..5] for c in [20..120] by 20))
    ([Selection.random(x), "random #{x}"] for x in [10..110] by 10)
  ]

  eliteCount: ([x, x] for x in [2..10] by 2)

solverParamNames = (name for name of solverParams)


randomConfiguration = ->
  dict(for param, values of solverParams
    [param, randomInteger 0, values.length])


Solver = (configuration) ->
  # Create SAT solver from configuration
  confValues = dict(for param, index of configuration
    [value, desc] = solverParams[param][index]
    [param, value])
  SatGASolver confValues


confToString = (configuration) ->
  lines = for param, index of configuration when param[0] isnt '_'
    [value, desc] = solverParams[param][index]
    "\t#{param}: #{desc}"
  lines.join '\n'


printConfiguration = (configuration) -> print confToString configuration



SatSolverGenerator = (testInstances) ->

  stats = cycles: 0

  GASolver
    initialPopulationSize: 5

    getInitialPopulation: (opts) ->
      [1..opts.initialPopulationSize].map -> randomConfiguration()

    terminationCondition: (population, opts) -> stats.cycles >= opts.maxCycles

    maxCycles: 1000

    fitness: (configuration, opts) ->

      if configuration._fitnessCache?
        return configuration._fitnessCache

      print "Computing fitness for"
      printConfiguration configuration

      results = dict(for [name, instance] in testInstances
        {sat, satCount, weight, stats:{cycles}} = Solver(configuration)(instance)
        [name, {sat, satCount, weight, cycles}])

      satSum = satRatiosSum = weightRatiosSum = cyclesSum = 0

      for name, {sat, satCount, weight, cycles} of results
        satSum += sat
        satRatiosSum += satCount / instance.clauses.length
        weightRatiosSum += weight / sum instance.weights
        cyclesSum += cycles

      fitness = (satRatiosSum + weightRatiosSum * .1) * (satSum + .1) #- cycles / 1000000

      print "_______________"
      print "satSum: #{satSum}, satRatiosSum: #{satRatiosSum}, weightRatiosSum: #{weightRatiosSum}, cycles: #{cyclesSum}"
      print "fitness: #{fitness}\n"

      configuration._results = results
      return configuration._fitnessCache = fitness

    selection: Selection.tournament (->3), 5

    eliteCount: 2

    cycleFinished: (population, opts) ->
      stats.cycles += 1
      best = opts.processResults population, opts
      saveConfiguration stats.cycles, best
      saveResults stats.cycles, best

      print "__________________________________________________________________"
      print "\n#{stats.cycles}. generation finished."
      print "best configuration:"
      printConfiguration best
      print "fitness: #{opts.fitness best}"
      print "__________________________________________________________________"
      for conf in population
        print opts.fitness conf


    mutation: (population, opts) ->
      probOfMutation = .4
      newPopulation = [].concat population
      for individual in population
        if Math.random() < probOfMutation
          newPopulation.push opts.mutate individual, opts
      return newPopulation

    mutate: (configuration, opts) ->
      param = selectRandom solverParamNames
      randomValue = randomInteger 0, solverParams[param].length
      mutated = dict(for name, value of configuration when name[0] isnt '_'
        if name is param
          [name, averageInteger [configuration[param], randomValue]]
        else
          [name, value])

    crossover: Crossover.randomPairsMixin 1

    cross: (a, b, opts) ->
      dict(for param of solverParams
        [param, switch randomInteger 0, 3
          when 0 then a[param]
          when 1 then b[param]
          when 2 then averageInteger [a[param], b[param]]])


result = SatSolverGenerator testInstances

print 'Done, result:'
printConfiguration result
