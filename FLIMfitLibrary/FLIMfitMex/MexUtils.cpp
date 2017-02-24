#pragma once

#include "MexUtils.h"
#include <cv.h>

void checkInputCondition(char* text, bool condition)
{
   if (!condition)
      mexErrMsgIdAndTxt("FLIMfitMex:invalidInput", text);
}

std::string getStringFromMatlab(const mxArray* dat)
{
   if (mxIsChar(dat))
   {
      size_t buflen = mxGetN(dat) * sizeof(mxChar) + 1;
      char* buf = (char*)mxMalloc(buflen);

      mxGetString(dat, buf, (mwSize)buflen);

      return std::string(buf);
   }

   mexWarnMsgIdAndTxt("MATLAB:mxmalloc:invalidInput",
      "Unable to retrieve string");

   return std::string();
}

void checkSize(const mxArray* array, int needed)
{
   if (needed != mxGetNumberOfElements(array))
      mexErrMsgIdAndTxt("MATLAB:mxmalloc:invalidInput",
         "Input array is the wrong size");
}

mxArray* mxCreateUint64Scalar(uint64_t v)
{
   mxArray* m = mxCreateNumericMatrix(1, 1, mxUINT64_CLASS, mxREAL);
   uint64_t* mp = (uint64_t*)mxGetData(m);
   mp[0] = v;
   return m;
}

mxArray* getFieldFromStruct(const mxArray* s, const char *field)
{
   int field_number = mxGetFieldNumber(s, field);
   if (field_number == -1)
   {
      std::string err = std::string("Missing field in structure: ").append(field);
      mexErrMsgIdAndTxt("FLIMfit:missingField", err.c_str());
   }

   return mxGetFieldByNumber(s, 0, field_number);
}

double getValueFromStruct(const mxArray* s, const char *field, double default_value)
{
   int field_number = mxGetFieldNumber(s, field);
   if (field_number == -1)
      return default_value;

   const mxArray* v = mxGetFieldByNumber(s, 0, field_number);

   if (!mxIsScalar(v))
   {
      std::string err = std::string("Expected field to be scalar: ").append(field);
      mexErrMsgIdAndTxt("FLIMfit:missingField", err.c_str());
   }

   return mxGetScalar(v);
}

double getValueFromStruct(const mxArray* s, const char *field)
{
   const mxArray* v = getFieldFromStruct(s, field);

   if (!mxIsScalar(v))
   {
      std::string err = std::string("Expected field to be scalar: ").append(field);
      mexErrMsgIdAndTxt("FLIMfit:missingField", err.c_str());
   }

   return mxGetScalar(v);
}

cv::Mat getCvMat(const mxArray* im)
{
   int type;
   if (mxIsDouble(im))
      type = CV_64F;
   else if (mxIsSingle(im))
      type = CV_32F;
   else if (mxIsInt32(im))
      type = CV_32S;
   else if (mxIsInt16(im))
      type = CV_16S;
   else if (mxIsInt8(im))
      type = CV_8S;
   else if (mxIsUint16(im))
      type = CV_16U;
   else if (mxIsUint8(im))
      type = CV_8U;
   else
      mexErrMsgIdAndTxt("FLIMfit:invalidInput",
         "Image was not of an acceptable type");

   AssertInputCondition(mxIsDouble(im));
   AssertInputCondition(mxGetNumberOfDimensions(im) == 2);
   int n = (int) mxGetN(im);
   int m = (int) mxGetM(im);

   return cv::Mat(n, m, type, mxGetData(im));
}

mxArray* convertCvMat(const cv::Mat im)
{
   int type = im.type();
   int data_size;
   mxClassID mtype;
   if (type == CV_64F)
   {
      mtype = mxDOUBLE_CLASS;
      data_size = 8;
   }
   else if (type == CV_32F)
   {
      mtype = mxSINGLE_CLASS;
      data_size = 4;
   }
   else if (type == CV_32S)
   {
      mtype = mxINT32_CLASS;
      data_size = 4;
   }
   else if (type == CV_16S)
   {
      mtype = mxINT16_CLASS;
      data_size = 2;
   }
   else if (type == CV_16U)
   {
      mtype = mxUINT16_CLASS;
      data_size = 2;
   }
   else if (type == CV_8S)
   {
      mtype = mxINT8_CLASS;
      data_size = 1;
   }
   else if (type == CV_8U)
   {
      mtype = mxUINT8_CLASS;
      data_size = 1;
   }
   else
      mexErrMsgIdAndTxt("FLIMfit:invalidInput",
         "Image was not of an acceptable type");

   mxArray* a = mxCreateNumericMatrix(im.rows, im.cols, mtype, mxREAL);
   char* ptr = reinterpret_cast<char*>(mxGetData(a));

   for (int i = 0; i < im.rows; i++)
      memcpy(ptr + i*im.cols*data_size, im.data + i*im.step, im.cols*data_size);

   return a;
}


bool isArgument(int nrhs, const mxArray *prhs[], const char* arg, int nstart)
{
   for (int i = nstart; (i + 1) < nrhs; i++)
   {
      if (mxIsChar(prhs[i]) && getStringFromMatlab(prhs[i]) == arg)
         return true;
   }
   return false;
}

const mxArray* getNamedArgument(int nrhs, const mxArray *prhs[], const char* arg, int nstart)
{
   for (int i = nstart; (i + 1) < nrhs; i += 2)
   {
      if (mxIsChar(prhs[i]) && getStringFromMatlab(prhs[i]) == arg)
         return prhs[i + 1];
   }

   std::string err = std::string("Missing argument: ").append(arg);
   mexErrMsgIdAndTxt("FLIMfit:missingArgument", err.c_str());
   return static_cast<const mxArray*>(nullptr);
}

void CheckInput(int nrhs, int needed)
{
   if (nrhs < needed)
      mexErrMsgIdAndTxt("MATLAB:mxmalloc:invalidInput",
         "Not enough input arguments");
}