#!/usr/bin/env python
# Horizontally mirrors a SpokePOV .dat file.
# Useful if you want to use the "mirror" option on the SpokePOV software but SpokePOV units
# are installed "backwards" because they fit your spokes better that way.
# http://www.ladyada.net/make/spokepov/software.html
# SpokePOV .dat file format info from https://github.com/adafruit/SpokePOV/blob/d4acac8cdfe3663d2b01fa4280da7d41ca80fedb/wheelpanel.cpp#L132

import struct, sys

if len(sys.argv) != 2:
	print('Usage: spokepov-mirror.py filename.dat')
	print('Writes result to filename_flipped.dat')
	sys.exit(1)

contents = open(sys.argv[1], 'rb').read(-1)
newcontents = b''

# Magic header
if contents[:12] != b'\x08\x00\x00\x00SpokePOV':
	print('Invalid SpokePOV file.')
	sys.exit(1)
newcontents += contents[:12]
contents = contents[12:]

# Format version
if contents[:2] != b'\x01\x02':
	print('Invalid SpokePOV file version.')
	sys.exit(1)
newcontents += contents[:2]
contents = contents[2:]

# Radial image dimensions
# leds = Number of LEDs on each SpokePOV unit
# pixels = Number of pixels in one rotation per LED
leds, pixels = struct.unpack('=BH', contents[:3])
print('LEDs: %d / Pixels: %d' % (leds, pixels))
newcontents += contents[:3]
contents = contents[3:]

# Do the actual mirroring
for led in range(leds):
	led_offset = led * pixels
	newcontents += contents[led_offset + pixels:led_offset:-1]

output = sys.argv[1][:-4] + '_flipped.dat'
open(output, 'wb').write(newcontents)
