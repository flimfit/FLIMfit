/*
 Trimmed mean code from: 
 Fast Computation of Trimmed Means. Gleb Beliakov
 http://www.jstatsoft.org/v39/c02/paper
*/

#define SWAP(a,b) temp=(a);(a)=(b);(b)=temp;

template <typename T>
float quickselect(T *arr, int span, unsigned long n, unsigned long k) 
{
   unsigned long i,ir,j,l,mid;
   T a,temp;

   l=0;
   ir=n-1;
   for(;;) 
   {
      if (ir <= l+1) 
      { 
         if (ir == l+1 && arr[ir*span] < arr[l*span]) 
         {
            SWAP(arr[l*span],arr[ir*span]);
         }
         return arr[k*span];
      }
      else 
      {
         mid=(l+ir) >> 1; 
         SWAP(arr[mid*span],arr[(l+1)*span]);
         if (arr[l*span] > arr[ir*span]) 
         {
            SWAP(arr[l*span],arr[ir*span]);
         }
         if (arr[(l+1)*span] > arr[ir*span]) 
         {
            SWAP(arr[(l+1)*span],arr[ir*span]);
         }
         if (arr[l*span] > arr[(l+1)*span]) 
         {
            SWAP(arr[l*span],arr[(l+1)*span]);
         }
         i=l+1; 
         j=ir;
         a=arr[(l+1)*span]; 
         for (;;)
         { 
            do i++; while (arr[i*span] < a && arr[i*span] == arr[i*span] && i<n-1); 
            do j--; while (arr[j*span] > a && arr[j*span] == arr[j*span] && j>0); 
            if (j < i) break; 
            SWAP(arr[i*span],arr[j*span]);
         } 
         arr[(l+1)*span]=arr[j*span]; 
         arr[j*span]=a;
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
void TrimmedMean(T x[], int span, int n, int K, T& mean, T& std)
{
   T w1, w2, OS1, OS2, wt;
   
   T mean_sq = 0;
   mean = 0;
   std = 0;

   OS1=quickselect(x, span, n, K);
   OS2=quickselect(x, span, n, n-K-1);

   // compute weights
   T a, b=0, c, d=0, dm=0, bm=0, r;

   for(int i=0; i<n; i++)
   {
      r = x[i*span];
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
      mean_sq = 0;
   }
   else
   {
      for(int i=0; i<n; i++)
      {
         wt = Weighted(x[i*span], OS1, OS2, w1, w2);
         mean += wt;
         mean_sq += wt * wt;
      } 

      mean /= (n-2*K);
      mean_sq /= (n-2*K);

   }

   std -= (mean * mean); 
   std = sqrt(std);

}
