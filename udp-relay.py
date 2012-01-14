#!/usr/bin/env python
# Super simple script that listens to a local UDP port and relays all packets to an arbitrary remote host.
# Packets that the host sends back will also be relayed to the local UDP client.
# Works with Python 2 and 3

import sys, socket

def fail(reason):
	sys.stderr.write(reason + '\n')
	sys.exit(1)

if len(sys.argv) != 2 or len(sys.argv[1].split(':')) != 3:
	fail('Usage: udp-relay.py localPort:remoteHost:remotePort')

localPort, remoteHost, remotePort = sys.argv[1].split(':')

try:
	localPort = int(localPort)
except:
	fail('Invalid port number: ' + str(localPort))
try:
	localPort = int(remotePort)
except:
	fail('Invalid port number: ' + str(remotePort))

try:
	s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
	s.bind(('', localPort))
except:
	fail('Failed to bind on port ' + str(localPort))

knownClient = None
knownServer = (remoteHost, remotePort)
sys.stderr.write('All set.\n')
while True:
	data, addr = s.recvfrom(32768)
	if knownClient is None:
		knownClient = addr
	if addr == knownClient:
		s.sendto(data, knownServer)
	else:
		s.sendto(data, knownClient)
