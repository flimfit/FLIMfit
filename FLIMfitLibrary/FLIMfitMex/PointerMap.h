#pragma once

#include <memory>
#include <map>

template<class T,class ...Args>
class PointerMap
{
public:

   int CreateObject(Args... args)
   {
      int id = next_id;
      next_id++;

      object_map.insert(std::pair<int, std::shared_ptr<T>>(id, std::make_shared<T>(args...)));
      return id;
   }

   std::shared_ptr<T> Get(int idx)
   {
      auto iter = object_map.find(idx);
      if (iter == object_map.end() || iter->second == nullptr)
         return nullptr;
      return iter->second;
   }

   void Clear(int idx)
   {
      object_map.erase(idx);
   }

   void Clear()
   {
      object_map.clear();
   }


protected:
   std::map<int, std::shared_ptr<T>> object_map;
   int next_id = 0;
};