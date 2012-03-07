
//#include "f2c.h"


#ifdef __cplusplus
extern "C" {
#endif

double d_sign(double *a, double *b)
{
	double x;
	x = (*a >= 0 ? *a : - *a);
	return( *b >= 0 ? x : -x);
};

#ifdef __cplusplus
	}
#endif
