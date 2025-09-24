import
  unittest2,
  ssz_serialization,
  # ssz_serialization/merkleization,
  macros,
  std/sequtils,
  stew/byteutils,
  stint,
  ../../eth/common/[addresses, base, hashes],
  ../../eth/ssz/[transaction_ssz, transaction_builder, signatures, codec]

const
  recipient = address"095e7baea6a6c7c4c2dfeb977efac326af552d87"
  source = address"0x0000000000000000000000000000000000000001"
  storageKey = default(Bytes32)
  abcdef = hexToSeqByte("abcdef")

let accesses: seq[AccessTuple] =
  @[AccessTuple(address: source, storage_keys: @[Hash32(storageKey)])]

proc dummySig(): Secp256k1ExecutionSignature =
  secp256k1Pack(1.u256, 1.u256, 0'u8)

macro txRT*(name: static[string], expr: typed): untyped =
  ## SSZ roundtrip + size check for a Transaction-like value.
  let v = genSym(nskLet, "txValue")
  let b1 = genSym(nskLet, "enc1")
  let v2 = genSym(nskVar, "dec")
  let b2 = genSym(nskLet, "enc2")
  result = quote:
    test `name`:
      let `v` = `expr`
      let `b1` = SSZ.encode(`v`)
      var `v2` = SSZ.decode(`b1`, type(`v`))
      let `b2` = SSZ.encode(`v2`)
      check `b1` == `b2`
      check sszSize(`v`) == `b1`.len

macro txRT*(name: static[string], expr: typed, body: untyped): untyped =
  ## Same as above, plus custom assertions with aliases:
  ##    t : original value
  ##    d : decoded value
  # echo "RAW ARG AST:\n", treeRepr(expr)
  let v = genSym(nskLet, "txValue")
  let b1 = genSym(nskLet, "enc1")
  let v2 = genSym(nskVar, "dec")
  let b2 = genSym(nskLet, "enc2")
  let t = ident("t")
  let d = ident("d")
  # echo treeRepr(result)
  result = quote:
    test `name`:
      let `v` = `expr`
      let `b1` = SSZ.encode(`v`)
      var `v2` = SSZ.decode(`b1`, type(`v`))
      let `b2` = SSZ.encode(`v2`)
      check `b1` == `b2`
      check sszSize(`v`) == `b1`.len
      block:
        let `t` = `v`
        let `d` = `v2`
        `body`

suite "SSZ Transactions (round-trip)":
  txRT "SSZ: Legacy Call",
    Transaction(
      txType = 0x00'u8,
      chain_id = ChainId(1.u256),
      nonce = 1'u64,
      gas = 21_000'u64,
      to = Opt.some(recipient),
      value = 0.u256,
      input = abcdef,
      max_fees_per_gas = BasicFeesPerGas(regular: 2.u256),
      signature = dummySig(),
    ):
    check d.rlp.legacyBasic.payload.txType == 0x00'u8
    check d.rlp.legacyBasic.payload.to == t.rlp.legacyBasic.payload.to
    check d.rlp.legacyBasic.payload.nonce == t.rlp.legacyBasic.payload.nonce
    check d.rlp.legacyBasic.payload.gas == t.rlp.legacyBasic.payload.gas
    check d.rlp.legacyBasic.payload.input == t.rlp.legacyBasic.payload.input
    check d.rlp.legacyBasic.signature == t.rlp.legacyBasic.signature

  txRT "SSZ: Legacy Create",
    Transaction(
      txType = 0x00'u8,
      chain_id = ChainId(1.u256),
      nonce = 2'u64,
      gas = 50_000'u64,
      to = Opt.none(Address),
      value = 0.u256,
      input = abcdef, # initcode present
      max_fees_per_gas = BasicFeesPerGas(regular: 2.u256),
      signature = dummySig(),
    ):
    check d.rlp.legacyCreate.payload.txType == 0x00'u8
    check d.rlp.legacyCreate.payload.input.len == abcdef.len

  txRT "SSZ: 2930 Call",
    Transaction(
      txType = 0x01'u8,
      chain_id = ChainId(1.u256),
      nonce = 3'u64,
      gas = 123_457'u64,
      to = Opt.some(recipient),
      value = 0.u256,
      input = abcdef,
      max_fees_per_gas = BasicFeesPerGas(regular: 10.u256),
      access_list = accesses,
      signature = dummySig(),
    ):
    check d.rlp.accessListBasic.payload.txType == 0x01'u8
    check d.rlp.accessListBasic.payload.access_list.len == 1
    check d.rlp.accessListBasic.payload.access_list[0].address == source

  txRT "SSZ: 2930 Create",
    Transaction(
      txType = 0x01'u8,
      chain_id = ChainId(1.u256),
      nonce = 4'u64,
      gas = 123_457'u64,
      to = Opt.none(Address),
      value = 0.u256,
      input = abcdef,
      max_fees_per_gas = BasicFeesPerGas(regular: 10.u256),
      signature = dummySig(),
    ):
    check d.rlp.accessListCreate.payload.txType == 0x01'u8

  txRT "SSZ: 1559 Call",
    Transaction(
      txType = 0x02'u8,
      chain_id = ChainId(1.u256),
      nonce = 5'u64,
      gas = 123_457'u64,
      to = Opt.some(recipient),
      value = 0.u256,
      input = abcdef,
      max_fees_per_gas = BasicFeesPerGas(regular: 10.u256),
      max_priority_fees_per_gas = BasicFeesPerGas(regular: 2.u256),
      access_list = accesses,
      signature = dummySig(),
    ):
    check d.rlp.basic.payload.txType == 0x02'u8
    check d.rlp.basic.payload.max_priority_fees_per_gas.regular == 2.u256

  txRT "SSZ: 1559 Create",
    Transaction(
      txType = 0x02'u8,
      chain_id = ChainId(1.u256),
      nonce = 6'u64,
      gas = 123_457'u64,
      to = Opt.none(Address),
      value = 0.u256,
      input = abcdef,
      max_fees_per_gas = BasicFeesPerGas(regular: 10.u256),
      max_priority_fees_per_gas = BasicFeesPerGas(regular: 2.u256),
      signature = dummySig(),
    ):
    check d.rlp.create.payload.txType == 0x02'u8
    check d.rlp.create.payload.input.len == abcdef.len

  when compiles(BlobFeesPerGas):
    txRT "SSZ: 4844 Blob Tx",
      (
        block:
          const vh =
            hash32"010657f37554c781402a22917dee2f75def7ab966d7b770905398eba3c444014"
          Transaction(
            txType = 0x03'u8,
            chain_id = ChainId(1.u256),
            nonce = 7'u64,
            gas = 123_457'u64,
            to = Opt.some(recipient),
            value = 0.u256,
            input = @[],
            max_fees_per_gas = BasicFeesPerGas(regular: 10.u256),
            max_priority_fees_per_gas = BasicFeesPerGas(regular: 1.u256),
            access_list = accesses,
            blob_versioned_hashes = @[VersionedHash(vh)],
            blob_fee = 10.u256,
            signature = dummySig(),
          )
      ):
      check d.rlp.blob.payload.txType == 0x03'u8
      check d.rlp.blob.payload.blob_versioned_hashes.len == 1

  when compiles(Authorization):
    txRT "SSZ: SetCode (auth list)",
      Transaction(
        txType = 0x04'u8,
        chain_id = ChainId(1.u256),
        nonce = 8'u64,
        gas = 123_457'u64,
        to = Opt.some(recipient),
        value = 0.u256,
        input = @[],
        max_fees_per_gas = BasicFeesPerGas(regular: 10.u256),
        max_priority_fees_per_gas = BasicFeesPerGas(regular: 1.u256),
        authorization_list =
          @[
            Authorization(
              chain_id: ChainId(1.u256),
              nonce: 0'u64,
              signer: source,
              v: 27'u8,
              r: 1.u256,
              s: 1.u256,
            )
          ],
        signature = dummySig(),
      ):
      check d.rlp.setCode.payload.txType == 0x04'u8
      check d.rlp.setCode.payload.authorization_list.len == 1

#   # Negative SSZ decoding: truncated bytes must fail
#   test "SSZ: decode fails on truncated bytes":
#     let good = SSZ.encode(Transaction(
#       txType = 0x00'u8,
#       chain_id = ChainId(1.u256),
#       nonce = 123'u64,
#       gas = 21_000'u64,
#       to = Opt.some(recipient),
#       value = 0.u256,
#       input = abcdef,
#       max_fees_per_gas = BasicFeesPerGas(regular: 1.u256),
#       signature = dummySig(),
#     ))
#     var bad = good
#     if bad.len > 0: discard bad.pop() # truncate
#     expect CatchableError:
#       discard SSZ.decode(bad, Transaction)

# suite "Block transactions root (SSZ sanity)":
#   test "transactions root for 3 txs: non-zero and stable":
#     let t0 = Transaction(
#       txType = 0x00'u8,
#       chain_id = ChainId(1.u256),
#       nonce = 1'u64,
#       gas = 21_000'u64,
#       to = Opt.some(recipient),
#       value = 0.u256,
#       input = abcdef,
#       max_fees_per_gas = BasicFeesPerGas(regular: 2.u256),
#       signature = dummySig(),
#     )
#     let t1 = Transaction(
#       txType = 0x01'u8,
#       chain_id = ChainId(1.u256),
#       nonce = 2'u64,
#       gas = 44_000'u64,
#       to = Opt.none(Address),
#       value = 0.u256,
#       input = abcdef,
#       max_fees_per_gas = BasicFeesPerGas(regular: 5.u256),
#       signature = dummySig(),
#     )
#     let t2 = Transaction(
#       txType = 0x02'u8,
#       chain_id = ChainId(1.u256),
#       nonce = 3'u64,
#       gas = 50_000'u64,
#       to = Opt.some(recipient),
#       value = 0.u256,
#       input = abcdef,
#       max_fees_per_gas = BasicFeesPerGas(regular: 9.u256),
#       max_priority_fees_per_gas = BasicFeesPerGas(regular: 1.u256),
#       access_list = accesses,
#       signature = dummySig(),
#     )
#     var txs = @[t0, t1, t2]
#     let root1 = hash_tree_root(txs)
#     check root1 != hashes.zeroHash32
#     # round-trip list and ensure root is stable
#     let enc = SSZ.encode(txs)
#     let txs2 = SSZ.decode(enc, type(txs))
#     let root2 = hash_tree_root(txs2)
#     check root2 == root1
