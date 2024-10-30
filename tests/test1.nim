import unittest

from lzf import nil

test "Matching license text decompression":
  const
    decompressed = staticRead("../LICENSE")
    compressed = staticRead("LICENSE.lzf")

  let dc = lzf.decompress(n[4 .. ^1], 0x37D)
  check dc == decompressed
