import ./exceptions

type uint3 = 0b000 .. 0b111

{.push boundChecks: off, overflowChecks: off.}
func decompress*(data: openArray[byte]): seq[byte] =
  let dataLen = len(data)
  var index = 0

  while index < dataLen:
    var currentByte = data[index]
    inc index

    if currentByte <= 0b00011111:
      # a literal run of 1 to 32 bytes (encoded as 0 - 31)
      # off the input
      inc currentByte

      if dataLen < index + int(currentByte):
        # an out-of-bounds read indicates that the data in the array is not
        # complete. however Nim's default is to throw an uncatchable IndexDefect.
        # I think this case should be catchable with the usual mechanisms.
        raise newException(
          IncompleteDataError,
          "attempt to read data beyond amount stated in literal header [" & $index & "]",
        )

      for i in index ..< index + int(currentByte):
        result.add(data[i])
        index = i
      inc index
    else:
      # back reference, taken from the bytes already written
      # to the output.
      {.push rangeChecks: off.}
      # - currentByte is already a uint8
      # - cast to int required to shift right
      # - unsigned means it's zero extended rather than sign extended
      # = guaranteed to be uint3, type coercion is only for compile-time type check
      let backrefDeterminer: uint3 = (uint(currentByte) shr 5)
      {.pop.}

      case backrefDeterminer
      of 0b111:
        # long backref
        if index + 2 > dataLen:
          raise newException(
            IncompleteDataError,
            "missing required arguments for long backref [" & $index & "]",
          )

        let
          realLength = int(data[index]) + 9
          afterByte = data[index + 1]
          offset = ((int(currentByte) and 0b11111) shl 8) or int(afterByte)
          start = len(result) - offset - 1

        if start < 0:
          raise newException(
            BackreferenceError,
            "start position of backreference is negative [" & $index & "]",
          )

        if len(result) < start + realLength + 1:
          # if I use result.add for copying, it would repeat
          # the last element instead of overflowing, so it'd be
          # fine... but let's assume that it's invalid
          raise newException(
            BackreferenceError,
            "backreference copy would go out of bounds [" & $index & "]",
          )

        inc index, 2

        for i in start ..< start + realLength:
          result.add(result[i])
      else:
        # short backref
        if index + 1 > dataLen:
          raise newException(
            IncompleteDataError,
            "missing required arguments for short backref [" & $index & "]",
          )
        let
          nextByte = data[index]
          realLength = backrefDeterminer + 2
          # offset and start index refers to the *output*, not the *input*
          offset = ((int(currentByte) and 0b11111) shl 8) or int(nextByte)
          start = len(result) - offset - 1

        if start < 0:
          raise newException(
            BackreferenceError,
            "start position of backreference is negative [" & $index & "]",
          )

        if len(result) < start + realLength:
          raise newException(
            BackreferenceError,
            "backreference copy would go out of bounds [" & $index & "]",
          )

        inc index

        for i in start ..< start + realLength:
          result.add(result[i])
{.pop.}
