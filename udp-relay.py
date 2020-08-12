#!/usr/bin/env python
# Super simple script that listens to a local UDP port and relays all packets to an arbitrary remote host.
# Packets that the host sends back will also be relayed to the local UDP client.
# Works with Python 2 and 3

import sys, socket

# Whether or not to print the IP address and port of each packet received
debug=False

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
	remotePort = int(remotePort)
except:
	fail('Invalid port number: ' + str(remotePort))

try:
	s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
	s.bind(('', localPort))
except:
	fail('Failed to bind on port ' + str(localPort))

knownClient = None
knownServer = (remoteHost, remotePort)
sys.stdout.write('All set, listening on '+str(localPort)+'.\n')
while True:
	data, addr = s.recvfrom(32768)
	if knownClient is None or addr != knownServer:
		if debug:
			print("")
		knownClient = addr

	if debug:
		print("Packet received from "+str(addr))

	if addr == knownClient:
		if debug:
			print("\tforwording tO "+str(knownServer)) 

		s.sendto(data, knownServer)
	else:
		if debug:
			print("\tforwarding to "+str(knownClient))
		s.sendto(data, knownClient)
