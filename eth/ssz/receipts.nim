# Copyright (c) 2024-2026 Status Research & Development GmbH
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at https://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at https://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import ssz_serialization, ../common/[addresses, hashes], ./adapter, ./common_ssz

export common_ssz

const
  ReceiptTagBasic* = 0x01'u8
  ReceiptTagCreate* = 0x02'u8
  ReceiptTagSetCode* = 0x03'u8
  MaxTopicsPerLog* = 4

type
  Log* = object
    address*: Address
    topics*: seq[Hash32]
    data*: ProgressiveByteList

  ReceiptKind* {.pure.} = enum
    rkBasic = 0
    rkCreate
    rkSetCode

  BasicReceipt* {.sszActiveFields: [1, 1, 0, 1, 1].} = object
    `from`*: Address
    gas_used*: GasAmount
    logs*: seq[Log]
    status*: bool

  CreateReceipt* {.sszActiveFields: [1, 1, 1, 1, 1].} = object
    `from`*: Address
    gas_used*: GasAmount
    contract_address*: Address
    logs*: seq[Log]
    status*: bool

  SetCodeReceipt* {.sszActiveFields: [1, 1, 0, 1, 1, 1].} = object
    `from`*: Address
    gas_used*: GasAmount
    logs*: seq[Log]
    status*: bool
    authorities*: seq[Address]

  Receipt* = object
    case kind*: ReceiptKind
    of rkBasic:
      basic*: BasicReceipt
    of rkCreate:
      create*: CreateReceipt
    of rkSetCode:
      setCode*: SetCodeReceipt
