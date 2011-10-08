# Bucket problem

{print, readTextFile, parseNubmers, sum, equalNumbers} = require './common'


loadInstances = (filename, callback) ->
  readTextFile filename, (lines) ->
    instances = for line in lines
      [id, n, data...] = parseNubmers line
      capacity = data[...n]
      initial = data[n...2*n]
      target = data[2*n...]
      {id, capacity, initial, target}

    callback instances


makeActions = (bucketCount) ->
  ### Create a set of all possible actions for given bucket count

  Returns an array of objects containing a `name` and two functions that take
  bucket-values and bucket-capacities as parameters:
    `condition`: returns whether the action can be performed
    `action`: returns new bucket-values resulting from the action
  ###

  indexes = [0...bucketCount]

  fillActions = indexes.map (i) ->
    name: "Fill #{i}"
    condition: (buckets, capacity) -> buckets[i] < capacity[i]
    action: (buckets, capacity) ->
      for bucket, index in buckets
        if index is i then capacity[i] else bucket

  emptyActions = indexes.map (i) ->
    name: "Empty #{i}"
    condition: (buckets) -> buckets[i] > 0
    action: (buckets) ->
      for bucket, index in buckets
        if index is i then 0 else bucket

  pourActions = []
  for a in indexes
    for b in indexes when a isnt b
      # for-block doesn't have scope...
      ((src, dest) -> pourActions.push
        name: "Pour #{src} to #{dest}"
        condition: (buckets, capacity) ->
          buckets[src] > 0 and buckets[dest] < capacity[dest]
        action: (buckets, capacity) ->
          amount = Math.min(buckets[src], capacity[dest] - buckets[dest])

          for bucket, index in buckets
            if index is src
              buckets[src] - amount
            else if index is dest
              buckets[dest] + amount
            else
              bucket
      )(a, b)

  [].concat fillActions, emptyActions, pourActions


solve = ({capacity, initial, target}, queue) ->
  ### Bucket solver template.

  the `queue` object must provide the following interface:
    push(object), pop() = object, isEmpty() = true/false
  ###

  initialState = buckets: initial, depth: 0, action: 'Start'
  queue.push initialState

  visited = {}

  actions = makeActions initial.length

  until queue.isEmpty()
    state = queue.pop()
    {buckets, depth} = state

    for {action, condition, name} in actions when condition buckets, capacity
      newBuckets = action buckets, capacity

      if visited[newBuckets] then continue

      visited[newBuckets] = true

      newState =
        buckets: newBuckets
        depth: depth + 1
        action: name
        previous: state

      if equalNumbers newBuckets, target
        count = (x for x of visited).length
        return solutionFound: true, state: newState, count: count

      queue.push newState

  return solutionFound: false


# Data structures

Stack = ->
  stack = []
  stack.isEmpty = -> stack.length is 0
  stack

Queue = ->
  queue = Stack()
  queue.pop = queue.shift
  queue

PriorityQueue = (getPriority) ->
  queue = Stack()
  sorted = false
  sort = ->
    queue.sort (a, b) -> a.priority - b.priority
    sorted = true

  push: (obj) ->
    priority = getPriority obj
    queue.push {obj, priority}
    sorted = false

  pop: ->
    if not sorted then sort()
    queue.pop().obj

  isEmpty: queue.isEmpty



Solvers =

  BFS: (instance) -> solve instance, Queue()

  DFS: (instance) -> solve instance, Stack()

  PQSum: (instance) ->
    # priority based on how close is sum of values to the sum of target values
    targetSum = sum instance.target
    solve instance, PriorityQueue ({buckets}) -> -(Math.abs(targetSum - sum buckets))

  PQCount: (instance) ->
    # priority based on how many of the buckets are already filled correctly
    getPriority =
    solve instance, PriorityQueue ({buckets}) ->
      sum (1 for bucket, i in buckets when bucket is instance.target[i])

  PQRand: (instance) ->
    # random priority a.k.a. I'm feeling lucky
    solve instance, PriorityQueue Math.random


runVerbose = (instance, solvers) ->
  print "\nInstance #{instance.id}\n
    buckets: #{instance.capacity}\n
    initial fill: #{instance.initial}\n
    target: #{instance.target}"

  for name, solver of solvers
    print "\nUsing #{name}"
    {solutionFound, state, count} = solver instance
    if solutionFound
      print "Solution found at depth #{state.depth}, visited #{count} states"
      printBacktrack state


runSparse = (instance, solvers) ->
  print "\nInstance #{instance.id}"
  for name, solver of solvers
    {solutionFound, state, count} = solver instance
    if solutionFound
      print "#{name}\tdepth:\t#{state.depth}\tvisited:\t#{count}"
    else
      print "#{name} Solution not found."


printBacktrack = (state) ->
  print "Backtrack:"
  while state
    print "#{state.depth}\t#{state.buckets}\t(#{state.action})"
    state = state.previous


loadInstances 'bucket/bu.inst.dat', (instances) ->
  run = if process.argv[2] is '-v' then runVerbose else runSparse
  run instance, Solvers for instance in instances

