import std/times

const expected = 19534375000
const n = 100_000_000

when defined(case1):
  # Raw implementation with a loop:
  block:
    let t0 = epochTime()
    var total = 0
    for i in 1..n:
      if i mod 2 == 0:
        if i mod 4 == 0:
          if i mod 8 == 0:
            if i mod 16000 == 0:
              total += i div 16
    echo epochTime() - t0
    # 0.119 s (macbook pro 2017)
    doAssert total == expected

when defined(case2):
  import std/sequtils
  block:
    let t0 = epochTime()
    var total = 0
    for i in toSeq(1..n).
        filter(proc(x: int): bool = x mod 2 == 0).
        filter(proc(x: int): bool = x mod 4 == 0).
        filter(proc(x: int): bool = x mod 8 == 0).
        filter(proc(x: int): bool = x mod 16000 == 0).
        map(proc(x: int): int = x div 16):
      total += i
    echo epochTime() - t0
    # 3.00 s
    doAssert total == expected

when defined(case3):
  import pkg/iterutils
  block:
    # 1.8 s
    let t0 = epochTime()
    var total = 0
    for i in (1..n).
        filter(proc(x: int): bool = x mod 2 == 0).
        filter(proc(x: int): bool = x mod 4 == 0).
        filter(proc(x: int): bool = x mod 8 == 0).
        filter(proc(x: int): bool = x mod 16000 == 0).
        map(proc(x: int): int = x div 16):
      total += i
    echo epochTime() - t0
    # 1.26 s
    doAssert total == expected
