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

#include <thread>
#include <mutex>
#include <list>

//class DecayModel;

using std::list;

//double norm_chi2(DecayModel* gc, double chi2, int s, bool fixed = false);

class FitStatus
{
   std::recursive_mutex running_mutex;
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

   FitStatus(int n_thread, int (*callback)() = nullptr);
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
   void AddConditionVariable(std::condition_variable* cond);

   list<std::condition_variable*> cond_list;
};
