#pragma once

// from: https://cheind.wordpress.com/2011/12/06/serialization-of-cvmat-objects-using-boost/

#include <opencv2/opencv.hpp>
#include <boost/serialization/split_free.hpp>
#include <boost/serialization/vector.hpp>

BOOST_SERIALIZATION_SPLIT_FREE(::cv::Mat)
namespace boost {
   namespace serialization {
      
      /** Serialization support for cv::Mat */
      template<class Archive>
      void save(Archive & ar, const ::cv::Mat& m, const unsigned int version)
      {
         size_t elem_size = m.elemSize();
         int elem_type = m.type();
         
         ar & m.cols;
         ar & m.rows;
         ar & elem_size;
         ar & elem_type;
         
         const size_t data_size = m.cols * m.rows * elem_size;
         ar & boost::serialization::make_array(m.ptr(), data_size);
      }
      
      /** Serialization support for cv::Mat */
      template<class Archive>
      void load(Archive & ar, ::cv::Mat& m, const unsigned int version)
      {
         int cols, rows, elem_type;
         size_t elem_size;
         
         ar & cols;
         ar & rows;
         ar & elem_size;
         ar & elem_type;
         
         m.create(rows, cols, elem_type);
         
         size_t data_size = m.cols * m.rows * elem_size;
         ar & boost::serialization::make_array(m.ptr(), data_size);
      }
      
   }
}