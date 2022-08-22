$WW,1$Cd(__DIR__);;
#include "Load"

U0 ViewerMain()
{$ID,2$
/* Feel free to use this and save a list of your STL files here, or just call StlView("/path/to/my/file.stl") directly after including Load.HC */

// STL filename to be viewed
$WW,1$$WW,1$U8* f;

f = "./DATA/ASCII.STL";
f = "./DATA/BUNNY.STL";
//f = "./DATA/DODECA.STL";
//f = "./DATA/PIKACHU.STL";
//f = "./DATA/XYZCUBE.STL";

// Big
//f = "./DATA/utahteapot.stl";

// Very big
//f = "./DATA/BENCHY3D.STL";

StlView(f);

$ID,-2$}

ViewerMain();