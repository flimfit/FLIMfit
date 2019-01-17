#pragma once

#ifdef USE_SIMD
   #define __FMA__
   #include "simd_avx.h"

   #include <iostream>
   #include <string>
   #include <immintrin.h>
   #include <vector>

   static const vecd a1 = vset1_pd(0.254829592);
   static const vecd a2 = vset1_pd(-0.284496736);
   static const vecd a3 = vset1_pd(1.421413741);
   static const vecd a4 = vset1_pd(-1.453152027);
   static const vecd a5 = vset1_pd(1.061405429);

   #define verf_pd _mm256_erf_pd_

   static const vecd p = vset1_pd(0.3275911);
   static const vecd signmask = vset1_pd(-0.0);

   inline static vecd abs_mask(void) {
      __m256i minus1 = _mm256_set1_epi64x(-1);
      return _mm256_castsi256_pd(_mm256_srli_epi64(minus1, 1));
   }


   inline static vecd _mm256_erf_pd_(vecd x)
   {
      vecd t, t_exp, y, negx, signx;

      vecd c_one = vset1_pd(1);

      signx = vand_pd(x, signmask); // stores sign of x
      x = vand_pd(x, abs_mask()); // abs(x)
      negx = vxor_pd(x, signmask); // negx = -x
      t = vdiv_pd(c_one, vfmadd_pd(x, p, c_one)); // t = 1 / (1 + p*x)

      y = a5;
      y = vfmadd_pd(y, t, a4);
      y = vfmadd_pd(y, t, a3);
      y = vfmadd_pd(y, t, a2);
      y = vfmadd_pd(y, t, a1);  
      t_exp = vmul_pd(t, vexp_pd(vmul_pd(negx, x))); // t_exp = t * exp(-x*x)
      y = vsub_pd(c_one, vmul_pd(y, t_exp));

      y = vor_pd(y, signx);
      return y;
   }
#endif