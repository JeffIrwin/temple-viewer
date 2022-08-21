
$ID,2$#include "StlIo"

//================================

/* Global settings */

I64 glbl_r[4][4];
Stl* glbl_stl = NULL;

#define VIEW_MODE_WIRE 0
#define VIEW_MODE_SURF 1

I64 glbl_view_mode = VIEW_MODE_SURF; /* default */

Bool glbl_show_help = TRUE;
Bool glbl_show_dbg  = FALSE;

$WW,1$/* Fixed-point scaling constant.  This allows smooth panning even when zoomed in very close, instead of discrete panning of 1 pixel unit from initial zoom level */
#define FPC 0x4000

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

U0 GrPrintHelp(CDC* dc)
{$ID,2$
dc->color = BLACK;

if (glbl_show_help)
{$ID,2$
U8* help =
    "h: toggle help\n"
    "s: surface\n"
    "w: wireframe\n"
    "LMB: rotate\n"
    "RMB: pan\n"
    "Scroll: zoom\n"
    "Esc: exit";

GrPrint(dc, FONT_WIDTH, 0, help);
$ID,-2$}

if (glbl_show_dbg)
{$ID,2$
F64 f = 1.0 * FPC / GR_SCALE;

/* Apparently there's a limit to the number of print args, so you can't do this all at once */
I64 y0 = 90, dy = 10;
GrPrint(dc, 0, y0, "%9.6f %9.6f %9.6f",
f*glbl_r[0][0],
f*glbl_r[0][1],
f*glbl_r[0][2]);
GrPrint(dc, 0, y0+dy, "%9.6f %9.6f %9.6f",
f*glbl_r[1][0],
f*glbl_r[1][1],
f*glbl_r[1][2]);
GrPrint(dc, 0, y0+2*dy, "%9.6f %9.6f %9.6f", f*glbl_r[2][0],
f*glbl_r[2][1],
f*glbl_r[2][2]);
GrPrint(dc, 0, y0+3*dy, " d: toggle debug");
$ID,-2$}
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

if (glbl_view_mode == VIEW_MODE_WIRE)
{$ID,2$
Line(dc, &(s->v[a]), &(s->v[b]));
Line(dc, &(s->v[b]), &(s->v[c]));
Line(dc, &(s->v[c]), &(s->v[a]));
$ID,-2$}
else /*if (glbl_view_mode == VIEW_MODE_SURF)*/
{$ID,2$
/* TODO: experiment w/ light source and add single-color mode */
FillTri(dc, &(s->v[a]), &(s->v[b]), &(s->v[c]), (i/9) % (COLORS_NUM-1));
$ID,-2$}
$ID,-2$}

// Print help last so it's on top
GrPrintHelp(dc);

dc->r=old_r;
$ID,-2$}

//================================

/* Extensions of built-in rotation matrix functions

  As is common in graphics, Terry uses augmented 4x4 matrices to store rotations, translations, and scaling in a single matrix.  The upper-left 3x3 is the rotation matrix, the upper-right 3x1 column is the translation, and the lower-right element is the scaling.

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
/* General axis-angle rotation about an axis vector [x,y,z] by angle theta.  Vector must be normalized! */

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

/* Ref: wikipedia 
 *
 *     https://en.wikipedia.org/wiki/Rotation_matrix#Rotation_matrix_from_axis_and_angle
 *
 */
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

F64 x, y, z, zoom, x0, y0, z0,
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
tx0 = 0;
ty0 = 0;
tx = tx0;
ty = ty0;

zoom = 1.0;

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

tx = (xr - xr0)/zoom + tx0;
ty = (yr - yr0)/zoom + ty0;
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

/* Screen-plane right-hand normal to drag direction. Dragging horizontally rotates about a vertical axis and vice-versa. */
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

/* Translate center of model to origin (window center) */
Mat4x4TranslationEqu(glbl_r,
    -s->cx, -s->cy, -s->cz);

/* Apply rotation about model center */
Mat4x4Mul(glbl_r, r);

/* Apply mouse pan after rotation so it pans in screen XY coordinate system (not model XY). */
Mat4x4TranslationAdd(glbl_r, FPC*tx, FPC*ty, 0);

/* Use Exp so zoom is always positive.  Zoom is towards window center, not cursor or model */
zoom = Exp(0.05 * (ms.pos.z - z0));
Mat4x4Scale(glbl_r, zoom / FPC);

Sleep(20);
$ID,-2$}
SettingsPop;$ID,2$
$ID,-2$glbl_stl = NULL;

//"glbl_r[10] = %d\n", glbl_r[2][2];
//"GR_SCALE = %d\n", GR_SCALE;

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

io = StlScale(0.6 * FPC * win_size / s.r, &s);
if (io != 0) goto free;
//return 0;

io = StlRender(&s);
if (io != 0) return io;

free:
StlFree(&s);

return io;
$ID,-2$}

//================================
$ID,-2$