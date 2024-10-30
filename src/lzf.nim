##
## A partial implementation of Marc Lehmann's liblzf in Nim.
##
## The format works like this:
##
## 000xxxxx <data ..>
##   Copy (n + 1) bytes of literal data immediately following the first byte,
##   where n is converted from a 5-bit binary number xxxxx
##
## XXXyyyyy yyyyyyyy
##   Copy (n + 1) bytes of data starting from (last output position) - (k + 1))
##   where n is converted from 3-bit XXX and k is converted from 13-bit
##   yyyyyyyyyyyyy
##
## 111yyyyy XXXXXXXX yyyyyyyy
##   Copy (n + 8) bytes of data starting from (last output position - (k + 1))
##   where n is converted from 8-bit XXXXXXXX and k is converted from 13-bit
##   yyyyyyyyyyyyy
##

func decompress*(data: openArray[byte], maxLength: Natural): seq[byte] =
  var index = 0
  while index < maxLength:
    var currentByte = data[index]
    inc index

    if currentByte <= 0b00011111:
      # a literal run of 1 to 32 bytes (encoded as 0 - 31)
      # off the input
      inc currentByte
      for i in index ..< index + int(currentByte):
        result.add(data[i])
        index = i
      inc index
    else:
      # back reference, taken from the bytes already written
      # to the output.
      let backrefDeterminer: 0b000 .. 0b111 = int(currentByte) shr 5
      case backrefDeterminer
      of 0b111:
        # long backref
        let
          realLength = int(data[index]) + 9
          afterByte = data[index + 1]
          offset = ((int(currentByte) and 0b11111) shl 8) or int(afterByte)
          start = len(result) - offset - 1

        inc index, 2

        for i in start ..< start + realLength:
          result.add(result[i])
      else:
        # short backref
        let
          nextByte = data[index]
          realLength = backrefDeterminer + 2
          # offset and start index refers to the *output*, not the *input*
          offset = ((int(currentByte) and 0b11111) shl 8) or int(nextByte)
          start = len(result) - offset - 1

        inc index

        for i in start ..< start + realLength:
          result.add(result[i])
