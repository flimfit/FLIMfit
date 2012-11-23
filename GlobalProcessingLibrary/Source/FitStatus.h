
#ifndef _FITSTATUS_H
#define _FITSTATUS_H

#include "tinythread.h"

class FLIMGlobalFitController;

double norm_chi2(FLIMGlobalFitController* gc, double chi2, int s, bool fixed = false);

class FitStatus
{
   tthread::recursive_mutex running_mutex;
   int (*callback)();

public:

   int n_thread;
   int n_region;
   double progress;
   int threads_running;
 
   int* group;
   int* n_completed;
   int* iter;
   double* chi2;

   int terminate;

   bool has_fit;
   bool running;
   bool started;

   FLIMGlobalFitController* gc;

   FitStatus(FLIMGlobalFitController* gc, int n_thread, int (*callback)());
   ~FitStatus();

   void SetNumRegion(int n_region);
   int UpdateStatus(int thread, int t_group, int t_iter, double t_chi2);
   void FinishedRegion(int thread);
   void CalculateProgress();
   void Terminate();
   void AddThread();
   int RemoveThread();
   bool Finished();
   bool HasFit();
   bool IsRunning();
};


#endif
