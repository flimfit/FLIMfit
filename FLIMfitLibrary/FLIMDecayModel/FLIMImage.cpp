#include "FLIMImage.h"
#include <boost/filesystem.hpp>


FLIMImage::FLIMImage(shared_ptr<AcquisitionParameters> acq, std::type_index type, const std::string& name, DataMode data_mode, const std::string& root) :
acq(acq),
stored_type(type),
name(name),
data_mode(data_mode),
root(root)
{
   init();
}

FLIMImage::~FLIMImage()
{
   
   if (data_mode == MappedFile)
   {
      
   }
}

void FLIMImage::init()
{
   if (stored_type == typeid(void)) // Loaded from saved file - we know data_class but not stored type
   {
      if (data_class == DataFloat)
         stored_type = typeid(float);
      else if (data_class == DataUint16)
         stored_type = typeid(uint16_t);
   }
   else
   {
      if (stored_type == typeid(float))
         data_class = DataFloat;
      else if (stored_type == typeid(uint16_t))
         data_class = DataUint16;
      else
         throw std::runtime_error("Unsupported data type");
   }
   
   int n_bytes = 1;
   if (data_class == DataFloat)
      n_bytes = 4;
   else if (data_class == DataUint16)
      n_bytes = 2;
   
   map_length = acq->n_px * acq->n_meas_full * n_bytes;
   
   if (data_mode == InMemory)
   {
      data.resize(map_length);
   }
   else
   {
      if (root.empty())
      {
         // Get temp filename
         boost::filesystem::path temp = boost::filesystem::unique_path();
         map_file_name = temp.native();
      }
      else
      {
         boost::filesystem::path dir(root);
         map_file_name = root;
         map_file_name.append("/").append(name).append(".ffdata");
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
