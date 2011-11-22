{writeFile} = require 'fs'
{exec} = require 'child_process'

{settings, params, getFileName} = require './task4'


# generate all tasks for the generator for each choice for each parameter
# while other parameters are at their default values
generatorTasks = (params.map (param) ->
  other = (p for p in params when p isnt param)
  defaults = other.map ([sw, desc, def]) -> "#{sw} #{def}"
  base = "#{settings.GENERATOR} #{defaults.join ' '}"
  [sw, desc, def, choices] = param
  choices.map (value) ->
    filename: getFileName desc, value
    cmd: [base, sw, value].join ' '
).reduce (a, b) -> a.concat b


# run all tasks and write results to files
generatorTasks.map ({filename, cmd}) ->
  exec cmd, (err, stdout) ->
    if err
      console.log cmd, err
    else
      writeFile filename, stdout, (err) -> if err then console.log err


