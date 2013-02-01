//=========================================================================
//  
//  GlobalProcessing FLIM Analysis Package
//  (c) 2013 Sean Warren
//
//
//
//=========================================================================

#ifndef _UTIL_H
#define _UTIL_H

#include <cstring>

template<typename T>
void ClearVariable(T*& var)
{
   if (var!=NULL)
   {
      delete[] var;
      var = NULL;
   }
};

void SetNaN(double* var, int n);
void SetNaN(float* var, int n);

#ifndef _MSVC

#define _ASSERTE(x)
#define _ASSERT(x)

int _CrtCheckMemory( );

#endif

#endif 
