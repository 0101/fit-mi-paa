### Knapsack utility funcitons

Data structures / interfaces:

Instances are objects with the following properties:
 id: id of the instance
 maxWeight: knapsack weight limit
 items: array of items where each item is an array of [weight, value, index]

Solutions are objects with properties:
  value: sum of values in the knapsack
  solution: array of 1s and 0s marking which items are in the knapsack

Solve functions should accept an instance and return a solution as described above.
###

{debug, print, readTextFile, parseNubmers, average, max} = require './common'


loadSolutions = (filename, callback) ->
  solutions = {}

  readTextFile filename, (lines) ->
    for line in lines
      [id, n, value, solution...] = parseNubmers line
      solutions[id] = {value, solution}

    callback solutions


loadInstances = (filename, limit=0, callback) ->
  readTextFile filename, (lines) ->
    if limit then lines = lines[0...limit]
    instances = for line in lines
      [id, n, maxWeight, data...] = parseNubmers line

      # zip weights and values together
      items = (data[x*2..x*2+1] for x in [0...data.length/2])

      # add indexes
      item.push(index) for item, index in items

      {id, maxWeight, items}

    callback instances


testSetWrapper = (instancesFile, solutionsFile, test, limit=0, callback) ->
  ###  Run given `test` function for all instances in `instancesFile`.

  The function also gets a second parameter, which is the correct solution
  for the instance according to `solutionsFile`.
  ###
  loadSolutions solutionsFile, (solutions) ->
    loadInstances instancesFile, limit, (instances) ->
      results = (test i, solutions[i.id] for i in instances)
      callback? results


testSolver = (instancesFile, solutionsFile, solve, limit=0, callback) ->
  # Test if `solve` function solves all instances in `instancesFile`
  # correctly according to solutions from `solutionsFile`

  failed = warn = ok = 0

  test = (instance, correct) ->
    {value, solution} = solve instance

    if value isnt correct.value
      debug "Test Failed", {instance, value, solution, correct}
      debug instance.items
      failed += 1
      return

    for n, i in solution
      if n isnt correct.solution[i]
        debug "Warning", {instance, value, solution, correct}
        warn += 1
        return

    ok += 1
    debug instance.id, 'OK'

  testSetWrapper instancesFile, solutionsFile, test, limit, ->
    print "correct: #{ok}, warning: #{warn}, failed: #{failed}"
    callback?()


measureError = (instancesFile, solutionsFile, solve, callback, aggregate) ->
  # Measure relative error of `solve` function values for instances
  # in `instancesFile` compared to values in `solutionsFile`.
  # Aggregate results using `aggregate` function.
  test = (instance, correct) ->
    {value} = solve instance
    debug value, correct.value
    Math.abs(correct.value - value) / Math.max(value, correct.value)

  testSetWrapper instancesFile, solutionsFile, test, 0, (results) ->
    callback aggregate results

measureAvgError = (args...) -> measureError args..., average
measureMaxError = (args...) -> measureError args..., max


Clone =
  # deep-copy utility functions
  array: (array) -> array.slice 0
  array2D: (array) -> (Clone.array a for a in array)
  sack: ({value, weight, solution}) ->
    value: value
    weight: weight
    solution: Clone.array solution


module.exports =
  loadInstances: loadInstances
  testSolver: testSolver
  measureAvgError: measureAvgError
  measureMaxError: measureMaxError
  Clone: Clone

  availableCounts: [4,10,15,20,22,25,27,30,32,35,37,40]
  # instances filename
  ifn: (n) -> "knap/knap_#{n}.inst.dat"
  # solutions filename
  sfn: (n) -> "knap/knap_#{n}.sol.dat"

