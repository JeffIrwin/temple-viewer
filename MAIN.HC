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
$WW,1$
Bool IsWS(U8 c)
{$ID,2$
/* Is c whitespace?
  
   Does not skip exotic chars like vertical tab
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
"Closing file\n";
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
I64 endp = f->data + f->len;

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

//================================

class Stl
{$ID,2$
/* Stereolithography file struct */

// Number of vertices
I64 nv;

/* Vertex coordinates, size 3 *nv.  Every 3 vertices (9 array elems) make a triangle.  There is no vertex equivalencing */
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

I64 StlLoad(U8* fstl, Stl* s)
{
$ID,2$/* Read an ASCII STL file named fstl.

   Set Stl out arg s.
*/

"\nReading \"%s\" ...\n\n", fstl;

File f;
FileOpen(fstl, &f);
if (f.eof) return -1;

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
/*if (nlines <10) PrintLine(ls, le);*/

/* Case-insensitive str comparison */
if (StrNICmp(ls, VrtId, StrLen(VrtId)) == 0)
  s->nv++;
$ID,-2$}

/*"Number of lines = %d\n", nlines;*/
"Number of verts = %d\n", s->nv;
"\n";

/* 3 dimensions, 8 bytes.  MAlloc uses 1-byte units */
s->v = MAlloc(3 *s->nv *sizeof(F64));

//"&v = %x\n", s->v;

F64 xmin, xmax, ymin, ymax, zmin, zmax;

// Re-read and save vertices v
FileRewind(&f);
I64 i = 0;
Bool init = FALSE;
while (!f.eof)
{$ID,2$
//"%d\n", i;
FileGetLine(&f, &ls, &le);
SkipWS(&ls, &le);

if (StrNICmp(ls, VrtId, StrLen(VrtId)) == 0)
{$ID,2$
/*if (i <10) PrintLine(ls, le);*/

/* Skip to the end of the "vertex" str */
ls += StrLen(VrtId);

/* Pointer to end of Str2F64 read */
U8* p;

/* Read 3 coordinates (x, y, and z) */
s->v[i++] = Str2F64(ls, &p); ls = p;
s->v[i++] = Str2F64(ls, &p); ls = p;
s->v[i++] = Str2F64(ls, &p); ls = p;

if (!init)
{$ID,2$
init = TRUE;
xmin = s->v[i-3];
ymin = s->v[i-2];
zmin = s->v[i-1];
xmax = xmin;
ymax = ymin;
zmax = zmin;
$ID,-2$}
else
{$ID,2$
xmin = Min(xmin, s->v[i-3]);
ymin = Min(ymin, s->v[i-2]);
zmin = Min(zmin, s->v[i-1]);

xmax = Max(xmax, s->v[i-3]);
ymax = Max(ymax, s->v[i-2]);
zmax = Max(zmax, s->v[i-1]);
$ID,-2$}
$ID,-2$}
$ID,-2$}
"x in [%9.6f, %9.6f]\n", xmin, xmax;
"y in [%9.6f, %9.6f]\n", ymin, ymax;
"z in [%9.6f, %9.6f]\n", zmin, zmax;
"\n";

s->cx = 0.5 *(xmin +xmax);
s->cy = 0.5 *(ymin +ymax);
s->cz = 0.5 *(zmin +zmax);

//"Center = %9.6f %9.6f %9.6f\n",
//    s->cx,
//    s->cy,
//    s->cz;

s->r = 0.5 *Sqrt(
    Sqr(xmax - xmin) +
    Sqr(ymax - ymin) +
    Sqr(zmax - zmin));

//"Radius = %9.6f\n", s->r;

s->xmin = xmin;
s->ymin = ymin;
s->zmin = zmin;

s->xmax = xmax;
s->ymax = ymax;
s->zmax = zmax;

FileClose(&f);

return 0;
$ID,-2$}

I64 StlScale(F64 f, Stl* s)
{$ID,2$
I64 i;
for (i = 0; i < 3 *s->nv; i++)
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

U0 StlFree(Stl* s)
{$ID,2$
//"Freeing STL ...\n";
//"&v = %x\n", s->v;
Free(s->v);
s->nv = 0;
$ID,-2$}

//================================

I64 glbl_r[4][4];
Stl* glbl_stl = NULL;

U0 Line(CDC* dc, F64* a, F64* b)
{$ID,2$
/* This is wrapper that takes 2 arrays instead of 6 scalars */
GrLine3(dc, a[0], a[1], a[2], b[0], b[1], b[2]);
$ID,-2$}

U0 StlDraw(CTask* ct, CDC* dc)
{$ID,2$
I64 *old_r=dc->r;
dc->thick=1;
dc->color=RED;

/* Translate origin to center of window.  This even works if you resize the window mid-render */

dc->x = ct->pix_width  / 2; // measured from left
dc->y = ct->pix_height / 2; // measured from top

dc->flags|=DCF_TRANSFORMATION;
DCMat4x4Set(dc,glbl_r); /*This assigns to dc->r and sets r_norm.*/

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

Line(dc, &(s->v[a]), &(s->v[b]));
Line(dc, &(s->v[b]), &(s->v[c]));
Line(dc, &(s->v[c]), &(s->v[a]));
$ID,-2$}

dc->r=old_r;
$ID,-2$}

I64 StlRender(Stl* s)
{
$ID,2$F64 é=0,è=0,ê=0,sc=1,s1=1.05;
SettingsPush; //See $LK,"SettingsPush",A="MN:SettingsPush"$
DocClear;

/* draw_it() is a callback so we cannot give it extra args.  Pass Stl pointer as a global var */
glbl_stl = s;

Fs->draw_it=&StlDraw;
while (!ScanChar)
{$ID,2$
Mat4x4IdentEqu(glbl_r);

/* Translate center of model to origin */
Mat4x4TranslationEqu(glbl_r,
    -s->cx, -s->cy, -s->cz);

// Rotations about origin
Mat4x4RotZ(glbl_r,é);
Mat4x4RotX(glbl_r,è);
Mat4x4RotZ(glbl_r,ê);

Mat4x4Scale(glbl_r,sc);

Sleep(20);
é+=2*ã/70;
è+=2*ã/90;
ê+=2*ã/110;
sc*=s1;
if ( !(0.2<sc<1.4) ) s1=1/s1;
$ID,-2$}
SettingsPop;$ID,2$
$ID,-2$glbl_stl = NULL;

return 0;
$ID,-2$}

//================================

I64 StlView(U8* fstl)
{$ID,2$
Stl s;
I64 io = 0;$ID,2$
$ID,-2$
io = StlLoad(fstl, &s);
if (io != 0) return io;

I64 win_size = MinI64(
    Fs->pix_width,
    Fs->pix_height);

io = StlScale(win_size / s.r, &s);
if (io != 0) return io;

io = StlRender(&s);
if (io != 0) return io;

StlFree(&s);

return io;
$ID,-2$}

//================================

U0 Main()
{$ID,2$
Cd(__DIR__);
U8* f;

// STLfile to be viewed
f = "./DATA/BUNNY.STL";
//f = "./DATA/TEAPOT.STL";

StlView(f);

//Dir;
$ID,-2$}

Main;

