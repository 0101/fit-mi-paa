knap = require './knapsack'
{ifn, sfn, Clone} = knap


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



runHeuristicRE = ->
  console.log "\n\nHeuristic relative error for all instances"
  knap.availableCounts.map (n) ->
    knap.measureError ifn(n), sfn(n), heuristicSolve, (avgError) ->
      console.log "n: #{n}\taverage relative error: #{avgError}"


runHeuristic = (n, repeat=1) ->
  console.log "\n\nHeuristic for n=#{n} repeated #{repeat} times"
  for x in [1..repeat]
    knap.testSolver ifn(n), sfn(n), heuristicSolve


runBruteforce = (n, limit=0) ->
  console.log "\n\nBruteforce for #{limit or 'all'} instance(s) of length #{n}"
  knap.testSolver ifn(n), sfn(n), bruteForceSolve, limit


knap.debug false

if process.argv[2] is 'h'
  if process.argv.length < 4
    runHeuristicRE()
  else
    [n, repeat] = process.argv[3..]
    runHeuristic n, repeat
else
  [n, limit] = process.argv[2..]
  runBruteforce n, limit

