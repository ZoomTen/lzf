import ./exceptions

{.compile: "liblzf_og/lzf_c_best.c".}

proc lzf_compress_best(
  in_data: ptr byte, in_len: cuint, out_data: ptr byte, out_len: cuint
): cuint {.importc.}

proc compress*(data: openArray[byte]): seq[byte] =
  var temp = newSeq[byte](len(data) * 2)
  if (
    let finalLength =
      lzf_compress_best(data[0].addr, len(data).cuint, temp[0].addr, len(temp).cuint)
    finalLength > 0
  ):
    result = newSeq[byte](finalLength)
    for i in 0 ..< finalLength:
      result[i] = temp[i]
      # copyMem(result[0].addr, temp[0].addr, finalLength)
  else:
    raise newException(CompressionError, "unable to compress input data")
