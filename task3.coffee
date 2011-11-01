{setDebug, sum, print} = require './common'
knap = require './knapsack'
{ifn, sfn, Clone} = knap


solve = (sack, remainingItems, condition) ->
  # Knapsack solver template

  solution: null

  for [weight, value, origIndex], index in remainingItems
    newSack = Clone.sack sack
    newSack.weight += weight
    newSack.value += value
    newSack.solution[origIndex] = 1

    newRemItems = Clone.array2D remainingItems
    # cut off all items before this one (!)
    newRemItems.splice 0, index + 1

    if condition newSack, remainingItems
      newSolution = solve newSack, newRemItems, condition
      if newSolution.value > (solution?.value or -Infinity)
        solution = newSolution

  return solution or sack


EmptySack = ({size}) -> weight: 0, value: 0, solution: (0 for x in [0...size])


solveCutWeight = ({items, maxWeight}) ->
  # Same thing as task1.bruteForceSolve

  cutByWeight = (sack) -> sack.weight <= maxWeight

  solve EmptySack(size: items.length), items, cutByWeight


solveBB = ({items, maxWeight}) ->
  # Branch & Bound

  bestValue = 0

  cutByWeightAndValue = (sack, remaining) ->

    if sack.weight > maxWeight
      return false

    if sack.value > bestValue
      bestValue = sack.value
      return true

    remainingValue = sum (value for [weight, value, index] in remaining)
    return (sack.value + remainingValue) > bestValue

  solve EmptySack(size: items.length), items, cutByWeightAndValue


solveBBSort = ({items, maxWeight}) ->
  # Branch & Bound on sorted items
  ratio = ([weight, value, index]) -> weight / value
  items.sort (a, b) -> ratio(a) - ratio(b)
  solveBB {items, maxWeight}


cache = (func, getKey) ->
  # Cache `func` result by key computed by `getKey` function from arguments
  map = {}
  (args...) ->
    key = getKey args...
    map[key] or map[key] = func args...


FPTAS = (b) ->
  # FPTAS solver with precision reduced by `b` bits

  getKey = ({items, maxWeight}) -> [items.length, maxWeight >> b << b]

  solveDP = (args...) ->
    # Dynamic-programming-based solver

    bestSack = ({items, maxWeight}) ->
      if maxWeight < 0 then return false
      if maxWeight is 0 then return EmptySack size: items.length
      if items.length is 0 then return EmptySack size: 0

      [weight, value, index] = items[0]

      sack1 = bestSack items: items[1..], maxWeight: maxWeight
      sack2 = bestSack items: items[1..], maxWeight: maxWeight - weight

      if sack2 and (sack2.value + value) > sack1.value
        solution: [1].concat(sack2.solution), value: (sack2.value + value)
      else
        solution: [0].concat(sack1.solution), value: sack1.value

    bestSack = cache bestSack, getKey

    bestSack args...


TestRunner = (func, name) ->
  (n, limit=0) ->
    print "\n\n#{name} for #{limit or 'all'} instance(s) of length #{n}"
    knap.testSolver ifn(n), sfn(n), func, limit


FPTASRunner = (n, b) ->
  print "\n\nFPTAS-#{b} average relative error for all instance(s) of length #{n}"
  knap.measureAvgError ifn(n), sfn(n), FPTAS(b), print


argMap =
  w: TestRunner solveCutWeight, "Cut-by-weight"
  bb: TestRunner solveBB, "Branch & Bound"
  bbs: TestRunner solveBBSort, "B&B + Sort"
  dp: TestRunner FPTAS(0), "Dynamic Programming"
  fptas: FPTASRunner

if process.argv.length < 3
  print "Usage: #{process.argv.join ' '} <#{(x for x of argMap).join '|'}> [limit|FPTAS precision]"

else
  argMap[process.argv[2]] process.argv[3..]...
