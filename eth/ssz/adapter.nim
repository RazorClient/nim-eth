# eth
# Copyright (c) 2024-2026 Status Research & Development GmbH
# Licensed and distributed under either of
#   * MIT license (license terms in the root directory or at https://opensource.org/licenses/MIT).
#   * Apache v2 license (license terms in the root directory or at https://www.apache.org/licenses/LICENSE-2.0).
# at your option. This file may not be copied, modified, or distributed except according to those terms.

import
  ../common/[addresses, hashes, base],
  std/typetraits,
  ssz_serialization,
  ssz_serialization/codec,
  ssz_serialization/merkleization

export ssz_serialization, codec, base, typetraits

# Generic SSZ adapter for distinct array types
template defineSszAdapter(T: typedesc) =
  template toSszType*(x: T): auto =
    distinctBase(x)

  func fromSszBytes*(Ty: type T, bytes: openArray[byte]): Ty {.raises: [SszError].} =
    readSszValue(bytes, distinctBase(result))

defineSszAdapter(Address)
defineSszAdapter(Hash32)
defineSszAdapter(Bytes32)
