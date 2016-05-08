#!/usr/bin/env python3

# Dirty script running some plain text replacements for broken encodings.
# Usage: fix=broken-encoding.py <file to fix> <encoding to read file> > output.txt

import sys

contents = open(sys.argv[1], 'r', encoding=sys.argv[2]).read()

replacements = {
	u'Ã ': u'à',
	u'Ã¢': u'â',
	u'Ã€': u'À',
	u'Ã§': u'ç',
	u'Ã‡': u'Ç',
	u'Ã©': u'é',
	u'Ã¨': u'è',
	u'Ãª': u'ê',
	u'Ã‰': u'É',
	u'Ãˆ': u'È',
	u'Ã®': u'î',
	u'Ã¯': u'ï',
	u'Ã±': u'ñ',
	u'Ã´': u'ô',
	u'Ã¹': u'ù',
	u'Ã»': u'û',
}

for target, replacement in replacements.items():
	contents = contents.replace(target, replacement)

print(contents)
