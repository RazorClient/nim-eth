# eth
# Copyright (c) 2024-2026 Status Research & Development GmbH
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at https://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at https://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

{.push raises: [].}

import stint, ../common/base

export base

type
  ExecutionSignatureAlgorithm* = uint8
  ProgressiveByteList* = seq[byte]
  ExecutionSignature* = ProgressiveByteList
  Secp256k1ExecutionSignature* = ExecutionSignature

const Secp256k1Algorithm*: ExecutionSignatureAlgorithm = 0xFF'u8

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
