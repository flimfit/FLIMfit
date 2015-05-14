#pragma once

class ProgressReporter
{
public:
   
   ProgressReporter()
   {
      
   }
   
   virtual void setInterderminate()
   {
      indeterminate = true;
      progressUpdated();
   }
   
   void setProgress(float progress_)
   {
      progress = progress_;
      progressUpdated();
   }

   void requestTermination()
   {
      termination_requested = true;
   }
   
   bool shouldTerminate()
   {
      return termination_requested;
   }
   
   void setFinished()
   {
      finished = true;
   }
   
   float getProgress() { return progress; }
   bool isIndeterminate() { return indeterminate; }
   bool isFinished() { return finished; }
protected:

   virtual void progressUpdated() {};
   
   float progress = 0;
   bool indeterminate = false;
   bool termination_requested = false;
   bool finished = false;
};