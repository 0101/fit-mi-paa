{funcComp} = require '../common'


Selection =

  first: (count) -> (population, opts) ->
    population.sort(funcComp ((i) -> opts.fitness(i, opts)), true)[...count]


module.exports = Selection
