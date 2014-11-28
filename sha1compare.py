#!/usr/bin/env python3

# Compares two files containing a bunch of sha1sums.
# Usage: file1 file1Prefix file2 file2Prefix
# Output is of the form "MESSAGETYPE:messageid: Message goes here", to allow for easy grepping.

import sys
import re
import shlex

def parseFile(f, prefix):
	prefix = bytes(prefix, 'utf8')
	sha1sums = {}
	for lineNumber, line in enumerate(open(f, 'rb').read().split(b'\n')):
		l = line.strip()
		if not l:
			continue
		l = l.split(b'  ', 1)
		if len(l) != 2 or len(l[0]) != 40 or any(c not in b'0123456789abcdef' for c in l[0]):
			print('WARNING:badsyntax: Invalid line %d of file %r: %r (ignoring)' % (lineNumber, f, line))
			continue
		if not l[1].startswith(prefix):
			print('WARNING:noprefix: File for line %d of file %r does not start with prefix %r (ignoring)' % (lineNumber, f, prefix))
			continue
		sha1sum = str(l[0], 'ascii')
		hashedFile = l[1][len(prefix):]
		try:
			utf8File = str(hashedFile, 'utf8')
		except UnicodeDecodeError:
			print('WARNING:notutf8: Filename on line %d of file %r cannot be decoded with UTF-8: %r (ignoring)' % (lineNumber, f, hashedFile))
			continue
		if utf8File in sha1sums:
			if sha1sums[utf8File] != sha1sum:
				print('ERROR:inconsistentsums: Hashed file %r of file %r is present more than once and with different hash values.' % (utf8File, f))
				sys.exit(1)
			print('INFO:dupline: Hashed file %r of file %r is present more than once, though with the same hash value. Ignoring.' % (utf8File, f))
		else:
			sha1sums[utf8File] = sha1sum
	return sha1sums

def cp(messageid, f1, f2):
	print('CMD:%s: %s' % (messageid, ' '.join(map(shlex.quote, ('cp', '-av', f1, f2)))))

f1, f2 = sys.argv[1], sys.argv[3]
prefix1, prefix2 = sys.argv[2], sys.argv[4]
sha1sums1 = parseFile(f1, prefix1)
sha1sums2 = parseFile(f2, prefix2)
for f in sorted(sha1sums1):
	if f not in sha1sums2:
		print('DIFF:in1not2: File %r is in %r but not %r' % (f, f1, f2))
		cp('in1not2', prefix1 + f, prefix2 + f)
	elif sha1sums1[f] != sha1sums2[f]:
		print('DIFF:mismatch: File %r is in both files but has different hash value' % (f,))
		cp('mismatch', prefix1 + f, prefix2 + f)
for f in sorted(sha1sums2):
	if f not in sha1sums1:
		print('DIFF:in2not1: File %r is in %r but not %r' % (f, f2, f1))
		cp('in2not1', prefix2 + f, prefix1 + f)
