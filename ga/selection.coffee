{funcComp, min} = require '../common'
{popRandom} = require './utils'


preserveElite = (selection) ->
  (population, opts) ->
    sortedPop = [].concat population.sort(funcComp (i) -> -opts.fitness(i, opts))
    elites = sortedPop.splice 0, opts.eliteCount or 0
    [].concat elites, selection sortedPop, opts


Selection =

  first: (count) -> (population, opts) ->
    population.sort(funcComp ((i) -> opts.fitness(i, opts)), true)[...count]

  tournament: (getTournamentSize, targetPopulationSize) ->
    preserveElite (population, opts) ->
      tournamentSize = getTournamentSize opts
      [1..min([targetPopulationSize, population.length])].map ->
        indexes = [0...population.length]
        contestants = [1..min([tournamentSize, indexes.length])].map -> popRandom indexes
        winner = contestants.sort(funcComp (i) -> -opts.fitness(population[i], opts))[0]
        population.splice(winner, 1)[0]

  random: (count) -> preserveElite (population, opts) ->
    [1..min([count, population.length])].map -> popRandom population


module.exports = Selection
