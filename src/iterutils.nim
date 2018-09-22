## This module imlements operations for iterators and slices. You can see it as
## a lazy version of `sequtils`.
##
## The iterators can easily be combined, see tests/tests.nim
##
## Performance example: see tests/performance.nim

# TODO: Can we get rid of duplication by unifying the iterators and procs?

type Iterable*[T] = (iterator: T) | Slice[T]
  ## Everything that can be iterated over, iterators and slices so far.

proc toIter*[T](s: Slice[T]): iterator: T =
  ## Iterate over a slice.
  iterator it: T {.closure.} =
    for x in s.a..s.b:
      yield x
  return it

proc toIter*[T](i: iterator: T): iterator: T =
  ## Nop
  i

iterator revItems*[T](a: iterator: T): T =
  for i in countdown(high(a), low(a)):
    yield a[i]

iterator revPairs*[T](a: iterator: T): tuple[key: int, val: T] =
  ## iterates over the items of a `seq`, `array` or `string` in reverse,
  ## yielding ``(index, a[index])``.
  ##
  ##   var xs = @[1,3,5,7,9,11]
  ##   for i,x in xs.revPairs:
  ##     echo i, " ", x
  for i in countdown(high(a), low(a)):
    yield (i, a[i])

proc map*[T,S](i: Iterable[T], f: proc(x: T): S): iterator: S =
  ## Returns an iterator which applies `f` to every item in `i`.
  ##
  ## .. code-block:: nim
  ##   for x in map(2..10, proc(x): int = x * 2):
  ##     echo x
  ##
  ##   for i in (1..10).map(proc(x): string = "foo: " & $x):
  ##     echo i
  let i = toIter(i)
  iterator it: S {.closure.} =
    for x in i():
      yield f(x)
  result = it

iterator map*[T,S](i: Iterable[T], f: proc(x: T): S): S =
  let i = toIter(i)
  for x in i():
    yield f(x)

proc filter*[T](i: Iterable[T], f: proc(x: T): bool): iterator: T =
  ## Iterates through an iterator and yields every item that fulfills the
  ## predicate `f`.
  ##
  ## .. code-block:: nim
  ##   for x in filter(1..11, proc(x): bool = x mod 2 == 0):
  ##     echo x
  let i = toIter(i)
  iterator it: T {.closure.} =
    for x in i():
      if f(x):
        yield x
  result = it

iterator filter*[T](i: Iterable[T], f: proc(x: T): bool): T =
  let i = toIter(i)
  for x in i():
    if f(x):
      yield x

proc concat*[T](its: varargs[T, toIter]): iterator: T =
  ## Takes several iterators' items and returns a new iterator from them.
  ##
  ## .. code-block:: nim
  ##   for i in concat(1..4, 20..23):
  ##     echo i
  iterator it: T {.closure.} =
    for i in its:
      for x in i():
        yield x
  result = it

iterator concat*[T](its: varargs[T, toIter]): auto =
  for i in its:
    for x in i():
      yield x

proc zip*[T,S](i: (iterator: T) | Slice[T], j: Iterable[S]): iterator: tuple[a: T, b: S] =
  ## Iterates through both iterators at the same time, returning a tuple of
  ## both elements as long as neither of the iterators has finished.
  ##
  ## .. code-block:: nim
  ##   for x in zip(1..4, 20..24):
  ##     echo x
  let i = toIter(i)
  let j = toIter(j)
  iterator it: tuple[a: T, b: S] {.closure.} =
    while true:
      let result = (i(), j())
      if finished(i) or finished(j):
        break
      yield result
  result = it

iterator zip*[T,S](i: (iterator: T) | Slice[T], j: Iterable[S]): tuple[a: T, b: S] =
  let i = toIter(i)
  let j = toIter(j)
  while true:
    let result = (i(), j())
    if finished(i) or finished(j):
      break
    yield result

proc slice*[T](i: Iterable[T], first = 0, last = 0, step = 1): iterator: T =
  ## Yields every `step` item in `i` from index `first` to `last`.
  ##
  ## .. code-block:: nim
  ##   for i in slice(0..100, 10, 20)
  ##     echo i
  let i = toIter(i)
  var pos = 0
  iterator it: T {.closure.} =
    for x in i():
      if pos > last:
        break
      elif pos >= first and (pos - first) mod step == 0:
        yield x
      inc pos
  result = it

iterator slice*[T](i: Iterable[T], first = 0, last = 0, step = 1): T =
  let i = toIter(i)
  var pos = 0
  for x in i():
    if pos > last:
      break
    elif pos >= first and (pos - first) mod step == 0:
      yield x
    inc pos

proc delete*[T](i: Iterable[T], first = 0, last = 0): iterator: T =
  ## Yields the items in `i` except for the ones between `first` and `last`.
  ##
  ## .. code-block:: nim
  ##   for x in delete(1..10, 4, 8):
  ##     echo x
  let i = toIter(i)
  var pos = 0
  iterator it: T {.closure.} =
    for x in i():
      if pos notin first..last:
        yield x
      inc pos
  result = it

iterator delete*[T](i: Iterable[T], first = 0, last = 0): T =
  let i = toIter(i)
  var pos = 0
  for x in i():
    if pos notin first..last:
      yield x
    inc pos

proc foldl*[T,S](i: Iterable[T], f: proc(x: S, y: T): S, y: S): S =
  ## Folds the values as the iterator yields them, returning the accumulation.
  ##
  ## As the initial value of the accumulation `y` is used.
  ##
  ## .. code-block:: nim
  ##   echo foldl(1..10, proc(x,y: int): int = x + y, 0)
  let i = toIter(i)
  result = y
  for x in i():
    result = f(result, x)

proc foldl*[T](i: Iterable[T], f: proc(x, y: T): T): T =
  ## Folds the values as the iterator yields them, returning the accumulation.
  ##
  ## The iterator is required to return at least a single element.
  ##
  ## .. code-block:: nim
  ##   echo foldl(1..10, proc(x,y: int): int = x + y)
  let i = toIter(i)
  result = i()
  for x in i():
    result = f(result, x)

template toClosure*(i): auto =
  ## Wrap an inline iterator in a first-class closure iterator.
  iterator j: type(i) {.closure.} =
    for x in i:
      yield x
  j

when isMainModule:
  import future, tables
  from sequtils import toSeq

  block: # map 1
    var it = toSeq(map(toIter(2..10), proc(x: int): int = x * 2))
    assert it == @[4, 6, 8, 10, 12, 14, 16, 18, 20]

  block: # map 2
    var it = toSeq(map(2..10, proc(x: int): int = x * 2))
    assert it == @[4, 6, 8, 10, 12, 14, 16, 18, 20]

  block: # map 3
    var it = toSeq((1..10).map(proc(x: int): string = "foo: " & $x))
    assert it == @["foo: 1", "foo: 2", "foo: 3", "foo: 4", "foo: 5", "foo: 6", "foo: 7", "foo: 8", "foo: 9", "foo: 10"]

  block: # filter 1
    var it = toSeq(filter(toIter(1..11), proc(x: int): bool = x mod 2 == 0))
    assert it == @[2, 4, 6, 8, 10]

  block: # filter 2
    var it = toSeq(filter(1..11, proc(x: int): bool = x mod 2 == 0))
    assert it == @[2, 4, 6, 8, 10]

  block: # concat 1
    var it = toSeq(concat(toIter(1..4), toIter(20..23)))
    assert it == @[1, 2, 3, 4, 20, 21, 22, 23]

  block: # concat 2
    var it = toSeq(concat(1..4, toIter(20..23)))
    assert it == @[1, 2, 3, 4, 20, 21, 22, 23]

  block: # concat 3
    var it = toSeq(concat(1..4, 20..23))
    assert it == @[1, 2, 3, 4, 20, 21, 22, 23]

  block: # zip
    var it = toSeq(zip(1..4, 20..24))
    assert it == @[(a: 1, b: 20), (a: 2, b: 21), (a: 3, b: 22), (a: 4, b: 23)]

  block: # delete
    var it = toseq(delete(1..10, 4, 8))
    assert it == @[1, 2, 3, 4, 10]

  block: # foldl 1
    var it = foldl(1..10, proc(x,y: int): int = x + y, 0)
    assert it == 55

  block: # foldl 2
    var it = foldl(1..10, proc(x,y: int): int = x + y)
    assert it == 55

  # TODO: Currently fail
  block: # combination 1
    var it = toSeq(filter(map(filter(2..10, proc(x: int): bool = x mod 2 == 0), proc(x: int): int = x * 2), proc(x: int): bool = x mod 8 == 0))
    assert it == @[8, 16]

  block: # combination 2
    var it = toSeq((2..10).filter(proc(x: int): bool = x mod 2 == 0).map(proc(x: int): int = x * 2).filter(proc(x: int): bool = x mod 8 == 0))
    assert it == @[8, 16]

  block: # combination 3
    var a = (2..10).filter(proc(x: int): bool = x mod 2 == 0)
    var b = a.map((x: int) => x * 2)
    var c = toSeq(b.map((x: int) => x + 2))
    assert c == @[6, 10, 14, 18, 22]

  block: # wrap inline iterator
    let d = {1: 4, 2: 5, 3: 6}.toTable

    iterator myiteropt[T](anotheriter: iterator: T): T =
      for i in 0..<3:
        var iter: type(anotheriter)
        iter.deepCopy(anotheriter)
        for j in iter():
          yield j

    var s = newSeq[int]()
    for i in myiteropt(toClosure(values(d))): s.add(i)
    for i in myiteropt(toClosure(2..10)): s.add(i)
    assert s == @[4, 5, 6, 4, 5, 6, 4, 5, 6, 2, 3, 4, 5, 6, 7, 8, 9, 10, 2, 3, 4, 5, 6, 7, 8, 9, 10, 2, 3, 4, 5, 6, 7, 8, 9, 10]
