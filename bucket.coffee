# Bucket problem 

{debug, setDebug, print, readTextFile, parseNubmers} = require './common'

setDebug false


loadInstances = (filename, callback) ->
  readTextFile filename, (lines) ->
    instances = for line in lines
      [id, n, data...] = parseNubmers line
      capacity = data[...n]
      initial = data[n...2*n]
      target = data[2*n...]
      {id, n, capacity, initial, target}

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
      debug "-> fill #{i}"
      for bucket, index in buckets
        if index is i then capacity[i] else bucket

  emptyActions = indexes.map (i) ->
    name: "Empty #{i}"
    condition: (buckets) -> buckets[i] > 0
    action: (buckets) ->
      debug "-> empty #{i}"
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
          debug "-> pour #{src} to #{dest}"
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


equal = (array, brray) ->
  if array.length isnt brray.length then return false
  for a, index in array
    if a isnt brray[index] then return false
  true


solve = ({capacity, initial, target}, queue, name='unnamed') ->
  ### Bucket solver template.
  
  the `queue` object must provide the following interface:
    push(object), pop() = object, isEmpty() = true/false
  ###
  print "\nBuckets with #{name}\n
    buckets: #{capacity}\n
    initial fill: #{initial}\n
    target: #{target}\n"

  initialState = buckets: initial, depth: 0, action: 'Start'
  queue.push initialState

  visited = {}

  actions = makeActions initial.length
  
  until queue.isEmpty()
    state = queue.pop()
    {buckets, depth} = state

    debug '_______________________________________'
    debug 'UNSHIFTED: ', buckets
    
    for {action, condition, name} in actions when condition buckets, capacity
      newBuckets = action buckets, capacity
      debug newBuckets
      if visited[newBuckets]
        debug '\tvisited\n'
        continue
      debug 'NEW\n'
      visited[newBuckets] = true
      
      newState =
        buckets: newBuckets
        depth: depth + 1
        action: name
        previous: state

      if equal newBuckets, target
        count = (x for x of visited).length
        print "Solution found at depth #{depth + 1}, visited #{count} states"
        print "Backtrack:"
        s = newState
        while s
          print "#{s.depth}\t#{s.buckets}\t(#{s.action})"
          s = s.previous
        return true

      queue.push newState


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


solveBFS = (instance) -> solve instance, Queue(), 'BFS'
solveDFS = (instance) -> solve instance, Stack(), 'DFS'


solvePQSum = (instance) ->
  sum = (x) -> x.reduce (a,b) -> a+b
  targetSum = sum instance.target
  getPriority = (state) -> -(Math.abs(targetSum - sum state.buckets))
  solve instance, PriorityQueue(getPriority), 'PQ-Sum'

solvePQRandom = (instance) ->
  solve instance, PriorityQueue(Math.random), 'PQ-Random'


testingInstance = capacity: [4,3], initial: [0,0], target: [2,0]

solveBFS testingInstance
solveDFS testingInstance
solvePQSum testingInstance
solvePQRandom testingInstance

#loadInstances 'bucket/bu.inst.dat', (instances) ->
#  solveBFS instances[0]
#  solveDFS instances[0]

