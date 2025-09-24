import ssz_serialization
import stint
import ../common/[addresses, base, hashes]
import ./signatures

type SignedTx*[P] = object
  payload*: P
  signature*: Secp256k1ExecutionSignature

type
  TransactionType* = uint8
  GasAmount* = uint64
  FeePerGas* = UInt256
  ProgressiveByteList* = seq[byte]

const
  TxLegacy*: TransactionType = 00'u8
  TxAccessList*: TransactionType = 01'u8
  TxDynamicFee*: TransactionType = 02'u8
  TxBlob*: TransactionType = 03'u8
  TxSetCode*: TransactionType = 04'u8
  AuthMagic7702*: TransactionType = 05'u8

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

type
  RlpReplayableBasicAuthorizationPayload* = object
    magic*: TransactionType
    address*: Address
    nonce*: uint64

  RlpBasicAuthorizationPayload* = object
    magic*: TransactionType
    chain_id*: ChainId
    address*: Address
    nonce*: uint64

type
  AuthKind* {.pure.} = enum
    ReplayableBasic
    Basic

  RlpAuthorization* = object
    case kind*: AuthKind
    of ReplayableBasic:
      replayable*: RlpReplayableBasicAuthorizationPayload
    of Basic:
      basic*: RlpBasicAuthorizationPayload

type RlpSetCodeTransactionPayload* {.
  sszActiveFields: [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
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
  authorization_list*: seq[RlpAuthorization]

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

  # # This doesnt do the ssz encode/decode stuff so we keep it here for now to swap in later
  # AnyRlpTransaction* =
  #   RlpLegacyReplayableBasicTransaction | RlpLegacyReplayableCreateTransaction |
  #   RlpLegacyBasicTransaction | RlpLegacyCreateTransaction |
  #   RlpAccessListBasicTransaction | RlpAccessListCreateTransaction | RlpBasicTransaction |
  #   RlpCreateTransaction | RlpBlobTransaction | RlpSetCodeTransaction

type
  RLPTransactionKind* {.pure.} = enum
    txLegacyReplayableBasic
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

type
  TransactionKind* {.pure.} = enum
    TxNone
    RlpTransaction

  Transaction* = object
    case kind*: TransactionKind
    of TxNone:
      discard
    of RlpTransaction:
      rlp*: RlpTransactionObject
