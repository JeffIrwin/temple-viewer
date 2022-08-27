
$ID,2$//================================
$WW,1$
/* Extensions of built-in rotation matrix functions

  As is common in graphics, Terry uses augmented 4x4 matrices to store rotations, translations, and scaling in a single matrix.  The upper-left 3x3 is the rotation matrix, the upper-right 3x1 column is the translation, and the lower-right element is the scaling.$WW,1$

  Depending on the degree of pointer indirection, the matrix is either a rank-2 array of size 4x4 or rank-1 size 16:
$WW,1$
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

I64* Mat4x4ZUp(I64* m)
{$ID,2$
// Set m to z up, x right
I64 r[4][4];
MemSet(r, 0, sizeof(r));
r[0][0] =  GR_SCALE;
r[1][2] = -GR_SCALE;
r[2][1] =  GR_SCALE;
r[3][3] =  GR_SCALE;
return Mat4x4Equ(m, r);
$ID,-2$}
$WW,0$$WW,1$
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

F64 ATan2(F64 y, F64 x)
{$ID,2$
F64 a = inf; // no NaN in TOS?
if (x > 0)
  a = ATan(y/x);
else if (x < 0 && y >= 0)
  a = ATan(y/x) + pi;
else if (x < 0 && y < 0)
  a = ATan(y/x) - pi;
else if (x == 0 && y > 0)
  a =  pi / 2;
else if (x == 0 && y < 0)
  a = -pi / 2;
// undefined if both are 0

return a;
$ID,-2$}

//================================
$ID,-2$