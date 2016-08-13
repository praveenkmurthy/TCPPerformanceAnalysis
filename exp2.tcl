set ns [new Simulator]

set tf [open trace w]
$ns trace-all $tf

#set nf [open out.nam w]
#$ns namtrace-all $nf

proc finish {} {
        global ns tf
        $ns flush-trace
        #close $nf
		close $tf
        exit 0
}

Agent/TCP instproc done {} {
	global ns
	set duration [expr [$ns now] - [$self set starts]]
	puts "[$self set node] \t [$self set sess] \t [$self set starts] \t \
		[$ns now] \t $duration \t [$self set ndatapack_] \t \
		[$self set ndatabytes_] \t [$self set nrexmitbytes_] \t\
		[expr [$self set ndatabytes_]/$duration]"
}

set NumNodes 6

if {$argc != 3} {
	puts stderr "Error! Insufficient arguments"
	exit 1
}

for {set index 1} {$index <= $NumNodes} {incr index} {
	set n($index) [$ns node]
}

for {set index 1} {$index <= [expr ($NumNodes-2)]} {incr index} {
	$ns duplex-link $n($index) $n([expr ($index+1)]) 10Mb 0.1ms DropTail
}

$ns duplex-link $n(2) $n(5) 10Mb 1ms DropTail
$ns duplex-link $n(3) $n(6) 10Mb 1ms DropTail

# Create a UDP agent and attach it to node n(2)
set udp1 [new Agent/UDP]
$ns attach-agent $n(2) $udp1

# Create a CBR traffic source and attach it to udp1
set cbr1 [new Application/Traffic/CBR]
$cbr1 set packetSize_ 1000
$cbr1 set rate_ [lindex $argv 2]Mb
$cbr1 attach-agent $udp1

set null1 [new Agent/Null] 
$ns attach-agent $n(3) $null1
$ns connect $udp1 $null1

# Create a TCP Agent & attach it to node n(1)
set tcp1 [new [lindex $argv 0]]
$tcp1 set starts 5 
$tcp1 set node 1
$tcp1 set sess 1
$ns attach-agent $n(1) $tcp1

# Create a TCP Sink on node n(4)
set sink1 [new Agent/TCPSink]
$ns attach-agent $n(4) $sink1
$ns connect $tcp1 $sink1
$tcp1 set packetSize_ 500

# Create a FTP source and attach it to tcp1
set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1

set null1 [new Agent/Null] 
$ns attach-agent $n(3) $null1

# Create a TCP Agent & attach it to node n(1)
set tcp2 [new [lindex $argv 1]]
$tcp2 set starts 5
$tcp2 set node 5
$tcp2 set sess 1
$ns attach-agent $n(5) $tcp2

# Create a TCP Sink on node n(6)
set sink2 [new Agent/TCPSink]
$ns attach-agent $n(6) $sink2
$ns connect $tcp2 $sink2
$tcp1 set packetSize_ 500

# Create a FTP source and attach it to tcp1
set ftp2 [new Application/FTP]
$ftp2 attach-agent $tcp2

$ns at 0.5 "$cbr1 start"
$ns at 5 "$ftp1 send 500000000"
$ns at 5 "$ftp2 send 500000000"
$ns at 155 "$ftp1 stop"
$ns at 155 "$ftp2 stop"
$ns at 159.5 "$cbr1 stop"
$ns at 160.0 "finish"

$ns run
