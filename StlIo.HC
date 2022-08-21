
$ID,2$$WW,0$$WW,1$/* This contains functions for reading and writing STL files.  For now, only reading is supported. */

#include "File"

//================================

class Stl
{$ID,2$
/* Stereolithography file struct */

// Number of vertices
I64 nv;

/* Vertex coordinates, size 3 * nv.  Every 3 vertices (9 array elems) make a triangle.  There is no vertex equivalencing */
F64* v;

// Bounding box
F64 xmin, xmax,
    ymin, ymax,
    zmin, zmax;

// Center (midpoint of box)
F64 cx, cy, cz;

// Radius (center to corner)
F64 r;
$ID,-2$};

//================================

U0 StlFree(Stl* s)
{$ID,2$
//"Freeing STL ...\n";
//"&v = %x\n", s->v;
Free(s->v);
s->nv = 0;
$ID,-2$}

//================================

I64 StlGetBounds(Stl* s)
{$ID,2$
/* Get bounds and related info for an Stl s */

// Initialize bounds at first vertex
s->xmin = s->v[0];
s->ymin = s->v[1];
s->zmin = s->v[2];

s->xmax = s->xmin;
s->ymax = s->ymin;
s->zmax = s->zmin;

// Loop through remaining vertices
I64 i;
for (i = 3; i < 3 * s->nv; i += 3)
{$ID,2$
s->xmin = Min(s->xmin, s->v[i+0]);
s->ymin = Min(s->ymin, s->v[i+1]);
s->zmin = Min(s->zmin, s->v[i+2]);

s->xmax = Max(s->xmax, s->v[i+0]);
s->ymax = Max(s->ymax, s->v[i+1]);
s->zmax = Max(s->zmax, s->v[i+2]);
$ID,-2$}

"x in [%e, %e]\n", s->xmin, s->xmax;
"y in [%e, %e]\n", s->ymin, s->ymax;
"z in [%e, %e]\n", s->zmin, s->zmax;
"\n";

s->cx = 0.5 * (s->xmin + s->xmax);
s->cy = 0.5 * (s->ymin + s->ymax);
s->cz = 0.5 * (s->zmin + $WW,1$s->zmax);

/*"Center = %9.6f %9.6f %9.6f\n",
    s->cx,
    s->cy,
    s->cz;
*/
s->r = 0.5 * Sqrt(
    Sqr(s->xmax - s->xmin) +
    Sqr(s->ymax - s->ymin) +
    Sqr(s->zmax - s->zmin));

//"Radius = %9.6f\n", s->r;

return 0;
$ID,-2$}

//================================

I64 StlLoadAscii(U8* fstl, Stl* s)
{$ID,2$
/* Read an ASCII STL file named fstl.

   Set Stl out arg s.
*/

//"\nReading \"%s\" ...\n\n", fstl;

File f;
FileOpen(fstl, &f);
if (f.eof)
{$ID,2$
PrintErr("File not found or empty\n\n");
return -1;
$ID,-2$}

//"len = %d\n", f.len;

/* Pointers to start and end of line */
U8* ls;
U8* le;

U8* VrtId = "vertex";

// Count vertices nv
s->nv = 0;
I64 nlines = 0;
while (!f.eof)
{$ID,2$
FileGetLine(&f, &ls, &le);
nlines++;

SkipWS(&ls, &le);

//"%d\n", f->eof;
/*if (nlines > 66058) PrintLine(ls, le);*/
/*if (nlines < 10) PrintLine(ls, le);*/

/* Case-insensitive str comparison */
if (StrNICmp(ls, VrtId, StrLen(VrtId)) == 0)
  s->nv++;
$ID,-2$}

if (s->nv <= 0)
{$ID,2$
FileClose(&f);
return -1;
$ID,-2$}

/*"Number of lines = %d\n", nlines;*/
"Number of verts = %d\n", s->nv;
"\n";

/* 3 dimensions, 8 bytes.  MAlloc uses 1-byte units */
s->v = MAlloc(3 * s->nv * sizeof(F64));

//"&v = %x\n", s->v;

// Re-read and save vertices v
FileRewind(&f);
I64 i = 0;
while (!f.eof)
{$ID,2$
//"%d\n", i;
FileGetLine(&f, &ls, &le);
SkipWS(&ls, &le);

if (StrNICmp(ls, VrtId, StrLen(VrtId)) == 0)
{$ID,2$
/*if (i < 10) PrintLine(ls, le);*/

/* Skip to the end of the "vertex" str */
ls += StrLen(VrtId);

/* Pointer to end of Str2F64 read */
U8* p;

/* Read 3 coordinates (x, y, and z) */
s->v[i++] = Str2F64(ls, &p); ls = p;
s->v[i++] = Str2F64(ls, &p); ls = p;
s->v[i++] = Str2F64(ls, &p); ls = p;
$ID,-2$}
$ID,-2$}
FileClose(&f);

return 0;
$ID,-2$}

//================================

I64 StlLoadBin(U8* fstl, Stl* s)
{$ID,2$
/* Read a binary STL file named fstl.

   Set Stl out arg s.
*/

//"\nReading \"%s\" ...\n\n", fstl;

File f;
FileOpen(fstl, &f);
if (f.eof)
{$ID,2$
PrintErr("File not found or empty\n\n");
return -1;
$ID,-2$}

//"len = %d\n", f.len;

/* Pointers to start and end of line */
U8* ls;
U8* le;

I64 hlen = 80;
ls = f.data;
le = ls + hlen;
f.p += hlen;

"STL header = \"";
PrintLine(ls, le);
"\"\n";

U32* ntri;
ntri = f.p;
f.p += sizeof(U32);
//"ntri = %d\n\n", *ntri;

s->nv = 3 * *ntri;
"\nNumber of verts = %d\n", s->nv;
"\n";

if (s->nv <= 0)
{$ID,2$
FileClose(&f);
return -1;
$ID,-2$}

s->v = MAlloc(3 * s->nv * sizeof(F64));

I64 i, j, k;
k = 0;
for (i = 0; i < *ntri; i++)
{$ID,2$
//"Triangle %d\n", i;

// Ignore normals
for (j = 0; j < 3; j++)
{$ID,2$
//F64 x = FileReadF32(&f);
f.p += 4;
$ID,-2$}

// Save vertices
for (j = 0; j < 9; j++)
{$ID,2$
//"j = %d\n", j;
s->v[k++] = FileReadF32(&f);
$ID,-2$}

if (f.eof)
{$ID,2$
FileClose(&f);
StlFree(s);
return -1;
$ID,-2$}

// Skip 2 junk bytes required by STL spec
f.p += 2;
$ID,-2$}

FileClose(&f);
return 0;
$ID,-2$}

//================================

I64 StlLoad(U8* fstl, Stl* s)
{
$ID,2$/* Read an STL file named fstl.  Also get bounds.

   Set Stl out arg s.
*/

"\nReading \"%s\" ...\n\n", fstl;
$WW,0$
I64 io;

io = StlLoadAscii(fstl, s);
if (io != 0)
{$ID,2$
io = StlLoadBin(fstl, s);
if (io != 0)
{$ID,2$
$WW,1$PrintErr("Cannot read STL file \"%s\".  Is the file properly formatted?\n\n", fstl);
$WW,1$return io;
$ID,-2$}
$ID,-2$}

io = StlGetBounds(s);
if (io != 0) return io;

return 0;
$ID,-2$}

//================================

I64 StlScale(F64 f, Stl* s)
{$ID,2$
/* Scale an STL s by a factor f.

This is not strictly on IO function, but it makes more sense to include here than anywhere else.
*/

I64 i;
for (i = 0; i < 3 * s->nv; i++)
  s->v[i] *= f;

s->xmin *= f;
s->ymin *= f;
s->zmin *= f;

s->xmax *= f;
s->ymax *= f;
s->zmax *= f;

s->cx *= f;
s->cy *= f;
s->cz *= f;

s->r  *= f;

return 0;
$ID,-2$}

//================================
$ID,-2$