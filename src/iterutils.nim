## This module imlements operations for iterators and slices. You can see it as
## a lazy version of `sequtils`.
##
## The iterators can easily be combined:
##
## .. code-block:: nimrod
##   for i in filter(map(filter(2..10, proc(x: int): bool = x mod 2 == 0),
##            proc(x: int): int = x * 2), proc(x: int): bool = x mod 8 == 0):
##     echo i
##
##   var s = toSeq (2..10).filter(proc(x): bool = x mod 2 == 0).
##           map(proc(x): int = x * 2).filter(proc(x): bool = x mod 8 == 0)
##   echo s
##
##   var a = (2..10).filter(proc(x: int): bool = x mod 2 == 0)
##   var b = a.map((x: int) => x * 2)
##   for i in b.map((x: int) => x + 2):
##     echo i
##
## Performance example:
##
## Raw implementation with a loop:
##
## .. code-block:: nimrod
##   # 0.2 s
##   for i in 1..100_000_000:
##     if i mod 2 == 0:
##       if i mod 4 == 0:
##         if i mod 8 == 0:
##           if i mod 16000 == 0:
##             echo i div 16
##
## Using sequtils:
##
## .. code-block:: nimrod
##   # 5.3 s
##   for i in toSeq(1..100_000_000).
##            filter(proc(x): bool = x mod 2 == 0).
##            filter(proc(x): bool = x mod 4 == 0).
##            filter(proc(x): bool = x mod 8 == 0).
##            filter(proc(x): bool = x mod 16000 == 0).
##            map(proc(x): int = x div 16):
##     echo i
##
## Using iterutils:
##
## .. code-block:: nimrod
##   # 1.8 s
##   for i in (1..100_000_000).
##            filter(proc(x): bool = x mod 2 == 0).
##            filter(proc(x): bool = x mod 4 == 0).
##            filter(proc(x): bool = x mod 8 == 0).
##            filter(proc(x): bool = x mod 16000 == 0).
##            map(proc(x): int = x div 16):
##     echo i

# TODO: Can we get rid of duplication by unifying the iterators and procs?

type Iterable*[T] = (iterator: T) | TSlice[T]
  ## Everything that can be iterated over, iterators and slices so far.

proc toIter*[T](s: TSlice[T]): iterator: T =
  ## Iterate over a slice.
  iterator it: T {.closure.} =
    for x in s.a..s.b:
      yield x
  return it

proc toIter*[T](i: iterator: T): iterator: T =
  ## Nop
  i

iterator revItems*(a) =
  for i in countdown(high(a), low(a)):
    yield a[i]

iterator revPairs*(a) =
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
  ## .. code-block:: nimrod
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
  ## .. code-block:: nimrod
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
  ## .. code-block:: nimrod
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

proc zip*[T,S](i: (iterator: T) | TSlice[T], j: Iterable[S]): iterator: tuple[a: T, b: S] =
  ## Iterates through both iterators at the same time, returning a tuple of
  ## both elements as long as neither of the iterators has finished.
  ##
  ## .. code-block:: nimrod
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

iterator zip*[T,S](i: (iterator: T) | TSlice[T], j: Iterable[S]): tuple[a: T, b: S] =
  let i = toIter(i)
  let j = toIter(j)
  while true:
    let result = (i(), j())
    if finished(i) or finished(j):
      break
    yield result

proc delete*[T](i: Iterable[T], first = 0, last = 0): iterator: T =
  ## Yields the items in `i` except for the ones between `first` and `last`.
  ##
  ## .. code-block:: nimrod
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
  ## .. code-block:: nimrod
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
  ## .. code-block:: nimrod
  ##   echo foldl(1..10, proc(x,y: int): int = x + y)
  let i = toIter(i)
  result = i()
  for x in i():
    result = f(result, x)

when isMainModule:
  import sequtils, future

  block: # map 1
    var it = toSeq(map(toIter(2..10), proc(x): int = x * 2))
    assert it == @[4, 6, 8, 10, 12, 14, 16, 18, 20]

  block: # map 2
    var it = toSeq(map(2..10, proc(x): int = x * 2))
    assert it == @[4, 6, 8, 10, 12, 14, 16, 18, 20]

  block: # map 3
    var it = toSeq((1..10).map(proc(x): string = "foo: " & $x))
    assert it == @["foo: 1", "foo: 2", "foo: 3", "foo: 4", "foo: 5", "foo: 6", "foo: 7", "foo: 8", "foo: 9", "foo: 10"]

  block: # filter 1
    var it = toSeq(filter(toIter(1..11), proc(x): bool = x mod 2 == 0))
    assert it == @[2, 4, 6, 8, 10]

  block: # filter 2
    var it = toSeq(filter(1..11, proc(x): bool = x mod 2 == 0))
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

  block: # combination 1
    var it = toSeq(filter(map(filter(2..10, proc(x: int): bool = x mod 2 == 0), proc(x: int): int = x * 2), proc(x: int): bool = x mod 8 == 0))
    assert it == @[8, 16]

  block: # combination 2
    var it = toSeq (2..10).filter(proc(x): bool = x mod 2 == 0).map(proc(x): int = x * 2).filter(proc(x): bool = x mod 8 == 0)
    assert it == @[8, 16]

  block: # combination 3
    var a = (2..10).filter(proc(x: int): bool = x mod 2 == 0)
    var b = a.map((x: int) => x * 2)
    var c = toSeq(b.map((x: int) => x + 2))
    assert c == @[6, 10, 14, 18, 22]
