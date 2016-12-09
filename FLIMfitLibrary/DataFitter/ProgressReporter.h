#pragma once
#include <string>

class ProgressReporter
{
public:
   
   ProgressReporter(const std::string& task_name, int sub_tasks = 0) :
   task_name(task_name),
   sub_tasks(sub_tasks)
   {
      sub_tasks_completed = 0;
      progress = 0;
   }

   void reset()
   {
      progress = 0;
      finished = false;
      termination_requested = false;
      sub_tasks_completed = 0;
   }
   
   virtual void setInterderminate()
   {
      indeterminate = true;
      progressUpdated();
   }
   
   void setProgress(double progress_)
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
   
   void subTaskCompleted()
   {
      sub_tasks_completed = sub_tasks_completed + 1;
      progress = static_cast<double>(sub_tasks_completed) / sub_tasks;
      progressUpdated();
      
      if (sub_tasks_completed == sub_tasks)
         setFinished();
   }
   
   double getProgress() { return progress; }
   bool isIndeterminate() { return indeterminate; }
   bool isFinished() { return finished; }
   const std::string& getTaskName() { return task_name; }
protected:

   virtual void progressUpdated() {};
   
   std::string task_name;
   int sub_tasks;
   std::atomic<int> sub_tasks_completed;
   std::atomic<double> progress;
   bool indeterminate = false;
   bool termination_requested = false;
   bool finished = false;
};