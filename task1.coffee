knap = require './knapsack'
{ifn, sfn, Clone} = knap

profiler = require 'v8-profiler'


heuristicSolve = ({items, maxWeight}) ->

  ratio = ([weight, value, index]) -> weight / value

  items.sort (a, b) -> ratio(a) - ratio(b)

  solution = (0 for x in [0...items.length])
  totalWeight = 0
  totalValue = 0

  for [weight, value, index] in items
    if totalWeight + weight <= maxWeight
      totalWeight += weight
      totalValue += value
      solution[index] = 1

  value: totalValue
  solution: solution


bruteForceSolve = ({items, maxWeight}) ->

  bestOf = (sacks) -> (sacks.sort (a, b) -> b.value - a.value)[0]

  bestSack = (sack, remainingItems) ->
    sacks = for [weight, value, origIndex], index in remainingItems \
      when sack.weight + weight <= maxWeight
        newSack = Clone.sack sack
        newSack.weight += weight
        newSack.value += value
        newSack.solution[origIndex] = 1

        newRemItems = Clone.array2D remainingItems
        # cut off all items before this one (!)
        newRemItems.splice 0, index + 1

        bestSack newSack, newRemItems

    if sacks.length is 0 then sack else bestOf sacks

  emptySack = weight: 0, value: 0, solution: (0 for x in [0...items.length])

  bestSack emptySack, items



run =

  heuristic: (callback) ->
    remaining = knap.availableCounts.length
    knap.availableCounts.map (n) ->
      knap.measureError ifn(n), sfn(n), heuristicSolve, (avgError) ->
        console.log "n: #{n}\taverage relative error: #{avgError}"
        remaining -= 1
        if remaining is 0 then callback?()


  bruteforce: (n, limit=0, repeat=1, callback) ->
    for x in [1..repeat]
      knap.testSolver ifn(n), sfn(n), bruteForceSolve, limit, ->
        repeat -= 1
        if repeat < 1 then callback?()


knap.debug false


profiler.startProfiling 'heuristic'
run.heuristic ->
  p = profiler.stopProfiling 'heuristic'


[4].map (n) ->
  label = "bruteforce-#{n}"
  profiler.startProfiling label
  run.bruteforce n, 0, 1, ->
    p = profiler.stopProfiling label
    console.log "bruteforce #{n} done."


# wait for termination
wait = -> setInterval wait, 9000
wait()

