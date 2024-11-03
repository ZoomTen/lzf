import unittest

from lzf import nil

test "Matching license text decompression":
  const
    decompressed = staticRead("../LICENSE")
    compressed = staticRead("LICENSE.lzf")

  let dc = lzf.decompress(compressed.toOpenArrayByte(0, len(compressed) - 1))

  check len(dc) == len(decompressed)

  for i in 0 ..< len(dc):
    check dc[i] == byte(decompressed[i])

test "Compress license text":
  skip()
  when false:
    const decompressedS = staticRead("../LICENSE")
    let decompressed = decompressedS
    var x = newSeq[byte](len(decompressed) * 2)
    let res = lzf.compress(
      cast[ptr byte](decompressed[0].addr), len(decompressed), x[0].addr, 1000
    )
    echo cast[seq[char]](decompressed).repr
    echo cast[seq[char]](x).repr
    check res == 0x37D

test "Not enough data for literal (missing argument)":
  expect lzf.IncompleteDataError:
    discard lzf.decompress(@[0'u8])

test "Not enough data for literal (off by one)":
  expect lzf.IncompleteDataError:
    discard lzf.decompress(@[0x04'u8, 0x10'u8, 0x10'u8, 0x10'u8, 0x10])

test "Not enough data for long backreference":
  expect lzf.IncompleteDataError:
    discard lzf.decompress(@[0b11100000'u8])
  expect lzf.IncompleteDataError:
    discard lzf.decompress(@[0b11100000'u8, 0'u8])

test "Not enough data for short backreference":
  expect lzf.IncompleteDataError:
    discard lzf.decompress(@[0b01000000'u8])

test "Long backreference offset is negative":
  expect lzf.BackreferenceError:
    discard lzf.decompress(@[0b11100000'u8, 0xff'u8, 0xff'u8])

test "Short backreference offset is negative":
  expect lzf.BackreferenceError:
    discard lzf.decompress(@[0b00111111'u8, 0b11111111'u8])

test "Copy short backreference out of bounds":
  let data: seq[byte] =
    @[0x04'u8, 0x50'u8, 0x50'u8, 0x50'u8, 0x50'u8, 0x50'u8] & # Initial data
    @[0b00100000'u8, 0x1'u8] # Short backref
  expect lzf.BackreferenceError:
    discard lzf.decompress(data)

test "Copy long backreference out of bounds":
  expect lzf.BackreferenceError:
    let data: seq[byte] =
      @[
        0x0a'u8, 0x50'u8, 0x50'u8, 0x50'u8, 0x50'u8, 0x50'u8, 0x50'u8, 0x50'u8, 0x50'u8,
        0x50'u8, 0x50'u8, 0x50'u8,
      ] & # Initial data
      @[0b11100000'u8, 0x00'u8, 0x05'u8] # Long backref
    discard lzf.decompress(data)
