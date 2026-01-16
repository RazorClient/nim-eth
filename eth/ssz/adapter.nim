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
