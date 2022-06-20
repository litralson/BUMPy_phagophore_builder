#!/bin/bash
start_file="PB_test_start"
echo $start_file".pdb"
folder="PB_test_files"
echo $folder

if [ $? -eq 0 ]; then
	echo 'Success'
else
	echo 'Failure :('
fi