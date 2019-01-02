//=========================================================================
//
// Copyright (C) 2013 Imperial College London.
// All rights reserved.
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License along
// with this program; if not, write to the Free Software Foundation, Inc.,
// 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
// This software tool was developed with support from the UK 
// Engineering and Physical Sciences Council 
// through  a studentship from the Institute of Chemical Biology 
// and The Wellcome Trust through a grant entitled 
// "The Open Microscopy Environment: Image Informatics for Biological Sciences" (Ref: 095931).
//
// Author : Sean Warren
//
//=========================================================================

#pragma once

#define CONSTRAIN_FRACTIONS 1

#include "AbstractFitter.h"
#include "nnls.h"

class MaximumLikelihoodFitter : public AbstractFitter
{
public:

   MaximumLikelihoodFitter(std::shared_ptr<DecayModel> model, FittingOptions options, std::shared_ptr<ProgressReporter> reporter);

   void fitFcn(int nl, std::vector<double>& alf, int& niter, int& ierr);

   void getLinearParams();
private:

   aligned_vector<double> b;

   void setLinearFactors(double* alf);

   void mle_funcs(double *alf, double *fvec, int nl, int nfunc);
   void mle_jacb(double *alf, double *fjac, int nl, int nfunc);

   // Buffers used by levmar algorithm
   double info[LM_INFO_SZ];
   std::vector<double> dy, work, expA, scale, alf_unscaled;


   int nfunc;
   double scaling;

   std::unique_ptr<NonNegativeLeastSquares> nnls;

   friend void MLEfuncsCallback(double *alf, double *fvec, int nl, int nfunc, void* pa);
   friend void MLEjacbCallback(double *alf, double *fjac, int nl, int nfunc, void* pa);

   template<typename it>
   void setScaledVariables(it alf_)
   {
      std::copy(alf_, alf_ + nl, alf.begin());

      int idx = 0;
      for (int i = 0; i<nl; i++)
      {
         alf[i] *= scale[i];

         if (i == fixed_param)
            params[i] = fixed_value_cur;
         else
            params[i] = alf[idx++];
      }

      model->setVariables(params);
   }
};
