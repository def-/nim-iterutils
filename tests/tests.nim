import iterutils
from sequtils import toSeq
import sugar

proc test1()=
   for i in filter(map(filter(2..10, proc(x: int): bool = x mod 2 == 0),
            proc(x: int): int = x * 2), proc(x: int): bool = x mod 8 == 0):
     echo i

   var s = toSeq (2..10).filter(proc(x): bool = x mod 2 == 0).
           map(proc(x): int = x * 2).filter(proc(x): bool = x mod 8 == 0)
   echo s

   var a = (2..10).filter(proc(x: int): bool = x mod 2 == 0)
   var b = a.map((x: int) => x * 2)
   for i in b.map((x: int) => x + 2):
     echo i
test1()
