{.push raises: [].}

import ../common/[addresses, hashes, base]
import ssz_serialization/codec
import ssz_serialization/merkleization

# This follows how
# https://github.com/status-im/nimbus-eth2/blob/9839f140628ae0e2e8aa7eb055da5c4bb08171d0/beacon_chain/spec/ssz_codec.nim#L29
# does it for addresses in eth 2

# # SSZ for Address
# template toSszType*(T: Address): auto =
#   T.data()

# func fromSszBytes*( T: type Address, bytes: openArray[byte]): T {.raises: [SszError].} =
#   if bytes.len != sizeof(result.data()):
#     raiseIncorrectSize T
#   copyMem(addr result.data()[0], unsafeAddr bytes[0], sizeof(result.data()))

# # SSZ for Hash32
# template toSszType*(T: type Hash32): auto =
#   T.data()

# proc fromSszBytes*(T: type Hash32, bytes: openArray[byte]): T {.raises: [SszError].} =
#   if bytes.len != sizeof(result.data()):
#     raiseIncorrectSize T
#     copyMem(addr result.data()[0], unsafeAddr bytes[0], sizeof(result.data()))


########################
# Address adapters
########################

# when compiles((let x = default(Address); discard x.data)):
#   # Address is an object with a .data: array[20, byte]
#   template toSszType*(T: type Address): untyped = array[20, byte]
#   template toSszType*(v: Address): untyped = v.data
#   proc toSszType*(v: var Address): var array[20, byte] {.inline.} = v.data
#   proc fromSszBytes*(T: type Address, bytes: openArray[byte]): Address {.inline.} =
#     doAssert bytes.len == 20
#     var a: array[20, byte]
#     for i in 0 ..< 20: a[i] = bytes[i]
#     result = Address.copyFrom(a)
# else:
#   # Address is a distinct array[20, byte]
# template toSszType*(T: type Address): untyped = array[20, byte]
# template toSszType*(v: Address): untyped = cast[array[20, byte]](v)
# proc toSszType*(v: var Address): var array[20, byte] {.inline.} =
#   cast[var array[20, byte]](v)
# proc fromSszBytes*(T: type Address, bytes: openArray[byte]): Address {.inline.} =
#   doAssert bytes.len == 20
#   var a: array[20, byte]
#   for i in 0 ..< 20: a[i] = bytes[i]
#   cast[Address](a)

# ########################
# # Hash32 adapters
# ########################
#   # # Hash32 is an object with a .data: array[32, byte]
#   # template toSszType*(T: type Hash32): untyped = array[32, byte]
#   # template toSszType*(v: Hash32): untyped = v.data
#   # proc toSszType*(v: var Hash32): var array[32, byte] {.inline.} = v.data
#   # proc fromSszBytes*(T: type Hash32, bytes: openArray[byte]): Hash32 {.inline.} =
#   #   doAssert bytes.len == 32
#   #   var a: array[32, byte]
#   #   for i in 0 ..< 32: a[i] = bytes[i]
#   #   result = Hash32.copyFrom(a)

#   # Hash32 is a distinct array[32, byte]  <-- this matches your error message
# template toSszType*(T: type Hash32): untyped = array[32, byte]
# template toSszType*(v: Hash32): untyped = cast[array[32, byte]](v)
# proc toSszType*(v: var Hash32): var array[32, byte] {.inline.} =
#   cast[var array[32, byte]](v)
# proc fromSszBytes*(T: type Hash32, bytes: openArray[byte]): Hash32 {.inline.} =
#   doAssert bytes.len == 32
#   var a: array[32, byte]
#   for i in 0 ..< 32: a[i] = bytes[i]
#   cast[Hash32](a)
