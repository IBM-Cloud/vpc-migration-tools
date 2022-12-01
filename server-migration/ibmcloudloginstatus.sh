#!/bin/bash
start=$(date +'%Y-%m-%d %H:%M:%S')
current=$(date +'%Y-%m-%d %H:%M:%S')

A_TS=$(date -d "$start" +%s)
B_TS=$(date -d "$current" +%s)
DIFF=$((B_TS-A_TS))
deletetime="02"
timenow="00"
while [[ "$timenow" != "$deletetime" ]]
do
	sleep 1m
	current=$(date +'%Y-%m-%d %H:%M:%S')
	B_TS=$(date -d "$current" +%s)
	DIFF=$((B_TS-A_TS))
	#TZ=UTC date -d @$DIFF +%H:%M:%S
	timenow=`TZ=UTC date -d @$DIFF +%H`
	echo $timenow
done

rm $0

