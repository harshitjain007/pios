#!/bin/sh

qemuopts="-hda obj/kern/kernel.img"
. ./grade-functions.sh


$make
run

score=0

pts=10; greptest "1a Printf:    " "1234 decimal is 2322 octal!"
pts=15; greptest "1b Backtrace: " "debug_check() succeeded!"
pts=25; greptest "2  Traps:     " "trap_check_kernel() succeeded!"
pts=25; greptest "3  User mode: " "trap_check_user() succeeded!"
pts=25; greptest "4  Memory:    " "mem_check() succeeded!"

echo "Total Score: $score/100"
maxmarks=10
final=$(echo "$score/$maxmarks" |bc)
echo "Total Marks: $final ($score% of $maxmarks)" 

if [ $score -lt 100 ]; then
    exit 1
fi
