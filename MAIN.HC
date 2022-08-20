$ID,2$
//================================

$WW,1$/* TODO: split into separate source files for file handling, stl, etc. */

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

U0 StlFree(Stl* s)
{$ID,2$
//"Freeing STL ...\n";
//"&v = %x\n", s->v;
Free(s->v);
s->nv = 0;
$ID,-2$}

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

I64 StlScale(F64 f, Stl* s)
{$ID,2$
/* Scale an STL s by a factor f */

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

/* Global settings */

I64 glbl_r[4][4];
Stl* glbl_stl = NULL;

I64 glbl_view_mode;
#define VIEW_MODE_WIRE 0
#define VIEW_MODE_SURF 1

glbl_view_mode = VIEW_MODE_SURF; /* default */

Bool glbl_show_help = TRUE;
Bool glbl_show_dbg  = FALSE;

//================================

// Graphic helpers

U0 Line(CDC* dc, F64* a, F64* b)
{$ID,2$
/* This is wrapper that takes 2 arrays instead of 6 scalars */
GrLine3(dc, a[0], a[1], a[2], b[0], b[1], b[2]);
$ID,-2$}

U0 FillTri(CDC* dc, F64* a, F64* b, F64* c, I64 color)
{
$ID,2$/* Fill a 3D triangle defined by points a, b, c */

/* Copy args into a single polygon array */
CD3I32 p[3];
p[0].x = a[0]; p[0].y = a[1]; p[0].z = a[2];
p[1].x = b[0]; p[1].y = b[1]; p[1].z = b[2];
p[2].x = c[0]; p[2].y = c[1]; p[2].z = c[2];

dc->color = color;
GrFillPoly3(dc, 3, p);
$ID,-2$}

//================================

U0 StlDraw(CTask* ct, CDC* dc)
{$ID,2$
I64 *old_r=dc->r;
dc->thick=1;
dc->color=RED;

/* Translate origin to center of window.  This even works if you resize the window mid-render */

dc->x = ct->pix_width  / 2; // measured from left
dc->y = ct->pix_height / 2; // measured from top

/* Prevent clipping at screen plane */
dc->z = GR_Z_ALL;

dc->flags|=DCF_TRANSFORMATION;

/* The depth buffer draws closer triangles on top instead of drawing the last triangle in the STL on top */
DCDepthBufAlloc(dc);

// TODO: refactor into another function
if (glbl_show_dbg)
{$ID,2$
/* Apparently there's a limit to the number of pritn args, so you can't do this all at once */
I64 y0 = 90, dy = 10;
GrPrint(dc, 0, y0, "%9.6f %9.6f %9.6f",
1.0*glbl_r[0][0]/GR_SCALE,
1.0*glbl_r[0][1]/GR_SCALE,
1.0*glbl_r[0][2]/GR_SCALE);
GrPrint(dc, 0, y0+dy, "%9.6f %9.6f %9.6f",
1.0*glbl_r[1][0]/GR_SCALE,
1.0*glbl_r[1][1]/GR_SCALE,
1.0*glbl_r[1][2]/GR_SCALE);
GrPrint(dc, 0, y0+2*dy, "%9.6f %9.6f %9.6f", 1.0*glbl_r[2][0]/GR_SCALE,
1.0*glbl_r[2][1]/GR_SCALE,
1.0*glbl_r[2][2]/GR_SCALE);
GrPrint(dc, 0, y0+3*dy, " d: toggle debug");
$ID,-2$}

DCMat4x4Set(dc,glbl_r); /*This assigns to dc->r and sets r_norm.*/

U8* help =
    "h: toggle help\n"
    "s: surface\n"
    "w: wireframe\n"
    "lb: rotate\n"
    "rb: pan\n"
    "scroll: zoom\n"
    "ESC: exit";

if (glbl_show_help)
  GrPrint(dc, FONT_WIDTH, 0, help);

Stl* s = glbl_stl;

//"StlDraw nv = %d\n", s->nv;

I64 i, a, b, c;
for (i = 0; i < 3 * s->nv; i += 9)
{$ID,2$
// Triangle loop

// Vertex x indices
a = i + 0;
b = i + 3;
c = i + 6;

if (glbl_view_mode == VIEW_MODE_WIRE)
{$ID,2$
Line(dc, &(s->v[a]), &(s->v[b]));
Line(dc, &(s->v[b]), &(s->v[c]));
Line(dc, &(s->v[c]), &(s->v[a]));
$ID,-2$}
else /*if (glbl_view_mode == VIEW_MODE_SURF)*/
{$ID,2$
FillTri(dc, &(s->v[a]), &(s->v[b]), &(s->v[c]), (i/9) % (COLORS_NUM-1));
$ID,-2$}
$ID,-2$}

dc->r=old_r;
$ID,-2$}

//================================

/* Extensions of built-in rotation matrix functions

  As is common in graphics, Terry uses augmented 4x4 matrices to store rotations, translations, and scaling in a single matrix.  The upper-left 3x3 is the rotation matrix, the right 3x1 column is the translation, and the lower-right element is the scaling.

 Depending on the degree of pointer indirection, the matrix is either a rank-2 array of size 4x4 or rank-1 size 16:

  [  0  1  2  3 ]
  [  4  5  6  7 ]
  [  8  9 10 11 ]
  [ 12 13 14 15 ]
*/

I64* Mat4x4Mul(I64* dst, I64* r)
{$ID,2$
/* Wrapper for Mat4x4MulMat4x4Equ without the extra dummy arg.  dst is an in/out arg!  Conceptually, the transform r is applied after input dst.  Output is stored in dst (and returned per Terry's convention) */

// Dummy for storage during mul
I64 r2[16];

return Mat4x4Equ(dst,
    Mat4x4MulMat4x4Equ(r2, r, dst));
$ID,-2$}

I64* Mat4x4Rot(I64* m, F64 x, F64 y, F64 z, F64 theta)
{$ID,2$
/* General axis-angle rotation about a vector [x,y,z] by angle theta.  Vector must be normalized! */

/* Skip identity/singular case. Caller likely set vector to garbage */
if (theta == 0) return m;

F64 c = Cos(theta);
F64 s = Sin(theta);
F64 t = 1 - c;

// fixed-point
c *= GR_SCALE;
s *= GR_SCALE;
t *= GR_SCALE;

I64 r[16];
MemSet(r, 0, sizeof(r));

// Ref: wikipedia
r[ 0] = c + x*x*t;
r[ 1] = x*y*t - z*s;
r[ 2] = z*x*t + y*s;

r[ 4] = x*y*t + z*s;
r[ 5] = c + y*y*t;
r[ 6] = y*z*t - x*s;

r[ 8] = z*x*t - y*s;
r[ 9] = y*z*t + x*s;
r[10] = c + z*z*t;

r[15] = GR_SCALE;

return Mat4x4Mul(m, r);
$ID,-2$}

//================================

I64 StlRender(Stl* s)
{$ID,2$
SettingsPush; //See $LK,"SettingsPush",A="MN:SettingsPush"$
DocClear;

/* draw_it() is a callback so we cannot give it extra args.  Pass Stl pointer as a global var */
glbl_stl = s;

F64 x, y, z, zm, x0, y0, z0,
    xr, yr, xr0, yr0,
    tx, ty, tx0, ty0;

// Mouse position
x0 = ms.pos.x;
y0 = ms.pos.y;

// mouse left-button (lb) trackers
x = x0; y = y0;

// scroll
z0 = ms.pos.z;
z = z0;

// rb trackers
xr  = x; yr  = y;
xr0 = x; yr0 = y;

// translation (pan) state
tx0 = 0;
ty0 = 0;
tx = tx0;
ty = ty0;

zm = 1.0;

/* Local rot matrices for saving rot state */
I64 r[4][4], r0[4][4];

// Initialize to z up
MemSet(r, 0, sizeof(r));
r[0][0] =  GR_SCALE;
r[1][2] = -GR_SCALE;
r[2][1] =  GR_SCALE;
r[3][3] =  GR_SCALE;

Mat4x4Equ(r0, r);

Fs->draw_it = &StlDraw;
I64 ch = 0;
while (!(ch = ScanChar)
    ||  (ch != CH_SHIFT_ESC && ch != CH_ESC))
{$ID,2$
// TODO: make const chars for these and help
if (ch == 'w')
{$ID,2$
glbl_view_mode = VIEW_MODE_WIRE;
$ID,-2$}
else if (ch == 's')
{$ID,2$
glbl_view_mode = VIEW_MODE_SURF;
$ID,-2$}
else if (ch == 'h')
{$ID,2$
glbl_show_help = !glbl_show_help;
$ID,-2$}
else if (ch == 'd')
{$ID,2$
glbl_show_dbg = !glbl_show_dbg;
$ID,-2$}

/* TODO: add an option to reset/center view, and a key/mouse combo for z rotation */

/* Track right-button drag for translations.  No middle-button in TempleOS? */
if (ms.rb)
{$ID,2$
xr = ms.pos.x;
yr = ms.pos.y;

tx = (xr - xr0)/zm + tx0;
ty = (yr - yr0)/zm + ty0;
$ID,-2$}
else
{$ID,2$
xr0 = ms.pos.x;
yr0 = ms.pos.y;
tx0 = tx;
ty0 = ty;
$ID,-2$}

/* Track left-button drag for rotations */
if (ms.lb)
{$ID,2$
x = ms.pos.x;
y = ms.pos.y;

F64 ux, uy, theta;

/* In-screen right-hand normal to drag direction */
ux =  (y - y0);
uy = -(x - x0);

// Normalize
theta = Sqrt(Sqr(ux) + Sqr(uy));
ux /= theta;
uy /= theta;

theta *= 0.02; // calibrate sensitivity

// Pop state from r0
Mat4x4Equ(r, r0); // dst, src

Mat4x4Rot(r, ux, uy, 0, theta);
$ID,-2$}
else
{$ID,2$
x0 = ms.pos.x;
y0 = ms.pos.y;
Mat4x4Equ(r0, r); // push state
$ID,-2$}

Mat4x4IdentEqu(glbl_r);

/* Translate center of model to origin */
Mat4x4TranslationEqu(glbl_r,
    -s->cx, -s->cy, -s->cz);

/* Apply rotation about model center */
Mat4x4Mul(glbl_r, r);

/* Apply mouse pan after rotation so it pans in screen XY coordinate system (not model XY). */
Mat4x4TranslationAdd(glbl_r, tx, ty, 0);

/* Use Exp so zm is always positive.  Zoom is towards screen center, not cursor or model */
zm = Exp(0.05 * (ms.pos.z - z0));
Mat4x4Scale(glbl_r, zm);

Sleep(20);
$ID,-2$}
SettingsPop;$ID,2$
$ID,-2$glbl_stl = NULL;

//"glbl_r[10] = %d\n", glbl_r[2][2];

return 0;
$ID,-2$}

//================================

I64 StlView(U8* fstl)
{$ID,2$
/* Read and graphically render an STL file */

Stl s;
I64 io = 0;

io = StlLoad(fstl, &s);
if (io != 0) return io;

I64 win_size = MinI64(
    Fs->pix_width,
    Fs->pix_height);

io = StlScale(0.6 * win_size / s.r, &s);
if (io != 0) goto free;

//return 0;
io = StlRender(&s);
if (io != 0) return io;

free:
StlFree(&s);

return io;
$ID,-2$}

//================================

U0 Main()
{$ID,2$
Cd(__DIR__);
U8* f;

// STL filename to be viewed

f = "./DATA/ASCII.STL";
f = "./DATA/BUNNY.STL";
//f = "./DATA/DODECA.STL";
//f = "./DATA/PIKACHU.STL";
//f = "./DATA/XYZCUBE.STL";

// Big
//f = "./DATA/utahteapot.stl";

// Very big
//f = "./DATA/BENCHY3D.STL";

StlView(f);

$ID,-2$}

Main;

$ID,-2$