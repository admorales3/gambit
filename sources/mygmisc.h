//
// FILE: mygmisc.h -- Miscellaneous generally-useful functions (for AMM)
//
// $Id$
//

#ifndef MYGMISC_H
#define MYGMISC_H

#include "gmisc.h"
#include "double.h"
#include "gstring.h"

//
// Converting between strings and other datatypes
//

gString         ToString(gDouble);
//double		FromString(const gString &s, gDouble &d);
gDouble          TOgDouble(const gString &);

#endif    // MYGMISC_H
