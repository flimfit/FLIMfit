
#ifndef CONANALYSIS_H_
#define CONANALYSIS_H_

#ifdef USE_CONCURRENCY_ANALYSIS

#include "cvmarkersobj.h"
using namespace Concurrency::diagnostic;

#define INIT_CONCURRENCY   span* sp
#define START_SPAN(x)      sp = new span (*writer, _T(x))
#define END_SPAN           delete sp  

extern marker_series* writer;

#else

#define INIT_CONCURRENCY   
#define START_SPAN(x)
#define END_SPAN           

#define _T(x) 0 

#endif


#endif