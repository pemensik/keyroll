#!/bin/sh

DIG="dig +dnssec @localhost"
ROOTNS=204.42.252.20
DATE=$(date +'%Y-%m-%dT%H:%M:%S')

set -e

dig_simple()
{
	local FILE="$1"
	shift
	echo -n "$@: "
	$DIG $@ | tee "$FILE" | sed -e '/;; ->>HEADER<<-/ ! d' -e 's/.* status: \([A-Z]\+\),.*/\1/' 
}

mkdir "test-$DATE"
cd "test-$DATE"

echo $DATE
dig_simple root.current.dnskey @$ROOTNS +multiline -t DNSKEY .
dig_simple root.soa SOA .
dig_simple root.dnskey +multiline -t DNSKEY .
dig_simple root.txt -t TXT .
dig_simple root.a -t A ns.root.
dig_simple example.soa -t SOA example.
dig_simple example.dnskey +multiline DNSKEY
dig_simple example.a A ns.example.
dig_simple invalid.soa SOA invalid.
dig_simple invalid.dnskey +multiline -t DNSKEY invalid.
dig_simple invalid.a A ns.invalid.
