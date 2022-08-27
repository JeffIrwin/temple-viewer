
$ID,2$#include "Math"
#include "StlIo"

//================================

/* Constants */

#define TVMAJOR 0
#define TVMINOR 6
#define TVPATCH 0

#define VIEW_MODE_WIRE 0
#define VIEW_MODE_SURF 1

$WW,1$/* Fixed-point scaling constant.  This allows smooth panning even when zoomed in very close, instead of discrete panning of 1 pixel unit from initial zoom level */
#define FPC 0x4000

// Keyboard shortcuts

#define KEY_HELP  'h'
#define KEY_RROT  'r'
#define KEY_SURF  's'
#define KEY_WIRE  'w'
#define KEY_ZFIT  'z'
#define KEY_DBG   'd'
#define KEY_UP    SC_CURSOR_UP
#define KEY_DOWN  SC_CURSOR_DOWN
#define KEY_LEFT  SC_CURSOR_LEFT
#define KEY_RIGHT SC_CURSOR_RIGHT
#define KEY_ESC   CH_ESC
#define KEY_SHESC CH_SHIFT_ESC

/* Global settings */

// Model rotation matrix
I64 glbl_r[4][4];

// Axes rotation matrix (no panning or zooming)
I64 glbl_ra[4][4];

Stl* glbl_stl = NULL;

I64 glbl_view_mode = VIEW_MODE_SURF; /* default */

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

U0 GrPrintText(CTask* ct, CDC* dc)
{$ID,2$
dc->color = BLACK;

U8* me = MStrPrint("temple-viewer %d.%d.%d",
    TVMAJOR, TVMINOR, TVPATCH);

I64 x = ct->pix_width - (StrLen(me)+1) * FONT_WIDTH;
GrPrint(dc, x, 0, me);

I64 nl = 0;
if (glbl_show_help)
{$ID,2$
U8* help = MStrPrint(
    "%c: toggle help\n"
    "%c: reset rotation\n"
    "%c: surface\n"
    "%c: wireframe\n"
    "%c: zoom fit\n"
    "\n"
    "LMB: rotate\n"
    "RMB: pan\n"
    "Scroll: zoom\n"
    "\n"
    "Arrow keys: rotate 30 degrees\n"
    "Shift+LMB/Arrow: z rotate\n"
    "\n"
    "Esc: exit\n",
    KEY_HELP,
    KEY_RROT,
    KEY_SURF,
    KEY_WIRE,
    KEY_ZFIT);

/* Maybe cycle between 3 levels instead of toggling 2 levels of help? */

GrPrint(dc, FONT_WIDTH, 0, help);

/* Count lines to place debug text below.  Alternatively, help and debug could be catted into a single string a printed with one GrPrint() call */
nl = StrOcc(help, '\n') + 2;
$ID,-2$}

if (glbl_show_dbg)
{$ID,2$
F64 f = 1.0 * FPC / GR_SCALE;

U8* debug = MStrPrint(
    " %c: toggle debug\n\n"
    "%9.6f %9.6f %9.6f\n"
    "%9.6f %9.6f %9.6f\n"
    "%9.6f %9.6f %9.6f\n",
    KEY_DBG,
    f*glbl_r[0][0], f*glbl_r[0][1], f*glbl_r[0][2],
    f*glbl_r[1][0], f*glbl_r[1][1], f*glbl_r[1][2],
    f*glbl_r[2][0], f*glbl_r[2][1], f*glbl_r[2][2]);

GrPrint(dc, 0, FONT_HEIGHT * nl, debug);
$ID,-2$}
$ID,-2$}

//================================

U0 StlDraw(CDC* dc, Stl* s)
{$ID,2$
/* Draw the STL */

//"StlDraw nv = %d\n", s->nv;

DCMat4x4Set(dc, glbl_r); /*This assigns to dc->r and sets r_norm.*/

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
Line(dc, &s->v[a], &s->v[b]);
Line(dc, &s->v[b], &s->v[c]);
Line(dc, &s->v[c], &s->v[a]);
$ID,-2$}
else /*if (glbl_view_mode == VIEW_MODE_SURF)*/
{$ID,2$
/* TODO: experiment w/ light source and add single-color mode */
FillTri(dc, &s->v[a], &s->v[b], &s->v[c],
    (i/9) % (COLORS_NUM-1));
$ID,-2$}
$ID,-2$}
$ID,-2$}

//================================

U0 AxesDraw(CDC* dc)
{$ID,2$
/* Draw orientation axes in the corner */
$WW,1$DCMat4x4Set(dc, glbl_ra);

F64 r;
r = 50.0; // pixel units

dc->color = RED;
GrArrow3(dc, 0, 0, 0, r, 0, 0);
dc->color = YELLOW;
GrArrow3(dc, 0, 0, 0, 0, r, 0);
dc->color = GREEN;
GrArrow3(dc, 0, 0, 0, 0, 0, r);

I64 x, y, z;
F64 r2 = 0.9 * r, dr = 0.2 * r;
dc->color = BLACK;

/* Print text labels offset from tips */

x = r2; y = dr; z = 0;

/* Transform {x,y,z} from 3D to 2D screen coords */
(*dc->transform)(dc,&x,&y,&z);

GrPrint(dc, x, y, "x");

x = 0; y = r2; z = dr;
(*dc->transform)(dc,&x,&y,&z);
GrPrint(dc, x, y, "y");

x = dr; y = 0; z = r2;
(*dc->transform)(dc,&x,&y,&z);
GrPrint(dc, x, y, "z");
$ID,-2$}

//================================

U0 SceneDraw(CTask* ct, CDC* dc)
{$ID,2$
/* Draw the current frame of the whole scene, which includes the STL, help text, and coordinate axes */

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

StlDraw(dc, glbl_stl);
AxesDraw(dc);

// Print help last so it's on top
GrPrintText(ct, dc);

dc->r=old_r;
$ID,-2$}

//================================

I64 StlRender(Stl* s)
{$ID,2$
/* Setup the canvas, start the loop to handle mouse/keyboard events, and draw the scene */

/* This is a very long function, but I can't think of a good way to refactor it without either a lot of global variables or an unwieldy singleton class for the state of keys, mouse, rotation, etc.  That may be the wrong abstraction */

SettingsPush; //See $LK,"SettingsPush",A="MN:SettingsPush"$
DocClear;
WinMax;

/* draw_it() is a callback so we cannot give it extra args.  Pass Stl pointer as a global var */
glbl_stl = s;

F64 x, y, z, theta, zoom, x0, y0, z0,
    xr, yr, xr0, yr0, tx, ty, tx0, ty0;
Bool shift_lb = FALSE, lb0 = FALSE;

// Mouse position
x0 = ms.pos.x;
y0 = ms.pos.y;

// Mouse left-button (lb) trackers
x = x0; y = y0;

// Scroll
z0 = ms.pos.z;
z = z0;

// rb trackers
xr  = x; yr  = y;
xr0 = x; yr0 = y;

// Translation (pan) state
tx0 = 0;
ty0 = 0;
tx = tx0;
ty = ty0;

zoom = 1.0;

/* Local rot matrices for saving rot state */
I64 r[4][4], r0[4][4];

// Initialize to z up
Mat4x4ZUp(r);
Mat4x4Equ(r0, r);

Fs->draw_it = &SceneDraw;
I64 ch = 0, sc;

while (ch != KEY_SHESC && ch != KEY_ESC)
{$ID,2$
/* Most normal characters (i.e. ASCII) are scanned as ch, while special keys like Ctrl, arrow keys, etc. are "scan codes" sc */
ScanKey(&ch, &sc);
U64 s0 = sc.u8[0]; // only this byte matters

/* Is the shift key down?  See "/Adam/WinMgr.HC.Z" which does something similar with SCF_CTRL */
Bool shift = kbd.scan_code&SCF_SHIFT;

if (ch == KEY_WIRE)
{$ID,2$
glbl_view_mode = VIEW_MODE_WIRE;
$ID,-2$}
else if (ch == KEY_SURF)
{$ID,2$
glbl_view_mode = VIEW_MODE_SURF;
$ID,-2$}
else if (ch == KEY_HELP)
{$ID,2$
glbl_show_help = !glbl_show_help;
$ID,-2$}
else if (ch == KEY_DBG)
{$ID,2$
glbl_show_dbg = !glbl_show_dbg;
$ID,-2$}
else if (shift &&
    (s0 == KEY_LEFT ||
     s0 == KEY_DOWN))
{$ID,2$
Mat4x4Equ(r, r0); // dst, src
Mat4x4RotZ(r, -pi/6);
$ID,-2$}
else if (shift &&
    (s0 == KEY_RIGHT ||
     s0 == KEY_UP))
{$ID,2$
Mat4x4Equ(r, r0);
Mat4x4RotZ(r,  pi/6);
$ID,-2$}
else if (s0 == KEY_UP)
{$ID,2$
Mat4x4Equ(r, r0);
Mat4x4RotX(r, -pi/6);
$ID,-2$}
else if (s0 == KEY_DOWN)
{$ID,2$
Mat4x4Equ(r, r0);
Mat4x4RotX(r,  pi/6);
$ID,-2$}
else if (s0 == KEY_RIGHT)
{$ID,2$
Mat4x4Equ(r, r0);
Mat4x4RotY(r, -pi/6);
$ID,-2$}
else if (s0 == KEY_LEFT)
{$ID,2$
Mat4x4Equ(r, r0);
Mat4x4RotY(r,  pi/6);
$ID,-2$}

if (ch == KEY_RROT)
{$ID,2$
/* Reset rotation (and zoom fit) */
Mat4x4ZUp(r);
Mat4x4Equ(r0, r);
$ID,-2$}
if (ch == KEY_ZFIT || ch == KEY_RROT)
{$ID,2$
/* Zoom to fit data */
z0 = ms.pos.z;
z = z0;

tx0 = 0;
ty0 = 0;
tx = tx0;
ty = ty0;
$ID,-2$}

/* Note, RMB + KEY_RROT does weird stuff.  If/else chains could be changed to prioritize one and ignore the other */

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

/* Is the shift key down at the start of LMB drag? */
shift_lb = ms.lb 
    && (shift_lb || (!lb0 && shift));
lb0 = ms.lb;

/* Track left-button drag for rotations */
if (shift_lb)
{$ID,2$
/* Shift+LMB: z rotation, controlled by angular cursor position wrt window center */
x = ms.pos.x;
y = ms.pos.y;

/* Window center.  Alternatively, we could get model center and transform() it to screen coords to use as z rotation center */
F64 cx = Fs->pix_left + Fs->pix_width  / 2;
F64 cy = Fs->pix_top  + Fs->pix_height / 2;

F64 theta0;
theta  = ATan2(y  - cy, x  - cx);
theta0 = ATan2(y0 - cy, x0 - cx);

Mat4x4Equ(r, r0);
Mat4x4RotZ(r, theta - theta0);
$ID,-2$}
else if (ms.lb)
{$ID,2$
/* LMB (w/o shift): free rotation */
x = ms.pos.x;
y = ms.pos.y;

F64 ux, uy;

/* Set screen-plane right-hand normal to drag direction. Dragging horizontally rotates about a vertical axis and vice-versa. */
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

Mat4x4IdentEqu(glbl_r );
Mat4x4IdentEqu(glbl_ra);

/* Translate center of model to origin (window center) */
Mat4x4TranslationEqu(glbl_r,
    -s->cx, -s->cy, -s->cz);

/* Apply rotation about model center */
Mat4x4Mul(glbl_r , r);
Mat4x4Mul(glbl_ra, r);

/* Apply mouse pan after rotation so it pans in screen XY coordinate system (not model XY). */
Mat4x4TranslationAdd(glbl_r, FPC*tx, FPC*ty, 0);

/* Put axes in lower-left corner.  Put on top with a big z translation */
Mat4x4TranslationAdd(glbl_ra,
    -0.41 * Fs->pix_width,
     0.38 * Fs->pix_height, -0.9 * GR_Z_ALL);

/* Use Exp so zoom is always positive.  Zoom is towards window center, not cursor or model.  Clamp belowe 10k bc stuff gets laggy at high zoom */
zoom = Clamp(Exp(0.05 * (ms.pos.z - z0)),
    -1.0, 10000.0);
Mat4x4Scale(glbl_r, zoom / FPC);

Sleep(20);
$ID,-2$}
SettingsPop;$ID,2$
$ID,-2$glbl_stl = NULL;

//"glbl_r[10] = %d\n", glbl_r[2][2];
//"GR_SCALE = %d\n", GR_SCALE;
//"pix_height = %d\n", Fs->pix_height;

return 0;
$ID,-2$}

//================================

I64 StlView(U8* fstl)
{$ID,2$
/* Read and graphically render an STL file */

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