
#ifndef _FITSTATUS_H
#define _FITSTATUS_H

#include "tinythread.h"
//#include "ModelADA.h"

class FLIMGlobalFitController;

class FitStatus
{
   //HANDLE running_mutex;
   //boost::interprocess::interprocess_mutex running_mutex;
   tthread::mutex running_mutex;
   int (*callback)();

public:

   int n_thread;
   int n_group;
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

   FitStatus(FLIMGlobalFitController* gc, int n_group, int n_thread, int (*callback)());
   ~FitStatus();

   int UpdateStatus(int thread, int t_group, int t_iter, double t_chi2);
   void FinishedGroup(int thread);
   void CalculateProgress();
   void Terminate();
   void AddThread();
   int RemoveThread();
   bool Finished();
   bool HasFit();
   bool IsRunning();
};


#endif
