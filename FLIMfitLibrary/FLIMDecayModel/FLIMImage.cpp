#include "FLIMImage.h"
#include <boost/filesystem.hpp>

using std::shared_ptr;

FLIMImage::FLIMImage(shared_ptr<AcquisitionParameters> acq, std::type_index type, const std::string& name, DataMode data_mode, const std::string& root) :
acq(acq),
stored_type(type),
name(name),
data_mode(data_mode),
root(root)
{
   init();
}

FLIMImage::FLIMImage(shared_ptr<AcquisitionParameters> acq, const std::string& map_file_name, DataClass data_class, int map_offset) :
   acq(acq),
   map_file_name(map_file_name),
   data_class(data_class),
   map_offset(map_offset),
   stored_type(typeid(void))
{
   has_data = true;
   init();

   if (data_class == DataUint16)
      compute<uint16_t>();
   else if (data_class == DataUint32)
      compute<uint32_t>();
   else if (data_class == DataFloat)
      compute<float>();
}

FLIMImage::FLIMImage(shared_ptr<AcquisitionParameters> acq, DataMode data_mode, DataClass data_class, void* data_) : 
   acq(acq),
   data_mode(data_mode),
   data_class(data_class),
   stored_type(typeid(void))
{
   init();

   if (data_class == DataUint16)
      setData(static_cast<uint16_t*>(data_));
   else if (data_class == DataUint32)
      setData(static_cast<uint32_t*>(data_));
   else if (data_class == DataFloat)
      setData(static_cast<float*>(data_));
}

FLIMImage::~FLIMImage()
{
   
   if (data_mode == MappedFile)
   {
      
   }
}

void FLIMImage::init()
{
   if (stored_type == typeid(void)) // We know data_class but not stored type
   {
      if (data_class == DataFloat)
         stored_type = typeid(float);
      else if (data_class == DataUint32)
         stored_type = typeid(uint32_t);
      else if (data_class == DataUint16)
         stored_type = typeid(uint16_t);
   }
   else
   {
      if (stored_type == typeid(float))
         data_class = DataFloat;
      else if (stored_type == typeid(uint32_t))
         data_class = DataUint32;
      else if (stored_type == typeid(uint16_t))
         data_class = DataUint16;
      else
         throw std::runtime_error("Unsupported data type");
   }
   
   int n_bytes = 1;
   if (data_class == DataFloat)
      n_bytes = 4;
   else if (data_class == DataUint32)
      n_bytes = 4;
   else if (data_class == DataUint16)
      n_bytes = 2;
   
   map_length = acq->n_px * acq->n_meas_full * n_bytes;
}

void FLIMImage::ensureAllocated()
{
   if (allocated)
      return;
   
   if (data_mode == InMemory)
   {
      data.resize(map_length);
   }
   else
   {
      if (map_file_name.empty())
      {
         if (root.empty())
         {
            // Get temp filename
            boost::filesystem::path temp = boost::filesystem::unique_path();
            map_file_name = temp.generic_string();
         }
         else
         {
            boost::filesystem::path dir(root);
            map_file_name = root;
            map_file_name.append("/").append(name).append(".ffdata");
         }
      }
      
      boost::filesystem::path file(map_file_name);
      if (!boost::filesystem::exists(file) || !(boost::filesystem::file_size(file) >= map_length))
      {
         std::ofstream of(map_file_name, std::ofstream::binary);
         of.seekp(map_length, std::ios_base::beg);
         of.put(0);
      }
      
      // Create mapping
      data_map_file = boost::interprocess::file_mapping(map_file_name.c_str(),boost::interprocess::read_write);
   }
   
   allocated = true;
}


cv::Mat FLIMImage::getIntensity()
{
   waitForData();
   return intensity;
}

void FLIMImage::waitForData()
{
   // See if the image data has been set
   if (!has_data)
   {
      // Do we have a reader future?
      if (reader_future.valid())
         reader_future.get();
      else
         throw std::runtime_error("No data loaded yet!");
   }
}

void FLIMImage::getDecay(cv::Mat mask, std::vector<std::vector<double>>& decay)
{
   if (stored_type == typeid(float))
      getDecayImpl<float>(mask, decay);
   else if (stored_type == typeid(uint16_t))
      getDecayImpl<uint16_t>(mask, decay);
}

std::shared_ptr<FLIMImage> FLIMImage::getRegionAsImage(cv::Mat mask)
{
   if (stored_type == typeid(float))
      return getRegionAsImageImpl<float>(mask);
   else if (stored_type == typeid(uint16_t))
      return getRegionAsImageImpl<uint16_t>(mask);
   
   return nullptr;
}
