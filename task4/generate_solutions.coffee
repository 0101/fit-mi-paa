{writeFile} = require 'fs'
{getFileName, getSolutionsFileName, params} = require './task4'
{loadInstances} = require '../knapsack'
{FPTAS} = require '../task3'


saveSolutions = (solutions, filename) ->
  data = ([id, solution.length, value, solution...].join ' ' \
          for {id, value, solution} in solutions).join '\n'
  writeFile filename, data, (err) ->
    console.log if err then err else "saved #{filename}"


makeSolution = (desc, value, solve) ->
  console.log "makeSolution", desc, value
  loadInstances getFileName(desc, value), 0, (instances) ->
    solutions = instances.map (instance) ->
      solution = solve instance
      solution.id = instance.id
      return solution
    saveSolutions solutions, getSolutionsFileName desc, value
    console.log ".finished", desc, value


makeAllSolutions = (solve) ->
  params.map ([sw, desc, def, choices]) ->
    choices.map (value) ->
      makeSolution desc, value, solve


solveDP = FPTAS 0

makeAllSolutions solveDP
