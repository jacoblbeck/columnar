SAMPLE VECTORS FOR COLUMNAR LAB
-------------------------------

INTRODUCTION
------------

This archive contains sample input, keys, output and TWO testing
scripts.  'test'.sh' performs encoding/decoding for each input and
grid size combination and 'padtest.sh' tests padding only enciphering
(no transposition) for compatible encoders and decoders (see below).

The scripts test.sh and padtest.sh use the following directories:

Contents:
	input/		-- sample inputs
	correct/	-- correctly encoded inputs with dims 1-10
	padded/		-- correctly padded inputs with dims 1-10
	ENCODED/	-- YOUR encoder's output files are put here
	DECODED/	-- YOUR decoder's output files are put here
	log/		-- program stdin and stderr from your encoder/decoder
	test.sh		-- runs full tests

INSTRUCTIONS FOR TEST.SH
------------------------

Copy your encoder.c and decoder.c files into this directory. Run
'./test.sh'. This will compile encoder.c and decoder.c and run all
combinations of inputs and dimensions. Encoded data is written into
ENCODED/ and compared against the correct version in correct/. Decoded
data is written into DECODED/ and compared against the original input
in input/.  Standard output and error for your programs are written to
files in log/.

Successes and failures are counted and results are printed at the end.

Options:

	-x Skip compilation step. This does not compile your source code, but
	   expects that the files 'encoder' and 'decoder' already exist.
	   
	-q Quit on any error. This quits when the first error is encountered,
	   rather than giving a cumulative score after running all tests. Since 
	   the full test can get rather spammy, this is a way of isolating and 
	   debugging failures one at a time.
	   
	-h Prints the help screen.
	
	-c Skip checksums check. Buggy code or mistakes COULD result in the
	   corruption of the test files, which would in turn result in an obtuse
	   sequence of hard to debug failures. test.sh normally double checks the
	   'input', 'correct', and 'padded' directories to make sure that this
	   test data has not been corrupted. You can disable this check if you 
	   want to, for example, to test additional inputs that you add. I don't
	   advise it, however.
	   
	-p Pad only (no encryption). This switch will compare the output of
	   'encoder' to the padded-but-unencrypted data in 'padded', so you can 
	   test that your padding code works properly separately from your
	   transposition code. Using this switch will also give 'encoder' 
	   and 'decoder' a fourth argument, '1' to enable this behavior in 
	   your code. For -p to work, your code must either have no functioning
	   transposition code, or you must accept the fourth parameter as a 
	   switch to disable transposition. (See below for more info.)
	   
PADDING CORRECTNESS
-------------------

To help you check whether you are performing padding correctly, the
files in the directory padded/ are correctly padded examples of the
input/ files, using the dimensions as specified in the filename. For
example, the file 'padded/6.12_abe.jpg' is the padded version of the
input file '12_abe.jpg' when padded using a dimension of 6 is used (a
block size of 36 bytes). 

To use these files, comment out your transposition code, or add a
"padding only mode" to your encoder and decoder (so that you can
enable/disable transposition on the command line -- see below for more
information). Then, you can "encode" input without transposition,
which you can compare to the correct examples in padded/. (You can
also test the "unpadding" of data by decoding padded output with
transposition disabled.)

In addition to examining files with cat, less, hexedit, or another
editor, you can also use the program 'diff' to tell you if two files
differ. Use it like this:

diff file1 file2

'diff' only prints differences between input files. Therefore, if the
two files match, diff will print nothing.

Another excellent tool is 'hexdiff', which displayes the hexadecimal 
and ASCII data side by side.

PADTEST.SH: OPTIONAL AUTOMATED PADDING TEST
-------------------------------------------

If you modify your encoder and decoder to accept an optional
fourth argument of '1' to mean "no transposition" (see below), the
script test.sh with the option -p will test your padding code by 
performing the same kind of automated tests as performed by test.sh. 
That is, padtest.sh will "pad" all inputs with all block sizes and 
compare your results against those in padded/ and, of course, 
whether the unpadded versions match the originals.

These tests will NOT be graded, but testing your padding code before
you test padding and transposition together may make your development
and debugging process easier. It certainly helped me.

To use "padding only" mode, your encoder and decoder MUST be able to 
accept a fourth argument with value '1' to disable transposition. So, 
running:

./encoder 4 input output 1

... would, using a blocksize of 16, pad the input and write it into
the file output -- WITHOUT transposing it. Similarly, the command:

./decoder 4 output decoded 1

... would, also using a blocksize of 16, remove the padding from the
file output and write the unpadded data to the file decoded -- with no
transposition. The switch value MUST be 1, and your encoder and
decoder must ALSO work *without* this optional value (or the graded
test.sh will not function properly).

Successes and failures are counted and results are printed at the end.

QUESTIONS / PROBLEMS?
---------------------

Contact your instructor or TA immediately!
