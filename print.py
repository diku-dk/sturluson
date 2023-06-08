#!/usr/bin/env python3
#
# If stdin is a single array whose byte representation can be decoded
# as UTF-8, print the corresponding string.  Otherwise just pass
# stdin.

import futhark_data
import string
import sys

def to_string(v):
    try:
        return v.tobytes().decode('utf-8')
    except:
        pass
    return None

inp = sys.stdin.read()
try:
    s = next(futhark_data.loads(inp)).astype('byte').tobytes().decode('utf-8')
    assert(all(c in string.printable for c in s))
    print(s)
except:
    print(inp, end='')
