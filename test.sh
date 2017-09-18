#!/bin/bash

# test all inputs against all keys

NUMTEST=0
FAILS=0
SCORE=0
SOURCEFILE="columnar.c"
DO_COMPILE=1
DO_CHECKSUMS=1
QUIT_ON_ERROR=0
PAD_ONLY=0
OPTIND=""
ENC="ENCODED"
DEC="DECODED"
GOLD="correct"
PADGOLD="padded"

usage()
{

cat <<TEXT
test.sh -- test your encoder/decoder
Options:
	-x	Skip compilation step.
	-q	Quit on any error.
	-h	Print this screen.
	-c	Skip checksums check.
	-p  Pad only (no encryption).

TEXT

exit 0

}

maybe_quit()
{
	if [[ $QUIT_ON_ERROR == 1 ]]
	then
		if [[ $PAD_ONLY == 1 ]]
		then
			echo "Note: 'pad only' mode was selected."
		fi
		exit 1
	fi

}

make_checksums()
{
	DIR=$1
	DATE=$(date -u +%s)
	TMP="$$.${DATE}.$RANDOM"
	echo "'$DIR'... "
	pushd $1 > /dev/null

	VERIFY="checksums/$DIR.verify"

	if [[ -f ../$VERIFY ]]
	then
		rm ../$VERIFY
	fi  

	for i in *
	do  
		md5sum $i >> "../$VERIFY"
	done

	# sort the file so that the order of the files
	# in the md5sum output won't matter
	sort ../$VERIFY > ../$VERIFY.$TMP
	mv ../$VERIFY.$TMP ../$VERIFY

	popd > /dev/null

	sort checksums/$DIR > checksums/$DIR.$TMP
	chmod u+w checksums/$DIR
	mv checksums/$DIR.$TMP checksums/$DIR
	chmod u-w checksums/$DIR

	if ! diff checksums/$DIR $VERIFY
	then
		echo
		echo "--------------------------------------------------"
		echo "                FATAL ERROR!"
		echo "--------------------------------------------------"
		echo "Files in $DIR do not match original test data!"
		echo "You should back up your encoder and decoder source"
		echo "code and re-extract the sample vectors tarball."
		echo "--------------------------------------------------"
		exit 1
	fi  
}

while getopts "xqhcp" OPTION
do
	case $OPTION in
		x)
			DO_COMPILE=0
			echo "Skipping compilation by request."
			;;
		q)
			QUIT_ON_ERROR=1
			echo "Will quit on any error."
			;;
		c)
			DO_CHECKSUMS=0
			echo "Skipping integrity check."
			;;
		p)
			PAD_ONLY=1
			echo "Attempting to perform 'padding only' (requires application support)"
			;;
		h)
			usage
			;;
	esac
done

if [[ $DO_CHECKSUMS == 1 ]]
then
	echo "Checking integrity of test data:"
	UNAME=$(uname)
	if [[ $UNAME == "Darwin" ]]
	then
		echo "It appears you are using a Mac/BSD."
		echo "This version of the md5 utility has an incompatible output."
		echo "Run these tests on a Linux computer, or disable integrity"
		echo "checking by running this script with the -c flag. See"
		echo "'./test.sh -h' or the README for more information."
		exit 1
	fi

	make_checksums input
	make_checksums correct
	make_checksums padded
	echo "Done."
fi

echo "Removing stale test data (if it exists)..."
rm $ENC/*
rm $DEC/*
rm -r log
echo "Creating folders..."
mkdir log
mkdir $ENC
mkdir $DEC

BANNED="strcpy strcat strtok sprintf vsprintf gets strlen"

# check source code for banned functions
echo "Checking for banned functions: $BANNED"
for bfunc in $BANNED
do 
	if grep -nE "\s${bfunc}\W" $SOURCEFILE &> /dev/null
	then
		echo "BANNED FUNCTION '$bfunc' DETECTED on line:"
		echo
		grep -nE "\s${bfunc}\W" $SOURCEFILE 
		echo
		echo "Remove all banned functions from your code and try again."
		exit 1
	else
		echo "$bfunc"
	fi
done

if grep -nE "\sfgets\W" $SOURCEFILE &> /dev/null
then
	echo 
	echo "WARNING: You almost certainly DO NOT want to use fgets() for this project!"
	echo "Try using something like fgetc() instead!"
	echo
	sleep 10
fi

# automatically recompile unless -x option selected
if [[ $DO_COMPILE == 1 ]]
then
	if [[ ! -f $SOURCEFILE ]]
	then
		echo "$SOURCEFILE does not exist!"
		MISSING=1
		echo "'$SOURCEFILE' is missing!"
		exit 1
	fi

	if ! gcc -g -std=c99 $SOURCEFILE -o encoder -D MODE=ENCODE
	then
		echo ":-< : Failed to compile encoder! Quitting."
		exit 1
	else 
		echo ":-D : encoder compiled!"
	fi
	
	if ! gcc -g -std=c99 $SOURCEFILE -o decoder -D MODE=DECODE
	then
		echo ":-< : Failed to compile decoder! Quitting."
		exit 1
	else
		echo ":-D : decoder compiled!"
	fi
fi

for FILEPATH in input/*
do
	FILENAME=${FILEPATH##input/} # get basename of file

	for DIM in $( seq 1 10)
	do

		for LOGFILE in log/encoder.log log/encoder.err log/decoder.log log/decoder.err
		do
			echo "----- testing $FILEPATH @ ${DIM}x${DIM} -----" >> $LOGFILE
		done

		# TEST ENCODING
		
		NUMTEST=$((NUMTEST + 1))

		if [[ $PAD_ONLY == 0 ]]
		then
			COMMAND="./encoder $DIM $FILEPATH $ENC/$DIM.$FILENAME"
		else 
			# optional fourth argument enables padding only
			COMMAND="./encoder $DIM $FILEPATH $ENC/$DIM.$FILENAME 1"
		fi

		if ! $COMMAND >> log/encoder.log 2>> log/encoder.err
		then
			echo ":-< : Encoder returned non-zero (crashed?) on $FILEPATH @ ${DIM}x${DIM}!"
			echo -e "\tCommand: $COMMAND"
			maybe_quit
		fi

		# compare the sample encoded version with your version

		# if we enabled "pad only" mode, then compare against the padded
		# version of the file, not the fully "encrypted" version of the file
		if [[ $PAD_ONLY == 0 ]]
		then
			EXEMPLAR="$GOLD/$DIM.$FILENAME"
		else
			# padding only -- check padded version
			EXEMPLAR="$PADGOLD/$DIM.$FILENAME"
		fi

		if ! diff $EXEMPLAR $ENC/$DIM.$FILENAME &> /dev/null
		then
			echo
			echo ":-( : Encoded file $ENC/$DIM.$FILENAME != $EXEMPLAR!"
			echo -e "\tCommand: $COMMAND"
			echo
			maybe_quit

			FAILS=$((FAILS + 1))
		else 
			echo ":-D : Encoded $FILEPATH @ ${DIM}x${DIM} matches sample. "
		fi

		# TEST DECODING
		
		NUMTEST=$((NUMTEST + 1))

		if [[ $PAD_ONLY == 0 ]]
		then
			COMMAND="./decoder $DIM $ENC/$DIM.$FILENAME $DEC/$DIM.$FILENAME"
		else
			# optional fourth argument enables padding only
			COMMAND="./decoder $DIM $ENC/$DIM.$FILENAME $DEC/$DIM.$FILENAME 1"
		fi

		if ! $COMMAND >> log/decoder.log 2>> log/decoder.err
		then
			echo ":-< : Decoder returned non-zero (crashed?) on $FILEPATH @ ${DIM}x${DIM}!"
			echo -e "\tCommand: $COMMAND"
			maybe_quit
		fi
		# compare the sample decoded version with your decoding
		if ! diff input/$FILENAME $DEC/$DIM.$FILENAME &> /dev/null
		then

			echo
			echo ":-( : Decoded file $DEC/$DIM.$FILENAME != input/$FILENAME!"
			echo -e "Command: \t$COMMAND"
			echo 

			maybe_quit
			FAILS=$((FAILS + 1))
		else
			echo ":-D : Decoded $FILEPATH @ ${DIM}x${DIM} matches original."
		fi

	done

done

SCORE=$((NUMTEST - FAILS))
echo "You passed $SCORE out of $NUMTEST sample tests."

if [[ $PAD_ONLY == 1 ]]
then
	echo "Note: 'pad only' mode was selected."
fi
