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

#ifndef _FLAGDEFINITIONS_H
#define _FLAGDEFINITIONS_H

enum FittingAlgorithm
{
   VariableProjection = 0,
   MaximumLikelihood = 1
};

enum GlobalScope
{
   Pixelwise = 0,
   Imagewise = 1,
   Global = 2
};

enum GlobalAlgorithm
{
   GlobalBinning = 0,
   GlobalAnalysis = 1
};

enum WeightingMode
{
   AverageWeighting = 0,
   PixelWeighting = 1
};


enum PARAM_IDX { PARAM_MEAN, PARAM_W_MEAN, PARAM_STD, PARAM_W_STD, PARAM_MEDIAN, 
                 PARAM_Q1, PARAM_Q2, PARAM_01, PARAM_99, PARAM_ERR_LOWER, PARAM_ERR_UPPER };

const int N_STATS = 11;


#define DATA_DIRECT 0
#define DATA_MAPPED 1

//----------------------------------------------
#define MODE_STANDARD     0
#define MODE_POLARISATION 1

//----------------------------------------------
#define DATA_FLOAT 0
#define DATA_UINT16 1

//----------------------------------------------
#define BG_NONE     0
#define BG_VALUE    1
#define BG_IMAGE    2
#define BG_TV_IMAGE 3

//----------------------------------------------
#define APPLY_ANSCOME_TRANSFORM  0

//----------------------------------------------
#define FIX            0
#define FIT_LOCALLY    1
#define FIT_GLOBALLY   2
#define FIT            1

//----------------------------------------------
#define DATA_TYPE_TCSPC     0
#define DATA_TYPE_TIMEGATED 1

//----------------------------------------------
#define MAX_CONTROLLER_IDX 255

//----------------------------------------------
#define SUCCESS                        0
#define ERR_NOT_INIT                   -1001
#define ERR_FIT_IN_PROGRESS            -1002
#define ERR_FAILED_TO_START_THREADS    -1003
#define ERR_NO_FIT                     -1004
#define ERR_OUT_OF_MEMORY              -1005
#define ERR_COULD_NOT_OPEN_MAPPED_FILE -1006
#define ERR_COULD_NOT_START_FIT        -1007
#define ERR_FOUND_NO_REGIONS           -1008
#define ERR_FAILED_TO_MAP_DATA         -1009
#define ERR_INVALID_INPUT              -1010
#define ERR_INVALID_IDX                -1012

#define WARN_DECAY_GROUPS_NOT_CONSISTENT -2001

/*
#define _CRTDBG_MAP_ALLOC
#ifdef _DEBUG   
#ifndef DBG_NEW     
#define DBG_NEW new ( _NORMAL_BLOCK , __FILE__ , __LINE__ )      
#define new DBG_NEW   
#endif
#endif  // _DEBUG
*/

#endif
