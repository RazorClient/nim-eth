# eth
# Copyright (c) 2024-2025 Status Research & Development GmbH
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at https://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at https://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

{.push raises: [].}

import
  ssz_serialization,
  stint,
  ../common/[addresses, base, hashes],
  ./adapter

export adapter

type
  ExecutionSignatureAlgorithm* = uint8
  ProgressiveByteList* = seq[byte]
  ExecutionSignature* = ProgressiveByteList
  Secp256k1ExecutionSignature* = ExecutionSignature

const
  Secp256k1Algorithm*: ExecutionSignatureAlgorithm = 0xFF'u8

type SignedTx*[P] = object
  payload*: P
  signature*: ExecutionSignature

type
  TransactionType* = uint8
  GasAmount* = uint64
  FeePerGas* = UInt256

const
  TxLegacy*: TransactionType = 0x00'u8
  TxAccessList*: TransactionType = 0x01'u8
  TxDynamicFee*: TransactionType = 0x02'u8
  TxBlob*: TransactionType = 0x03'u8
  TxSetCode*: TransactionType = 0x04'u8
  AuthMagic7702*: TransactionType = 0x05'u8

type
  BasicFeesPerGas* = object
    regular*: FeePerGas

  BlobFeesPerGas* = object
    regular*: FeePerGas
    blob*: FeePerGas

type AccessTuple* = object
  address*: Address
  storage_keys*: seq[Hash32]

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
  RlpLegacyBasicTransactionPayload* {.sszActiveFields: [1, 1, 1, 1, 1, 1, 1, 1].} =
    object
      txType*: TransactionType
      chain_id*: ChainId
      nonce*: uint64
      max_fees_per_gas*: BasicFeesPerGas
      gas*: GasAmount
      to*: Address
      value*: UInt256
      input*: ProgressiveByteList

  RlpLegacyCreateTransactionPayload* {.sszActiveFields: [1, 1, 1, 1, 1, 0, 1, 1].} =
    object
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
  RlpBasicTransactionPayload* {.sszActiveFields: [1, 1, 1, 1, 1, 1, 1, 1, 1, 1].} =
    object
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

  RlpCreateTransactionPayload* {.sszActiveFields: [1, 1, 1, 1, 1, 0, 1, 1, 1, 1].} =
    object
      txType*: TransactionType
      chain_id*: ChainId
      nonce*: uint64
      max_fees_per_gas*: BasicFeesPerGas
      gas*: GasAmount
      value*: UInt256
      input*: ProgressiveByteList
      access_list*: seq[AccessTuple]
      max_priority_fees_per_gas*: BasicFeesPerGas

type RlpBlobTransactionPayload* {.
  sszActiveFields: [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
.} = object
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

  RlpTransactionObject* = object
    case kind*: RLPTransactionKind
    of txLegacyReplayableBasic:
      legacyReplayableBasic*: RlpLegacyReplayableBasicTransaction
    of txLegacyReplayableCreate:
      legacyReplayableCreate*: RlpLegacyReplayableCreateTransaction
    of txLegacyBasic:
      legacyBasic*: RlpLegacyBasicTransaction
    of txLegacyCreate:
      legacyCreate*: RlpLegacyCreateTransaction
    of txAccessListBasic:
      accessListBasic*: RlpAccessListBasicTransaction
    of txAccessListCreate:
      accessListCreate*: RlpAccessListCreateTransaction
    of txBasic:
      basic*: RlpBasicTransaction
    of txCreate:
      create*: RlpCreateTransaction
    of txBlob:
      blob*: RlpBlobTransaction
    of txSetCode:
      setCode*: RlpSetCodeTransaction

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

  TransactionKind* {.pure.} = enum
    TxNone = 0
    RlpTransaction = 1

  TransactionObject* = object
    case kind*: TransactionKind
    of TxNone:
      discard
    of RlpTransaction:
      rlp*: RlpTransactionObject

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
