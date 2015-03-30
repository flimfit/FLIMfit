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

#include "FitStatus.h"
#include <math.h>



/*

double norm_chi2(DecayModel* gc, double chi2, int s, bool fixed_param)
{
   return chi2 * chi2 / (gc->n_meas * s - (gc->nl-(int)fixed_param) - s*gc->l);
}

*/


FitStatus::FitStatus(int n_thread, int (*callback)()) : 
   n_thread(n_thread), callback(callback), n_region(0),
   progress(0), threads_running(0),  terminate(0), has_fit(0), running(0)
{
   group = new int[n_thread];
   n_completed = new int[n_thread];
   iter = new int[n_thread];
   chi2 = new double[n_thread];

   for(int i=0; i<n_thread; i++)
   {
      group[i] = 0;
      n_completed[i] = 0;

      iter[i] = 0;
      chi2[i] = 0;
   }

   started = false;

}

FitStatus::~FitStatus()
{
   delete[] group;
   delete[] iter;
   delete[] chi2;
   delete[] n_completed;

}


void FitStatus::SetNumRegion(int n_group)
{
   this->n_region = n_group;
}


void FitStatus::FinishedRegion(int thread)
{
   n_completed[thread]++;
}

void FitStatus::AddThread()
{
   tthread::lock_guard<tthread::recursive_mutex> lock(running_mutex);
   started = true;
   running = true;
   threads_running++;
}

int FitStatus::RemoveThread()
{
   tthread::lock_guard<tthread::recursive_mutex> lock(running_mutex);
   --threads_running;
   has_fit = threads_running == 0;
   running = threads_running > 0;
   return threads_running;
}

void FitStatus::CalculateProgress()
{
   double p = 0;
   for(int i=0; i<n_thread; i++)
   {
      p += n_completed[i]; 
   }
   p = p / (double) n_region;

   progress = p;
}

int FitStatus::UpdateStatus(int thread, int t_group, int t_iter, double t_chi2)
{
   double progress = 0;

   if (t_group >= 0)
      group[thread] = t_group;
   iter[thread] = t_iter;
   chi2[thread] = t_chi2; // TODO: norm_chi2(gc, t_chi2, 1);

   for(int i=0; i<n_thread; i++)
   {
      progress += n_completed[i]; 
   }
   progress /= (double) n_region;

   if (callback != 0)
   {
      int ret = 1; //callback(n_thread,n_completed,group,iter,chi2,progress);
      if (ret == 0)
         terminate = 1;
   }

   return terminate;
}


void FitStatus::AddConditionVariable(tthread::condition_variable* cond)
{
   // Add a condition variable that might need to be notified when we terminate

   cond_list.push_back(cond);
}

void FitStatus::Terminate()
{
   terminate = true;

   while(threads_running > 0)
   {
      // Wake up any threads that are sleeping
      for (std::list<tthread::condition_variable*>::const_iterator it = cond_list.begin(), end = cond_list.end(); it != end; it++)
            (*it)->notify_all();
   }

}

bool FitStatus::Finished()
{
   if ( running_mutex.try_lock() )
   {
      bool finished = false; 
      if (terminate && !started)
         finished = true;
      else
         finished = !running && started;
      running_mutex.unlock();
      return finished;
   }
   else 
      return false;
}

bool FitStatus::HasFit()
{
   if ( running_mutex.try_lock() )
   {
      bool ret =  has_fit && !running;
      running_mutex.unlock();
      return ret;
   }
   else 
      return false;
}

bool FitStatus::IsRunning()
{
   if ( running_mutex.try_lock() )
   {
      bool ret = running;
      running_mutex.unlock();
      return ret;
   }
   else
      return true;
}