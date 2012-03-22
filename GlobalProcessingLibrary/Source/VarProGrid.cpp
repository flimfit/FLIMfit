#include "ModelADA.h"
#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

void GetVarsAtGridIdx(int idx, int nl, int grid_size, double var_min[], double var_step[], double var[]);

void varp2_grid(integer *s, integer *l, integer *lmax, integer *
   nl, integer *n, integer *nmax, integer *ndim, integer *lpps1, integer 
   *lps, integer *pp2, integer *iv, doublereal *t, doublereal *y, 
   doublereal *w, U_fp ada, doublereal *a, doublereal *b,
    integer *iprint, integer *gc, integer *thread, doublereal *alf, doublereal *beta, 
   integer *ierr, doublereal *r__, integer *gn,
   doublereal var_min[], doublereal var_max[], doublereal grid[], integer grid_size, integer grid_factor, doublereal buf[], integer n_iter )
{   
   static doublereal eps1 = 1e-6;

   integer err[1];
   integer static_store[200];

   int idx, iter;
   double grid_min;
   int grid_min_idx = -1;

   integer b1 = *l + *s + 1;
   integer lnls1 = *l + *nl + *s + 1;
   integer nlp1 = *nl + 1;
 
   double *step = buf;

   int grid_positions = 1;

   for(int i=0; i<*nl; i++)
      grid_positions *= grid_size;

   *ierr = 1;
   *err = 1;

   /*
   int write_to_file = false;
   FILE* f;
   if (write_to_file)
   {
      fopen(&f,"c:\\users\\scw09\\varp2_export.dat","ab");
   }
   */


   iter = 0;
   while(iter < n_iter)
   {
      for(int i=0; i<*nl; i++)
      {
         step[i] = (var_max[i]-var_min[i])/grid_size;
      }

      grid_min = 1e10;

      //Evaluate Grid
      //--------------------------------
      for(idx=0; idx<grid_positions; idx++)
      {
         GetVarsAtGridIdx(idx, *nl, grid_size, var_min, step, alf);


         if (alf[0] > alf[1])
         {
            // Evaulate grid position
            dpa_(s, l, lmax, nl, n, nmax, ndim, lpps1, lps, pp2, iv, t, y, 
                 w, alf, (U_fp)ada, err, iprint, a, b, beta, a + (*l)*(*n),
                 grid+idx, gc, thread, static_store);
              
            *err=2;
         
            if (grid[idx] < grid_min && grid[idx] > 0)
            {
               grid_min_idx = idx;
               grid_min = grid[idx];
            }
         }
         else
         {
            grid[idx] = 1e10;
         }
      }

      // Get vars at grid min
      GetVarsAtGridIdx(grid_min_idx, *nl, grid_size, var_min, step, alf);

      for(int i=0; i<*nl; i++)
      {
         double var_dist = 0.5 * (var_max[i] - var_min[i]) / grid_factor;
         
         if (alf[i]+var_dist < var_max[i])
         {
            var_max[i] = alf[i] + var_dist;

            if (alf[i]-var_dist < var_min[i])
               var_max[i] = var_min[i] + 2*var_dist;
            else
               var_min[i] = alf[i]-var_dist;
            
         }
         else
         {
            var_min[i] = var_max[i] - 2*var_dist; 
         }
      }

      //if (write_to_file && f!=NULL)
      //   fwrite(grid,sizeof(double),grid_positions,f);
      
      iter++;
   }

   *err = 2;

   // Calculate final quantities
   //-----------------------------
   dpa_(s, l, lmax, nl, n, nmax, ndim, lpps1, lps, pp2, iv, t, y,
       w, alf, (U_fp)ada, err, iprint, a, b, beta, a + (*l)*(*n),
       r__, gc, thread, static_store);
     postpr_(s, l, lmax, nl, n, nmax, ndim, &lnls1, lps, pp2,
          &eps1, r__, iprint, alf, w, a, b, a + (*l)*(*n), beta, err);

     //if (write_to_file && f!=NULL)
     //   fclose(f);


}

void GetVarsAtGridIdx(int idx, int nl, int grid_size, double var_min[], double var_step[], double var[])
{
   // Get variable's at grid position
   //-----------------------------------
   int cur_idx = idx;
   for(int i=0; i<nl; i++)
   {
      double var_max = var_min[i] + var_step[i] * grid_size;
      int var_idx = cur_idx % grid_size;
      cur_idx = cur_idx / grid_size;
      var[i] = var_min[i] + var_step[i] * var_idx;
      var[i] = tau2alf(var[i],var_min[i],var_max);
   }
}


#ifdef __cplusplus
   }
#endif
