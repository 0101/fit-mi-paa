{writeFile} = require 'fs'
{loadInstance, testSolver, testSetWrapper, relativeError} = require '../knapsack'
solvers = require './solvers'
{average, max} = require '../common'


settings =
  GENERATOR: '../knapgen/knapgen'
  OUTPUT_DIR: 'data'
  RESULT_DIR: 'results'


params = [
  # switch, description, default, values to try
  ['-n', 'pocet-veci',        20, [5, 10, 15, 20, 25, 30, 40]]
  ['-N', 'pocet-instanci',    20, [20]]
  ['-m', 'pomer-kapacity',    .5, (x/10 for x in [1..9])]
  ['-W', 'max-vaha',         100, [30, 50, 100, 200, 350, 500]]
  ['-C', 'max-cena',         100, [20, 50, 100, 200, 350, 500]]
  ['-d', 'granularita', '0 -k 0', ("#{d} -k #{k}" for [d, k] in \
            ([-1, x] for x in [3, 2, 1.5, 1, .8, .5, .3]).concat \
            ([ 1, x] for x in [.3, .5, .8, 1, 1.5, 2, 3]))]
]

limits =
  'pocet-veci':
    solveCutWeight: 20
    solveBB: 25
    solveBBSort: 25


getTasksFor = (solverName) ->
  tasks = []
  params.map ([sw, desc, def, choices]) ->
    choices.map (value) ->
      limit = limits[desc]?[solverName]
      if limit and limit < value then return
      tasks.push [desc, value]
  return tasks


getFileName = (desc, value, type='inst') ->
  valueString = String(value).replace /\ /g, '_'
  return "#{settings.OUTPUT_DIR}/knap-#{desc}-#{valueString}.#{type}.dat"


getSolutionsFileName = (desc, value) -> getFileName desc, value, 'sol'


measure = (name, solve, callback) ->
  tasks = getTasksFor name

  results = []
  collectResults = (r) ->
    results.push r
    if results.length is tasks.length then callback results

  tasks.map ([desc, paramValue]) ->
    instFile = getFileName desc, paramValue
    solFile = getSolutionsFileName desc, paramValue

    test = (instance, correct) ->
      {value, steps} = solve instance
      error: relativeError value, correct.value
      steps: steps

    testSetWrapper instFile, solFile, test, 0, (results) ->
      console.log "collecting results from #{name} #{desc} #{paramValue}"
      collectResults {
        name: name,
        desc: desc,
        value: paramValue,
        avgError: average (error for {error} in results)
        maxError: max (error for {error} in results)
        avgSteps: average (steps for {steps} in results)
        maxSteps: max (steps for {steps} in results)
      }


saveResults = (name) -> (results) ->
  grouped = {}
  for result in results
    if not grouped[result.desc] then grouped[result.desc] = []
    grouped[result.desc].push result

  for desc, resultList of grouped
    data = (resultList.map (r) ->
      [r.value, r.avgError, r.maxError, r.avgSteps, r.maxSteps].join '\t'
    ).join '\n'
    data = data.replace /\./g, ','
    header = ['value', 'average error', 'max error', 'average steps',
      'max steps'].join '\t'
    output = "#{name} #{desc}\n#{header}\n#{data}"
    filename = "#{settings.RESULT_DIR}/#{name}-#{desc}.txt"
    writeFile filename, output, (err) ->
      if err then console.log err


run = ->
  for name, func of solvers
    measure name, func, saveResults name


module.exports = {params, getFileName, getSolutionsFileName, settings, run}
