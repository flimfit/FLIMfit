#include "DecayResampler.h"

void testDecayResampler()
{
   std::vector<double> test  = {2, 0, 1, 1, 1, 3, 1, 0, 0, 1, 0, 0, 0};
   
   std::vector<double> test1 = {2, 1, 4, 1, 4, 3, 1, 4, 1, 1, 1, 1, 1};
   DecayResampler r(13, 3);

   r.determineSampling(test.data());
   r.resample(test1.data());

   int a = 1;
}
