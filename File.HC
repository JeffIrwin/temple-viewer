
$ID,2$$WW,1$/* These are helper functions for opening and closing files and parsing strings and binary data */

//================================

Bool IsNewline(U8 c)
{$ID,2$
return (
    c == '\n' ||
    c == '\r' ||
    c == '\f');
$ID,-2$}

Bool IsWS(U8 c)
{$ID,2$
/* Is c whitespace?
  
   Does not check exotic chars like vertical tab
*/
return (IsNewline(c) ||
    c == ' '  ||
    c == '\t');
$ID,-2$}

U0 SkipWS(U8** ss, U8** se)
{$ID,2$
U8* p = *ss;
while (IsWS(*p) && p < *se)
  p++;
*ss = p;
$ID,-2$}

//================================

class File
{$ID,2$
U8* data;
U8* p;  // pointer to read head
I64 len;
Bool eof;
$ID,-2$};

U0 FileOpen(U8* fname, File* f)
{$ID,2$
//"Opening %s\n", fname;
f->data = FileRead(fname, &f->len);
f->p = f->data;

f->eof = (f->len <= 0);

//"File size = %d B\n", f->len;
$ID,-2$}

U0 FileRewind(File* f)
{$ID,2$
// Rewind to start of file
f->p = f->data;
f->eof = (f->len <= 0);
$ID,-2$}

I64 FileClose(File* f)
{$ID,2$
//"Closing file\n";
Free(f->data);
f->len = 0;
f->eof = TRUE;
return 0;
$ID,-2$}

U0 FileGetLine(File* f, U8** ls, U8** le)
{$ID,2$
/* Read the next line of file f.

   Return pointers to the start ls and end le of the line
*/

// Line start
*ls = f->p;

// End of file
U8* endp = f->data + f->len;

U8* p = f->p;
while (!IsNewline(*p) && p < endp)
  p++;

while ( IsNewline(*p) && p < endp)
  p++;

f->p = p;

// Line end
*le = f->p;

I64 remain = endp - p;
//"remain = %d\n", remain;

f->eof = (remain <= 0);

//"gl %d\n", *le - *ls;
$ID,-2$}

U0 PrintLine(U8* str, U8* endp)
{$ID,2$
U8* p = str;
while (p < endp)
  "%c", *p++;
$ID,-2$}

F64 FileReadF32(File* file)
{$ID,2$
/* Read a 32 bit float from a binary file.  Since F32 is not implemented in HolyC, convert and return F64 instead.  This does not handle special floats like Inf or NaN correctly.

   The table below shows the bit layout of the IEEE 754 float (top) and double (bottom):

   | sign | exponent  | fraction |
   |------|-----------|----------|
   | 31   | 30 <-> 23 | 22 <-> 0 |
   | 63   | 62 <-> 52 | 51 <-> 0 |
*/

// Return val
F64 x;

// Pointer to bits in file
U32* p; // works as I32 too
p = file->p;
file->p += sizeof(U32);
//"p = %x\n", *p;
//"p = %032b\n", *p;

file->eof = (file->data + file->len - file->p <= 0);

// Initialize bits to 0 by aliasing an int
U64* ix = &x;
*ix = 0;

/* Copy the float sign (bit 31) to the double sign (bit 64) */
x |= (*p >> 31) << 63;

/* Exponent.  Right shifting discards the fraction bits right of the expo, while anding with 0xff discards the sign bit left of the expo.  127 and 1023 are the float and double biases.  Finally, left shift the result by 52 to place the expo correctly in the double bits. */
x |= ((0xff & (*p >> 23)) - 127 + 1023) << 52;

// Fraction
x |= (0x7fffff & *p) << (51 - 22);

//"x = %064b\n", x;
//"x = %e\n", x;
//"\n";

return x;
$ID,-2$}

//================================
$ID,-2$