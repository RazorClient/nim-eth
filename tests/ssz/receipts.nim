import
  unittest2,
  ssz_serialization/merkleization,
  ssz_serialization,
  macros,
  std/sequtils,
  ../../eth/common/[addresses, base, hashes],
  ../../eth/ssz/[receipts, adapter]

template roundTrip*(v: var untyped) =
  var bytes = SSZ.encode(v)
  var v2 = SSZ.decode(bytes, v.type)
  var bytes2 = SSZ.encode(v2)
  check bytes == bytes2

template topicFill(b: byte): untyped =
  (
    block:
      var buf: array[32, byte]
      for i in 0 ..< 32:
        buf[i] = b
      Hash32.copyFrom(buf)
  )

# Idea- pass only l values to this

macro testRT*(name: static[string], expr: typed): untyped =
  ## Roundtrip SSZ + size check.
  let valueSym = genSym(nskLet, "rtValue")
  let bytesSym = genSym(nskLet, "rtEncoded")
  let value2Sym = genSym(nskVar, "rtDecoded")
  let bytes2Sym = genSym(nskLet, "rtReencoded")

  result = quote:
    test `name`:
      let `valueSym` = `expr`
      when compiles(encodeReceipt(`valueSym`)):
        let `bytesSym` = encodeReceipt(`valueSym`)
        echo "encodeReceipt bytes.len=", `bytesSym`.len, " preview=", bytesSym
        var `value2Sym` = decodeReceipt[type(`valueSym`)](`bytesSym`)
        let `bytes2Sym` = encodeReceipt(`value2Sym`)
        echo "re-encode bytes.len=", `bytes2Sym`.len, " preview=", bytes2Sym
        check `bytesSym` == `bytes2Sym`
        check sszSize(asTagged(`valueSym`)) == `bytesSym`.len
      else:
        let `bytesSym` = SSZ.encode(`valueSym`)
        echo "SSZ.encode bytes.len=", `bytesSym`.len, " preview=", bytesSym
        var `value2Sym` = SSZ.decode(`bytesSym`, type(`valueSym`))
        let `bytes2Sym` = SSZ.encode(`value2Sym`)
        echo "SSZ.re-encode len=", `bytes2Sym`.len, " preview=", bytes2Sym
        check `bytesSym` == `bytes2Sym`
        check sszSize(`valueSym`) == `bytesSym`.len

macro testRT*(name: static[string], expr: typed, body: untyped): untyped =
  ## Same as above, with an extra assertions block.
  let valueSym = genSym(nskLet, "rtValue")
  let bytesSym = genSym(nskLet, "rtEncoded")
  let value2Sym = genSym(nskVar, "rtDecoded")
  let bytes2Sym = genSym(nskLet, "rtReencoded")
  let userAlias = ident("v")

  result = quote:
    test `name`:
      let `valueSym` = `expr`
      when compiles(encodeReceipt(`valueSym`)):
        let `bytesSym` = encodeReceipt(`valueSym`)
        # echo "encodeReceipt bytes.len=", `bytesSym`.len, " preview=", hexPreview(`bytesSym`)
        var `value2Sym` = decodeReceipt[type(`valueSym`)](`bytesSym`)
        let `bytes2Sym` = encodeReceipt(`value2Sym`)
        # echo "re-encode bytes.len=", `bytes2Sym`.len, " preview=", hexPreview(`bytes2Sym`)
        check `bytesSym` == `bytes2Sym`
        check sszSize(asTagged(`valueSym`)) == `bytesSym`.len
      else:
        let `bytesSym` = SSZ.encode(`valueSym`)
        # echo "SSZ.encode bytes.len=", `bytesSym`.len, " preview=", hexPreview(`bytesSym`)
        var `value2Sym` = SSZ.decode(`bytesSym`, type(`valueSym`))
        let `bytes2Sym` = SSZ.encode(`value2Sym`)
        # echo "SSZ.re-encode len=", `bytes2Sym`.len, " preview=", hexPreview(`bytes2Sym`)
        check `bytesSym` == `bytes2Sym`
        check sszSize(`valueSym`) == `bytesSym`.len
      block:
        let `userAlias` = `valueSym`
        `body`

# # Pretty hex preview (first n bytes) and full hex dump
# proc hexPreview*(bytes: openArray[byte]; maxLen: int = 64): string =
#   let n = min(bytes.len, maxLen)
#   var s = newSeq[string](n)
#   for i in 0 ..< n:
#     s[i] = bytes[i].toHex(2)
#   result = s.join("")
#   if bytes.len > maxLen:
#     result.add("...")

suite "Log Construction (SSZ)":
  testRT "Log: empty topics",
    Log(
      address: addresses.zeroAddress,
      topics: List[Hash32, MAX_TOPICS_PER_LOG](@[]),
      data: @[],
    )

  testRT "Log: max topics",
    (
      block:
        let addrAA = Address.copyFrom(newSeqWith(20, byte 0xAA))
        Log(
          address: addrAA,
          topics: List[Hash32, MAX_TOPICS_PER_LOG](
            @[topicFill(0x10), topicFill(0x11), topicFill(0x12), topicFill(0x13)]
          ),
          data: @[byte 0xDE, 0xAD, 0xBE, 0xEF],
        )
    ):
    check v.topics.len == 4
  testRT "Log: 4 topics, some data",
    (
      block:
        let addr22 = Address.copyFrom(newSeqWith(20, byte 0x22))
        var a0, a1, a2, a3: array[32, byte]
        for i in 0 ..< 32:
          a0[i] = 0xA0'u8
          a1[i] = 0xA1'u8
          a2[i] = 0xA2'u8
          a3[i] = 0xA3'u8
        Log(
          address: addr22,
          topics: List[Hash32, MAX_TOPICS_PER_LOG](
            @[
              Hash32.copyFrom(a0),
              Hash32.copyFrom(a1),
              Hash32.copyFrom(a2),
              Hash32.copyFrom(a3),
            ]
          ),
          data: @[byte 0xDE, 0xAD, 0xBE, 0xEF],
        )
    ):
    check v.topics.len == 4

#   testRT "Log decode sanity",
#     (
#       block:
#         let addr33 = Address.copyFrom(newSeqWith(20, byte 0x33))
#         var t1, t2: array[32, byte]
#         for i in 0 ..< 32:
#           t1[i] = 1
#           t2[i] = 2
#         Log(
#           address: addr33,
#           topics: List[Hash32, MAX_TOPICS_PER_LOG](
#             @[Hash32.copyFrom(t1), Hash32.copyFrom(t2)]
#           ),
#           data: @[byte 1, 2, 3, 4],
#         )
#     ):
#     let d = SSZ.decode(SSZ.encode(v), Log)
#     check d.address == v.address
#     check d.topics.len == 2
#     check d.topics[0] == v.topics[0]
#     check d.topics[1] == v.topics[1]
#     check d.data == v.data

#   testRT "Log: large progressive data (128 KiB)",
#     (
#       block:
#         let a77 = Address.copyFrom(newSeqWith(20, byte 0x77))
#         var t1, t2: array[32, byte]
#         for i in 0 ..< 32:
#           t1[i] = 1
#           t2[i] = 2
#         var big = newSeq[byte](128 * 1024)
#         for i in 0 ..< big.len:
#           big[i] = byte(i and 0xFF)
#         Log(
#           address: a77,
#           topics: List[Hash32, MAX_TOPICS_PER_LOG](
#             @[Hash32.copyFrom(t1), Hash32.copyFrom(t2)]
#           ),
#           data: big,
#         )
#     ):
#     check v.data.len == 128 * 1024

# suite "Receipts Construction (SSZ)":
#   testRT "Basic Receipt empty",
#     BasicReceipt(
#       `from`: addresses.zeroAddress,
#       gas_used: 100'u64,
#       contract_address: addresses.zeroAddress,
#       logs: @[],
#       status: true,
#     )

#   testRT "Basic receipt data",
#     (
#       block:
#         let log0 = Log(
#           address: default(Address),
#           topics: default(List[Hash32, MAX_TOPICS_PER_LOG]),
#           data: @[],
#         )
#         BasicReceipt(
#           `from`: default(Address),
#           gas_used: 100'u64,
#           contract_address: default(Address),
#           logs: @[log0],
#           status: true,
#         )
#     ):
#     check v.gas_used == 100'u64
#     check v.status == true
#     check v.contract_address == default(Address)
#     check v.logs.len == 1

#   testRT "BasicReceipt: reserved contract_address is zero",
#     (
#       block:
#         let fromAA = Address.copyFrom(newSeqWith(20, byte 0xAA))
#         BasicReceipt(
#           `from`: fromAA,
#           gas_used: 1'u64,
#           contract_address: addresses.zeroAddress,
#           logs: @[],
#           status: true,
#         )
#     )
#     # Ensure the invariant stays true across SSZ
#     # let dec = decodeReceipt[BasicReceipt](encodeReceipt(v))
#     # check dec.contract_address == addresses.zeroAddress

#   testRT "CreateReceipt: no logs",
#     (
#       block:
#         let fromBB = Address.copyFrom(newSeqWith(20, byte 0xBB))
#         let addrCC = Address.copyFrom(newSeqWith(20, byte 0xCC))
#         CreateReceipt(
#           `from`: fromBB,
#           gas_used: 42'u64,
#           contract_address: addrCC,
#           logs: @[],
#           status: false,
#         )
#     ):
#     check v.logs.len == 0

#   testRT "Create receipt:logs 1",
#     (
#       block:
#         let log1 = Log(
#           address: default(Address),
#           topics: default(List[Hash32, MAX_TOPICS_PER_LOG]),
#           data: @[byte 0x01, 0x02, 0x03],
#         )
#         let createdAddr = address"0x00000000000000000000000000000000000000aa"
#         CreateReceipt(
#           `from`: address"0x00000000000000000000000000000000000000bb",
#           gas_used: 21000'u64,
#           contract_address: createdAddr,
#           logs: @[log1],
#           status: false,
#         )
#     ):
#     check v.gas_used == 21000'u64
#     check v.status == false
#     check v.logs.len == 1

#   testRT "SetCode receipt",
#     (
#       block:
#         let log2 = Log(
#           address: address"0x00000000000000000000000000000000000000cc",
#           topics: default(List[Hash32, MAX_TOPICS_PER_LOG]),
#           data: @[],
#         )
#         SetCodeReceipt(
#           `from`: address"0x00000000000000000000000000000000000000dd",
#           gas_used: 42000'u64,
#           contract_address: address"0x00000000000000000000000000000000000000ee",
#           logs: @[log2],
#           status: true,
#           authorities:
#             @[
#               address"0x00000000000000000000000000000000000000f1",
#               address"0x00000000000000000000000000000000000000f2",
#             ],
#         )
#     ):
#     check v.gas_used == 42000'u64
#     check v.status == true
#     check v.authorities.len == 2
#     check v.logs.len == 1

# # #TODO -> rlp to receipts ssz

# suite "SSZ Debug Tests":
  # test "Test individual receipt components":
  #   echo "=== Testing individual SSZ components ==="

  #   echo "Testing Address SSZ..."
  #   try:
  #     let addr = addresses.zeroAddress
  #     let addrHash = hash_tree_root(addr)
  #     echo "Address hash_tree_root successful: ", addrHash.to0xHex()
  #   except Exception as e:
  #     echo "ERROR with Address SSZ: ", e.msg
  #     echo "Exception type: ", $e.name

  #   echo "Testing Log SSZ..."
  #   try:
  #     let log = Log(
  #       address: addresses.zeroAddress,
  #       topics: List[Hash32, MAX_TOPICS_PER_LOG](@[]),
  #       data: @[],
  #     )
  #     let logHash = hash_tree_root(log)
  #     echo "Log hash_tree_root successful: ", logHash.to0xHex()
  #   except Exception as e:
  #     echo "ERROR with Log SSZ: ", e.msg
  #     echo "Exception type: ", $e.name

  #   echo "Testing BasicReceipt SSZ..."
  #   try:
  #     let basicReceipt = BasicReceipt(
  #       `from`: addresses.zeroAddress,
  #       gas_used: 21_000'u64,
  #       contract_address: addresses.zeroAddress,
  #       logs: @[],
  #       status: true,
  #     )
  #     let basicHash = hash_tree_root(basicReceipt)
  #     echo "BasicReceipt hash_tree_root successful: ", basicHash.to0xHex()
  #   except Exception as e:
  #     echo "ERROR with BasicReceipt SSZ: ", e.msg
  #     echo "Exception type: ", $e.name

  #   echo "Testing Receipt variant SSZ..."
  #   try:
  #     let receipt = toReceipt(BasicReceipt(
  #       `from`: addresses.zeroAddress,
  #       gas_used: 21_000'u64,
  #       contract_address: addresses.zeroAddress,
  #       logs: @[],
  #       status: true,
  #     ))
  #     echo "Receipt created with kind: ", receipt.kind
  #     let receiptHash = hash_tree_root(receipt)
  #     echo "Receipt hash_tree_root successful: ", receiptHash.to0xHex()
  #   except Exception as e:
  #     echo "ERROR with Receipt variant SSZ: ", e.msg
  #     echo "Exception type: ", $e.name

# suite "Block receipts root (SSZ)":
#   test "receipts root for 3 receipts: non-zero and stable":
#     echo "Creating BasicReceipt..."
#     let r0 = toReceipt(
#       BasicReceipt(
#         `from`: addresses.zeroAddress,
#         gas_used: 21_000'u64,
#         contract_address: addresses.zeroAddress,
#         logs: @[],
#         status: true,
#       )
#     )
#     echo "BasicReceipt created: ", r0.kind

#     echo "Creating CreateReceipt..."
#     let r1 = toReceipt(
#       CreateReceipt(
#         `from`: address"0x0000000000000000000000000000000000000001",
#         gas_used: 42_000'u64,
#         contract_address: address"0x00000000000000000000000000000000000000aa",
#         logs: @[],
#         status: false,
#       )
#     )
#     echo "CreateReceipt created: ", r1.kind

#     echo "Creating SetCodeReceipt..."
#     let r2 = toReceipt(
#       SetCodeReceipt(
#         `from`: address"0x00000000000000000000000000000000000000bb",
#         gas_used: 63_000'u64,
#         contract_address: address"0x00000000000000000000000000000000000000cc",
#         logs: @[],
#         status: true,
#         authorities: @[address"0x00000000000000000000000000000000000000f1"],
#       )
#     )
#     echo "SetCodeReceipt created: ", r2.kind

#     var receipts: seq[Receipt] = @[r0, r1, r2]
#     echo "Created receipts sequence with ", receipts.len, " items"

#     echo "Attempting to compute hash_tree_root..."
#     try:
#       let root1 = hash_tree_root(receipts)
#       check root1 != hashes.zeroHash32
#       echo "receipts_root: ", root1.to0xHex()

#       echo "Attempting SSZ.encode on receipts..."
#       try:
#         let enc = SSZ.encode(receipts)
#         echo "SSZ encoding successful, size: ", enc.len

#         echo "Attempting SSZ.decode..."
#         let receipts2 = SSZ.decode(enc, type(receipts))
#         echo "SSZ decoding successful"

#         let root2 = hash_tree_root(receipts2)
#         check root2 == root1
#         echo "Root comparison successful"

#       except Exception as e:
#         echo "ERROR in SSZ encode/decode: ", e.msg
#         echo "Exception type: ", $e.name
#         raise e

#     except Exception as e:
#       echo "ERROR in hash_tree_root: ", e.msg
#       echo "Exception type: ", $e.name
#       raise e

# test "receipts root changes when a receipt changes":
#   var receipts = @[
#     asTagged(BasicReceipt(`from`: default(Address), gas_used: 1'u64, contract_address: default(Address), logs: @[], status: true)),
#     asTagged(BasicReceipt(`from`: default(Address), gas_used: 2'u64, contract_address: default(Address), logs: @[], status: true))
#   ]
#   let rootA = hash_tree_root(receipts)
#   # mutate gas_used in first receipt
#   receipts[0].basic.gas_used = 3'u64
#   let rootB = hash_tree_root(receipts)
#   check rootA != rootB

# test "receipts root is order-sensitive":
#   let a = asTagged(BasicReceipt(`from`: default(Address), gas_used: 1'u64, contract_address: default(Address), logs: @[], status: true))
#   let b = asTagged(BasicReceipt(`from`: default(Address), gas_used: 2'u64, contract_address: default(Address), logs: @[], status: true))
#   let list1 = @[a, b]
#   let list2 = @[b, a]
#   let r1 = hash_tree_root(list1)
#   let r2 = hash_tree_root(list2)
#   check r1 != r2
#   echo "receipts_root(list1): ", r1.to0xHex()
#   echo "receipts_root(list2): ", r2.to0xHex()

# suite "SSZ root ":
#   test "hash_tree_root for Log":
#     let log = Log(
#       address: addresses.zeroAddress,
#       topics: List[Hash32, MAX_TOPICS_PER_LOG](@[]),
#       data: @[]
#     )
#     let root = hash_tree_root(log)
#     echo "Log root: "#, root.to0xHex()#

#   test "hash_tree_root for list of Log":
#     let log = Log(
#       address: addresses.zeroAddress,
#       topics: List[Hash32, MAX_TOPICS_PER_LOG](@[]),
#       data: @[]
#     )
#     let logs = @[log]
#     let root = hash_tree_root(logs)
#     # echo "Logs list root: ", root.to0xHex()

#   test "hash_tree_root for BasicReceipt":
#     let r = BasicReceipt(
#       `from`: addresses.zeroAddress,
#       gas_used: 100'u64,
#       contract_address: addresses.zeroAddress,
#       logs: @[],
#       status: true
#     )
#     let root = hash_tree_root(r)
# echo "BasicReceipt root: ", root.to0xHex()

# test "hash_tree_root for CreateReceipt":
#   let r = CreateReceipt(
#     `from`: address"0x0000000000000000000000000000000000000001",
#     gas_used: 42_000'u64,
#     contract_address: address"0x00000000000000000000000000000000000000aa",
#     logs: @[],
#     status: false
#   )
#   let root = hash_tree_root(r)
#   # echo "CreateReceipt root: ", root.to0xHex()

# test "hash_tree_root for SetCodeReceipt":
#   let r = SetCodeReceipt(
#     `from`: address"0x00000000000000000000000000000000000000bb",
#     gas_used: 63_000'u64,
#     contract_address: address"0x00000000000000000000000000000000000000cc",
#     logs: @[],
#     status: true,
#     authorities: @[address"0x00000000000000000000000000000000000000f1"]
#   )
#   let root = hash_tree_root(r)
#   echo "SetCodeReceipt root: ", root.to0xHex()

# test "hash_tree_root for tagged receipts list":
#   let r0 = BasicReceipt(
#     `from`: addresses.zeroAddress,
#     gas_used: 21_000'u64,
#     contract_address: addresses.zeroAddress,
#     logs: @[],
#     status: true
#   )
#   let r1 = CreateReceipt(
#     `from`: address"0x0000000000000000000000000000000000000001",
#     gas_used: 42_000'u64,
#     contract_address: address"0x00000000000000000000000000000000000000aa",
#     logs: @[],
#     status: false
#   )
#   let r2 = SetCodeReceipt(
#     `from`: address"0x00000000000000000000000000000000000000bb",
#     gas_used: 63_000'u64,
#     contract_address: address"0x00000000000000000000000000000000000000cc",
#     logs: @[],
#     status: true,
#     authorities: @[address"0x00000000000000000000000000000000000000f1"]
#   )
#   var receipts = @[
#     asTagged(r0),
#     asTagged(r1),
#     asTagged(r2)
#   ]
#   let root = hash_tree_root(receipts)
#   # echo "Tagged receipts list root: ", root.to0xHex()
