# -*- coding: utf-8 -*-

#
# Crudely and inefficiently deduplicate vcard files
# Not suitable for serious business, this is just a one-off scripts
#
#     Usage:
#         $ cat vcard1.vcf vcard2.vcf ... | python2 vcard-dedup.py > result.vcf
#

import re
import sys

vcard = re.compile(u'^BEGIN:VCARD([\\s\\S]+?)^END:VCARD', re.MULTILINE)
fieldReg = re.compile(u'^([^:;\\s]+)((?:;[^:;\\s]+)*):(.*(?:[\r\n]+ +.*)*)', re.MULTILINE)
def getFields(v):
	fields = []
	for f in fieldReg.findall(v):
		value = []
		for val in u''.join(map(lambda x: x.strip(), f[2].split(u'\n'))).split(u';'):
			if val.strip():
				value.append(val.replace(u'\\:', u':'))
		fields.append((f[0], f[1], value))
	return fields

def printFields(fields):
	lines = [u'BEGIN:VCARD']
	for f in fields:
		lines.append(f[0] + f[1] + u':' + u';'.join(f[2]))
		while len(lines[-1]) > 76:
			lines = lines[:-1] + [lines[-1][:76], u' ' + lines[-1][76:]]
	lines.append(u'END:VCARD')
	return u'\n'.join(lines)

def getFieldsOf(fields, fieldName, asTuple):
	matchingFields = []
	for f in fields:
		if f[0].lower() == fieldName.lower():
			if asTuple:
				matchingFields.append(f)
			else:
				matchingFields.extend(f[2])
	return matchingFields

def m(v):
	f = getFields(v)
	email = getFieldsOf(f, 'email', False)
	FN = getFieldsOf(f, 'FN', False)
	N = getFieldsOf(f, 'N', False)
	if len(FN) == 0 and len(N) > 0:
		FN = [u' '.join(N)]
	return set(email), set(FN)
vcards = vcard.findall(sys.stdin.read().decode('utf8'))
vFields = map(m, vcards)
toMerge = []
taken = set()
for i, vf1 in enumerate(vFields):
	if i in taken:
		continue
	taken.add(i)
	matches = [vcards[i]]
	for j, vf2 in enumerate(vFields):
		if j not in taken and (len(vf1[0] & vf2[0]) or len(vf1[1] & vf2[1])):
			taken.add(j)
			matches.append(vcards[j])
	if len(matches) > 1:
		toMerge.append(matches)
output = u''
valueSplit = re.compile(u'[-;:,._*(){}[\\]\\s]+')
for m in toMerge:
	allFields = []
	for v in m:
		allFields.extend(getFields(v))
	fieldNames = list(set(map(lambda x: x[0], allFields)))
	fieldNames.sort()
	if u'VERSION' in fieldNames: # Move VERSION to first field
		fieldNames.remove(u'VERSION')
		fieldNames.insert(0, u'VERSION')
	finalFields = []
	for fn in fieldNames:
		fs = getFieldsOf(allFields, fn, True)
		uniqueValues = set(map(lambda x: u';'.join(x[2]), fs))
		# Dedup values
		filteredValues = []
		for v1 in uniqueValues:
			v1Split = valueSplit.split(v1.lower())
			isUnique = True
			for v2 in filteredValues[:]:
				v2Split = valueSplit.split(v2.lower())
				isUnique = False
				fullCoverage = True
				isSuperset = True
				for c1 in v1Split:
					if c1 not in v2Split:
						fullCoverage = False
						isUnique = True
						break
				if not fullCoverage:
					for c2 in v2Split:
						if c2 not in v1Split:
							isSuperset = False
							break
					if isSuperset:
						filteredValues.remove(v2)
						filteredValues.append(v1)
			if isUnique:
				filteredValues.append(v1)
		for v in filteredValues:
			if v.strip():
				matchingFields = filter(lambda x: u';'.join(x[2]) == v, fs)
				matchingTypes = list(set(map(lambda x: x[1], matchingFields)))
				matchingTypes.sort(key=lambda x: len(x))
				chosenType = matchingTypes[-1]
				chosenField = filter(lambda x: x[1] == chosenType, matchingFields)[0]
				finalFields.append((fn, chosenType, chosenField[2]))
	output += printFields(finalFields) + u'\n'
print output.encode('utf8')
