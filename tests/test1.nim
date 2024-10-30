import unittest

from lzf import nil

test "Matching license text decompression":
  const
    decompressed = staticRead("../LICENSE")
    compressed = staticRead("LICENSE.lzf")

  let dc = lzf.decompress(compressed.toOpenArrayByte(4, len(compressed) - 1), 0x37D)

  for i in 0 ..< min(len(dc), len(decompressed)):
    check dc[i] == byte(decompressed[i])
