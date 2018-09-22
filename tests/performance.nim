import std/sequtils
import pkg/iterutils

block:
  # Raw implementation with a loop:
  # 0.2 s
  for i in 1..100_000_000:
    if i mod 2 == 0:
      if i mod 4 == 0:
        if i mod 8 == 0:
          if i mod 16000 == 0:
            echo i div 16


block:
  # Using sequtils:
  # 5.3 s
  for i in toSeq(1..100_000_000).
      filter(proc(x: int): bool = x mod 2 == 0).
      filter(proc(x: int): bool = x mod 4 == 0).
      filter(proc(x: int): bool = x mod 8 == 0).
      filter(proc(x: int): bool = x mod 16000 == 0).
      map(proc(x: int): int = x div 16):
    echo i


block:
  # Using iterutils:
  # 1.8 s
  for i in (1..100_000_000).
      filter(proc(x: int): bool = x mod 2 == 0).
      filter(proc(x: int): bool = x mod 4 == 0).
      filter(proc(x: int): bool = x mod 8 == 0).
      filter(proc(x: int): bool = x mod 16000 == 0).
      map(proc(x: int): int = x div 16):
    echo i
