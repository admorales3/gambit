//
// FILE: glpsolv1.cc -- Instantiation of a specialized LP solvers
//
// $Id$
//

#include "glpsolv1.imp"
#include "rational.h"

#ifdef __GNUG__
#define TEMPLATE template
#elif defined __BORLANDC__
#define TEMPLATE
#pragma option -Jgd
#endif   // __GNUG__, __BORLANDC__

TEMPLATE class gLPTableau1<double>;
TEMPLATE class gLPTableau1<gRational>;
