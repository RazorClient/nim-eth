# Copyright (c) 2024-2026 Status Research & Development GmbH
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at https://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at https://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

{.push raises: [].}

import
  ssz_serialization, stint, ../common/[addresses, base, hashes], ./adapter, ./common_ssz

export adapter, common_ssz

type SignedTx*[P] = object
  payload*: P
  signature*: ExecutionSignature

type
  BasicFeesPerGas* = object
    regular*: FeePerGas

  BlobFeesPerGas* = object
    regular*: FeePerGas
    blob*: FeePerGas

type AccessTuple* = object
  address*: Address
  storage_keys*: seq[Hash32]

# Helper tuple mirroring the authorization values used in RLP transactions
type AuthTuple* =
  tuple[
    chain_id: ChainId,
    address: Address,
    nonce: uint64,
    y_parity: uint8,
    r: UInt256,
    s: UInt256,
  ]

type
  RlpReplayableBasicAuthorizationPayload* {.sszActiveFields: [1, 0, 1, 1].} = object
    magic*: TransactionType
    address*: Address
    nonce*: uint64

  RlpBasicAuthorizationPayload* {.sszActiveFields: [1, 1, 1, 1].} = object
    magic*: TransactionType
    chain_id*: ChainId
    address*: Address
    nonce*: uint64

  AuthorizationKind* = enum
    authReplayableBasic
    authBasic

  AuthorizationPayload* = object
    case kind*: AuthorizationKind
    of authReplayableBasic:
      replayable*: RlpReplayableBasicAuthorizationPayload
    of authBasic:
      basic*: RlpBasicAuthorizationPayload

  Authorization* = object
    payload*: AuthorizationPayload
    signature*: ExecutionSignature

type
  RlpLegacyReplayableBasicTransactionPayload* {.
    sszActiveFields: [1, 0, 1, 1, 1, 1, 1, 1]
  .} = object
    txType*: TransactionType
    nonce*: uint64
    max_fees_per_gas*: BasicFeesPerGas
    gas*: GasAmount
    to*: Address
    value*: UInt256
    input*: ProgressiveByteList

  RlpLegacyReplayableCreateTransactionPayload* {.
    sszActiveFields: [1, 0, 1, 1, 1, 0, 1, 1]
  .} = object
    txType*: TransactionType
    nonce*: uint64
    max_fees_per_gas*: BasicFeesPerGas
    gas*: GasAmount
    value*: UInt256
    input*: ProgressiveByteList

type
  RlpLegacyBasicTransactionPayload* {.sszActiveFields: [1, 1, 1, 1, 1, 1, 1, 1].} = object
    txType*: TransactionType
    chain_id*: ChainId
    nonce*: uint64
    max_fees_per_gas*: BasicFeesPerGas
    gas*: GasAmount
    to*: Address
    value*: UInt256
    input*: ProgressiveByteList

  RlpLegacyCreateTransactionPayload* {.sszActiveFields: [1, 1, 1, 1, 1, 0, 1, 1].} = object
    txType*: TransactionType
    chain_id*: ChainId
    nonce*: uint64
    max_fees_per_gas*: BasicFeesPerGas
    gas*: GasAmount
    value*: UInt256
    input*: ProgressiveByteList

type RlpAccessListBasicTransactionPayload* {.
  sszActiveFields: [1, 1, 1, 1, 1, 1, 1, 1, 1]
.} = object
  txType*: TransactionType
  chain_id*: ChainId
  nonce*: uint64
  max_fees_per_gas*: BasicFeesPerGas
  gas*: GasAmount
  to*: Address
  value*: UInt256
  input*: ProgressiveByteList
  access_list*: seq[AccessTuple]

type RlpAccessListCreateTransactionPayload* {.
  sszActiveFields: [1, 1, 1, 1, 1, 0, 1, 1, 1]
.} = object
  txType*: TransactionType
  chain_id*: ChainId
  nonce*: uint64
  max_fees_per_gas*: BasicFeesPerGas
  gas*: GasAmount
  value*: UInt256
  input*: ProgressiveByteList
  access_list*: seq[AccessTuple]

type
  RlpBasicTransactionPayload* {.sszActiveFields: [1, 1, 1, 1, 1, 1, 1, 1, 1, 1].} = object
    txType*: TransactionType
    chain_id*: ChainId
    nonce*: uint64
    max_fees_per_gas*: BasicFeesPerGas
    gas*: GasAmount
    to*: Address
    value*: UInt256
    input*: ProgressiveByteList
    access_list*: seq[AccessTuple]
    max_priority_fees_per_gas*: BasicFeesPerGas

  RlpCreateTransactionPayload* {.sszActiveFields: [1, 1, 1, 1, 1, 0, 1, 1, 1, 1].} = object
    txType*: TransactionType
    chain_id*: ChainId
    nonce*: uint64
    max_fees_per_gas*: BasicFeesPerGas
    gas*: GasAmount
    value*: UInt256
    input*: ProgressiveByteList
    access_list*: seq[AccessTuple]
    max_priority_fees_per_gas*: BasicFeesPerGas

type RlpBlobTransactionPayload* {.sszActiveFields: [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1].} = object
  txType*: TransactionType
  chain_id*: ChainId
  nonce*: uint64
  max_fees_per_gas*: BlobFeesPerGas
  gas*: GasAmount
  to*: Address
  value*: UInt256
  input*: ProgressiveByteList
  access_list*: seq[AccessTuple]
  max_priority_fees_per_gas*: BasicFeesPerGas
  blob_versioned_hashes*: seq[VersionedHash]

type RlpSetCodeTransactionPayload* {.
  sszActiveFields: [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1]
.} = object
  txType*: TransactionType
  chain_id*: ChainId
  nonce*: uint64
  max_fees_per_gas*: BasicFeesPerGas
  gas*: GasAmount
  to*: Address
  value*: UInt256
  input*: ProgressiveByteList
  access_list*: seq[AccessTuple]
  max_priority_fees_per_gas*: BasicFeesPerGas
  authorization_list*: seq[Authorization]

type
  RlpLegacyReplayableBasicTransaction* =
    SignedTx[RlpLegacyReplayableBasicTransactionPayload]
  RlpLegacyReplayableCreateTransaction* =
    SignedTx[RlpLegacyReplayableCreateTransactionPayload]
  RlpLegacyBasicTransaction* = SignedTx[RlpLegacyBasicTransactionPayload]
  RlpLegacyCreateTransaction* = SignedTx[RlpLegacyCreateTransactionPayload]
  RlpAccessListBasicTransaction* = SignedTx[RlpAccessListBasicTransactionPayload]
  RlpAccessListCreateTransaction* = SignedTx[RlpAccessListCreateTransactionPayload]
  RlpBasicTransaction* = SignedTx[RlpBasicTransactionPayload]
  RlpCreateTransaction* = SignedTx[RlpCreateTransactionPayload]
  RlpBlobTransaction* = SignedTx[RlpBlobTransactionPayload]
  RlpSetCodeTransaction* = SignedTx[RlpSetCodeTransactionPayload]

  RlpTxType* = enum
    legacy = 0x00'u8
    accessList = 0x01'u8
    feeMarket = 0x02'u8
    blob = 0x03'u8
    setCode = 0x04'u8
    setCodeMagic = 0x05'u8

  RLPTransactionKind* {.pure.} = enum
    txLegacyReplayableBasic = 0
    txLegacyReplayableCreate
    txLegacyBasic
    txLegacyCreate
    txAccessListBasic
    txAccessListCreate
    txBasic
    txCreate
    txBlob
    txSetCode

  TransactionPayloadKind* = RLPTransactionKind

  TransactionPayload* = object
    case kind*: TransactionPayloadKind
    of txLegacyReplayableBasic:
      legacyReplayableBasic*: RlpLegacyReplayableBasicTransactionPayload
    of txLegacyReplayableCreate:
      legacyReplayableCreate*: RlpLegacyReplayableCreateTransactionPayload
    of txLegacyBasic:
      legacyBasic*: RlpLegacyBasicTransactionPayload
    of txLegacyCreate:
      legacyCreate*: RlpLegacyCreateTransactionPayload
    of txAccessListBasic:
      accessListBasic*: RlpAccessListBasicTransactionPayload
    of txAccessListCreate:
      accessListCreate*: RlpAccessListCreateTransactionPayload
    of txBasic:
      basic*: RlpBasicTransactionPayload
    of txCreate:
      create*: RlpCreateTransactionPayload
    of txBlob:
      blob*: RlpBlobTransactionPayload
    of txSetCode:
      setCode*: RlpSetCodeTransactionPayload

  Transaction* = SignedTx[TransactionPayload]
