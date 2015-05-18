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
   /*
   if (data_mode == MappedFile)
   {
      boost::filesystem::wpath file(map_file_name);
      if(boost::filesystem::exists(file))
         boost::filesystem::remove(file);
   }
    */
}

void FLIMImage::init()
{
   if (stored_type == typeid(float))
      data_class = DataFloat;
   else if (stored_type == typeid(uint16_t))
      data_class = DataUint16;
   else
      throw std::runtime_error("Unsupported data type");
   
   int n_bytes = 1;
   if (stored_type == typeid(float))
      n_bytes = 4;
   else if (stored_type == typeid(uint16_t))
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
         
         const int bufsize = 1024*1024;
         vector<char> zeros(bufsize);
         int nrep = map_length / bufsize + 1;
         
         // Write zeros
         for(int i=0; i<nrep; i++)
            of.write(zeros.data(), bufsize);
      }
      
      // Create mapping
      data_map_file = boost::interprocess::file_mapping(map_file_name.c_str(),boost::interprocess::read_write);
   }
}

void FLIMImage::getDecay(cv::Mat mask, std::vector<std::vector<double>>& decay)
{
   if (stored_type == typeid(float))
      getDecayImpl<float>(mask, decay);
   else if (stored_type == typeid(uint16_t))
      getDecayImpl<uint16_t>(mask, decay);
}
