#!/bin/bash
# INIT functionality

# check that .legit directory is created
rm -rd ".legit"
./legit.pl init > /dev/null 2>&1

if [ -e ".legit" ]
then
	echo "Init: Succeed to create a new .legit directory"
else
	echo "Init: Failed to create a new .legit directory"
	exit 1
fi

print=$(perl legit.pl init 2>&1)
mes=$"legit.pl: error: .legit already exists"
if [ [ "$mes" eq $print ] ]
then
	echo "Init: Succeed to spot existed init"
else
	echo "Init: Failed to spot existed init"
	exit 1
fi

exit 0
