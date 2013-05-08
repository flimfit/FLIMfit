
#ifndef CONANALYSIS_H_
#define CONANALYSIS_H_

#ifdef _WINDOWS

#include "cvmarkersobj.h"
using namespace Concurrency::diagnostic;

extern marker_series* writer;

#else

#define _T(x) 0 

class marker_series
{
   marker_series(char* str) {};
}

class span
{
   span(marker_series& ms, int x) {};
}

#endif
#endif