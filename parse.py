#!/usr/bin/python

import re
import sys
import math 

def calculate_statistics(trace, node1, node2):
	total_sent_packets=0
	total_ackd_packets=0
	total_dropped_packets=0;
	seqno_dict={}
	subset=[]
	ack_window=0
	total_delay=0

	for line in trace:
		if (re.match("^\+.* " + str(node1) + " 1 tcp.* [0-9]*[' ''\n'].*", line)): 
			seqno_dict[int(line.rsplit(" ",1)[1])] = float(line.split()[1]);
			total_sent_packets += 1;

	trace.seek(0);
	for line in trace:
		if (re.match("^r.* 1 " + str(node1) + " ack.* [0-9]*[' ''\n'].*", line)):
			subset.append(line);
			while ack_window < int(line.rsplit(" ",1)[1]):
				try: 
					seqno_dict[ack_window] = float(line.split()[1]) - seqno_dict[ack_window]
				except KeyError:
					ack_window += 1;
					continue; 
				if seqno_dict[ack_window] < 0:
					continue;
				total_delay += seqno_dict[ack_window];
				ack_window += 1;
				total_ackd_packets += 1;

	trace.seek(0);
	for line in trace:
		if (re.match("^d.* [a|t]c[k|p].*[" + str(node1) + str(node2) + "].0 [" + str(node1) + str(node2) +"].0 .*" , line)):
			total_dropped_packets += 1;

	print "\n"
	print "Total Packets sent:      %d" % total_sent_packets;
	print "Total Ack'd Packets:     %d" % total_ackd_packets;
	print "\n"
	print "Throughput:              %f Mbps" % float((total_sent_packets*500*8)/(150 * math.pow(10,6)));
	print "Total dropped packets:   %f per/sec" % float(total_dropped_packets/150.0);
	print "Average Latency:         %f ms" % float(float(total_delay/total_ackd_packets) * math.pow(10,3));
	print "Packet Drop Rate:        %f percent" % float(float(total_dropped_packets)/float(total_sent_packets) * 100);
	print "\n"

def main(argv):
	if len(argv) != 4:
		print "Usage: python pasrse.py <tracefilename> <tcp-source-node-id> <tcp-destn-node-id>"
		return

	trace = open(argv[1], 'r');
	node1 = argv[2]
	node2 = argv[3]

	calculate_statistics(trace, node1, node2);

if __name__ == "__main__":
    main(sys.argv)
