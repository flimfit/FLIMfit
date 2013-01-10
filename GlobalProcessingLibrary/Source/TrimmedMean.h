/*
 Trimmed mean code from: 
 Fast Computation of Trimmed Means. Gleb Beliakov
 http://www.jstatsoft.org/v39/c02/paper
*/
#include "util.h"
#define SWAP(a,b) temp=(a);(a)=(b);(b)=temp;

template <typename T>
float quickselect(T *arr, unsigned long n, unsigned long k) 
{
   unsigned long i,ir,j,l,mid;
   T a,temp;

   l=0;
   ir=n-1;
   for(;;) 
   {
      if (ir <= l+1) 
      { 
         if (ir == l+1 && arr[ir] < arr[l]) 
         {
            SWAP(arr[l],arr[ir]);
         }
         return arr[k];
      }
      else 
      {
         mid=(l+ir) >> 1; 
         SWAP(arr[mid],arr[(l+1)]);
         if (arr[l] > arr[ir]) 
         {
            SWAP(arr[l],arr[ir]);
         }
         if (arr[(l+1)] > arr[ir]) 
         {
            SWAP(arr[(l+1)],arr[ir]);
         }
         if (arr[l] > arr[(l+1)]) 
         {
            SWAP(arr[l],arr[(l+1)]);
         }
         i=l+1; 
         j=ir;
         a=arr[(l+1)]; 
         for (;;)
         { 
            do i++; while (arr[i] < a && i<n-1); 
            do j--; while (arr[j] > a && j>0); 
            if (j < i) break; 
            SWAP(arr[i],arr[j]);
         } 
         arr[(l+1)]=arr[j]; 
         arr[j]=a;
         if (j >= k) ir=j-1; 
         if (j <= k) l=i;
      }
   }
}

template <typename T>
float Weighted(T x, T t1, T t2, T w1, T w2)
{
   if(x<t2 && x>t1) return x;
   if(x<t1) return 0;
   if(x>t2) return 0;
   if(x==t1) return w1*x;
   return w2*x; // if(x==t2)
}

template <typename T>
void TrimmedMean(T x[], int n, int K, T& mean, T& std, T& median, T& q1, T& q2, T& pct_lower, T& pct_upper)
{
   T w1, w2, OS1, OS2, wt;
   
   double mean_sq = 0;
   double mean_acc = 0;
   std = 0;

   if (n == 0)
   {
      SetNaN(&mean,1);
      SetNaN(&std,1);
      SetNaN(&pct_lower,1);
      SetNaN(&pct_upper,1);
      return;
   }

   OS1=quickselect(x, n, K);
   q1 = quickselect(x, n, (unsigned long)(0.25*n));
   median=quickselect(x, n, (unsigned long)(0.5*n));
   q2 = quickselect(x, n, (unsigned long)(0.75*n));
   OS2=quickselect(x, n, n-K-1);

   
   // compute weights
   T a, b=0, c, d=0, dm=0, bm=0, r;

   for(int i=0; i<n; i++)
   {
      r = x[i];
      if(r < OS1) bm += 1;
      else if(r == OS1) b += 1;
      if(r < OS2) dm += 1;
      else if(r == OS2) d += 1;
   }

   a = b + bm - K;
   c = n - K - dm;
   w1 = a/b;
   w2 = c/d;

   if (OS1==OS2)
   {
      mean = x[0];
      median = x[0];
      q1 = x[0];
      q2 = x[0];
      std = 0;
   }
   else
   {
      int zc = 0;
      for(int i=0; i<n; i++)
      {
         wt = Weighted(x[i], OS1, OS2, w1, w2);
         mean_acc += wt;
         mean_sq += wt * wt;
         if (wt == 0)
            zc++;
      } 

      mean_acc /= (n-2*K);
      mean_sq /= (n-2*K);

      std = (T) (mean_sq - (mean_acc * mean_acc)); 
      std = sqrt(std);

      mean = (T) mean_acc;

   }

   pct_lower = OS1;
   pct_upper = OS2;

}
