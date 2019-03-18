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

#include <boost/serialization/type_info_implementation.hpp>
#include <boost/serialization/shared_ptr.hpp>
#include <boost/serialization/vector.hpp>
#include <boost/serialization/base_object.hpp>

#include <vector>
#include <memory>


enum Polarisation
{
   Unpolarised = 0,
   Parallel = 1,
   Perpendicular = 2
};

class AcquisitionParameters
{
public:

   AcquisitionParameters(int data_type = 0, double t_rep = 12500.0, int n_chan = 1, double counts_per_photon = 1);

   void setImageSize(int n_x, int n_y);
   void setT(int n_t_full, double t_[], double t_int_[]);
   
   void setT(const std::vector<double>& t_);
   void setIntegrationTimes(std::vector<double>& t_int_);
   
   void setPolarisation(const std::vector<Polarisation>& pol_);

   double* getT();
   const std::vector<double>& getTimePoints();
   
   int data_type;

   int n_x = 1;
   int n_y = 1;

   int n_t_full = 1;
   int n_chan = 1;
   
   double  counts_per_photon = 1;
   double  t_rep;
   
   std::vector<double> t;
   std::vector<double> t_int;
   std::vector<Polarisation> polarisation;

   // Computed parameters
   int n_px;
   int n_meas_full;
   bool equally_spaced_gates;

protected:

   void checkGateSpacing();
   
private:
   
   template<class Archive>
   void serialize(Archive & ar, const unsigned int version);
   
   friend class boost::serialization::access;
};

BOOST_CLASS_VERSION(AcquisitionParameters, 2)


template<class Archive>
void AcquisitionParameters::serialize(Archive & ar, const unsigned int version)
{
   bool polarisation_resolved;

   ar & data_type;
   if (version <= 1)
      ar & polarisation_resolved;
   ar & n_x;
   ar & n_y;
   ar & n_t_full;
   ar & n_chan;
   ar & counts_per_photon;
   ar & t_rep;
   ar & t;
   ar & t_int;
   if (version >= 2)
      ar & polarisation;
   ar & n_px;
   ar & n_meas_full;
   ar & equally_spaced_gates;
}