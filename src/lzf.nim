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

import ./lzf/exceptions as exceptions
export exceptions

import ./lzf/decompress as decompress
export decompress.decompress
