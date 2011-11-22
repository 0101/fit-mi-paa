{extend} = require 'underscore'
{setDebug, sum, print} = require '../common'
{ifn, sfn, Clone, EmptySack} = require '../knapsack'
task1HeuristicSolve = require('../task1').heuristicSolve


heuristicSolve = ({items, maxWeight}) ->
  # add step count to heursitic solver -- which is alwas the number of items
  extend task1HeuristicSolve({items, maxWeight}), steps: items.length


countSteps = (func) ->
  counter = 0
  (args...) -> extend func(args...), steps: counter += 1


getCountedSolve = ->
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
  solve = countSteps solve
  return solve


solveCutWeight = ({items, maxWeight}) ->
  # Same thing as task1.bruteForceSolve

  cutByWeight = (sack) -> sack.weight <= maxWeight

  getCountedSolve() EmptySack(size: items.length), items, cutByWeight


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

  getCountedSolve() EmptySack(size: items.length), items, cutByWeightAndValue


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

    bestSack = cache countSteps(bestSack), getKey

    bestSack args...


solveDP = FPTAS 0
solveAPX = FPTAS 3


module.exports = {solveBB, solveBBSort, solveCutWeight, solveDP, solveAPX,
  heuristicSolve}

