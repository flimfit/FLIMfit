#ifndef OMP_H
#define OMP_H

#ifdef USE_OMP

#include "omp.h"

#else

int omp_get_thread_num()
{
   return 0;
}

void omp_set_num_threads(int num_threads)
{
   return;
}

#endif

#endif