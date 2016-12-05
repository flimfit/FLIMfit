#pragma once

#include <mex.h>
#include <string>
#include <vector>

#define AssertInputCondition(x) CheckInputCondition(#x, x);
void CheckInputCondition(char* text, bool condition)
{
   if (!condition)
      mexErrMsgIdAndTxt("FLIMfitMex:invalidInput", text);
}

using std::string;

string GetStringFromMatlab(const mxArray* dat)
{
   if (mxIsChar(dat))
   {
      size_t buflen = mxGetN(dat)*sizeof(mxChar) + 1;
      char* buf = (char*)mxMalloc(buflen);

      mxGetString(dat, buf, (mwSize)buflen);

      return string(buf);
   }

   mexWarnMsgIdAndTxt("MATLAB:mxmalloc:invalidInput",
      "Unable to retrieve string");

   return string();
}

template<typename T>
T GetHandleScalar(const mxArray* handle, const char* prop, T default_value = std::numeric_limits<T>::quiet_NaN())
{
   if (mxArray* a = mxGetProperty(handle, 0, prop))
      return (T)mxGetScalar(a);

   mexWarnMsgIdAndTxt("MATLAB:mxmalloc:invalidInput",
      "Unable to retrieve property");

   return default_value;
}

template<typename T>
T GetHandleArrayIdx(const mxArray* handle, const char* prop, int idx, T default_value = std::numeric_limits<T>::quiet_NaN())
{
   if (const mxArray* a = mxGetProperty(handle, 0, prop))
      if (mxGetNumberOfElements(a) > idx)
         return (T)((double*)mxGetData(a))[idx];

   mexWarnMsgIdAndTxt("MATLAB:mxmalloc:invalidInput",
      "Unable to retrieve property");

   return default_value;
}

template<typename T>
T GetVariableScalar(const char* prop, T default_value = std::numeric_limits<T>::quiet_NaN())
{
   if (const mxArray* a = mexGetVariablePtr("caller", prop))
      return (T)mxGetScalar(a);

   mexWarnMsgIdAndTxt("MATLAB:mxmalloc:invalidInput",
      "Unable to retrieve property");

   return default_value;

}

template<typename T>
T GetVariableArrayIdx(const char* prop, int idx, T default_value = std::numeric_limits<T>::quiet_NaN())
{
   if (const mxArray* a = mexGetVariablePtr("caller", prop))
      if (mxGetNumberOfElements(a) > idx)
         return (T)((double*)mxGetData(a))[idx];

   mexWarnMsgIdAndTxt("MATLAB:mxmalloc:invalidInput",
      "Unable to retrieve property");

   return default_value;
}

template<typename T>
T GetVariableArrayIdx(const mxArray* a, int idx, T default_value = std::numeric_limits<T>::quiet_NaN())
{
   if (mxGetNumberOfElements(a) > idx)
      return (T)((double*)mxGetData(a))[idx];

   mexWarnMsgIdAndTxt("MATLAB:mxmalloc:invalidInput",
      "Unable to retrieve property");

   return default_value;
}


template<typename T, typename U>
std::vector<T> GetUVector(const mxArray* v)
{
   std::vector<T> vec;
   if (mxIsNumeric(v))
      if (U* data = (U*)mxGetData(v))
      {
         size_t len = mxGetNumberOfElements(v);
         vec.resize(len);

         for (size_t i = 0; i < len; i++)
            vec[i] = static_cast<T>(data[i]);
      }
   return vec;

};

template<typename T>
std::vector<T> GetVector(const mxArray* v)
{
   if (mxIsDouble(v))
      return GetUVector<T, double>(v);
   else if (mxIsSingle(v))
      return GetUVector<T, float>(v);
   else if (mxIsInt64(v))
      return GetUVector<T, int64_t>(v);
   else if (mxIsInt32(v))
      return GetUVector<T, int32_t>(v);
   else if (mxIsInt16(v))
      return GetUVector<T, int16_t>(v);
   else if (mxIsInt8(v))
      return GetUVector<T, int8_t>(v);
   else if (mxIsUint64(v))
      return GetUVector<T, uint64_t>(v);
   else if (mxIsUint32(v))
      return GetUVector<T, uint32_t>(v);
   else if (mxIsUint16(v))
      return GetUVector<T, uint16_t>(v);
   else if (mxIsUint8(v))
      return GetUVector<T, uint8_t>(v);

   return std::vector<T>();
}

void CheckSize(const mxArray* array, int needed)
{
   if (needed != mxGetNumberOfElements(array))
      mexErrMsgIdAndTxt("MATLAB:mxmalloc:invalidInput",
      "Input array is the wrong size");
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
   int n = mxGetN(im);
   int m = mxGetM(im);

   return cv::Mat(n, m, type);
}

template<typename T>
std::vector<T> getVectorFromStruct(const mxArray* s, const char *field)
{
   mxArray* v = getFieldFromStruct(s, field);
   return GetVector<T>(v);
}

bool isArgument(int nrhs, const mxArray *prhs[], const char* arg, int nstart = 0)
{
   for (int i = nstart; (i + 1) < nrhs; i++)
   {
      if (mxIsChar(prhs[i]) && GetStringFromMatlab(prhs[i]) == arg)
         return true;
   }
   return false;
}

const mxArray* getNamedArgument(int nrhs, const mxArray *prhs[], const char* arg, int nstart = 0)
{
   for (int i = nstart; (i+1) < nrhs; i+=2)
   {
      if (mxIsChar(prhs[i]) && GetStringFromMatlab(prhs[i]) == arg)
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

template<class T>
std::shared_ptr<T> GetSharedPtrFromMatlab(const mxArray* a)
{
   if (!mxIsUint64(a))
      mexErrMsgIdAndTxt("MATLAB:mxmalloc:invalidInput",
      "Should be a pointer from Mex file");

   if (mxGetNumberOfElements(a) > 1)
      mexWarnMsgIdAndTxt("MATLAB:mxmalloc:tooManyPointers",
         "Only expected one pointer, will return first");

   return **reinterpret_cast<std::shared_ptr<T>**>(mxGetData(a));
}

template<class T>
std::vector<std::shared_ptr<T>> GetSharedPtrVectorFromMatlab(const mxArray* a)
{
   if (!mxIsUint64(a))
      mexErrMsgIdAndTxt("MATLAB:mxmalloc:invalidInput",
         "Should be a pointer from Mex file");
   
   std::shared_ptr<T>** ptrs = reinterpret_cast<std::shared_ptr<T>**>(mxGetData(a));

   int n = mxGetNumberOfElements(a);
   std::vector<std::shared_ptr<T>> v(n);
   for (int i = 0; i < n; i++)
      v[i] = *ptrs[i];
   
   return v;
}


template<class T>
mxArray* PackageSharedPtrForMatlab(std::shared_ptr<T> ptr)
{
   mxArray* a = mxCreateNumericMatrix(1, 1, mxUINT64_CLASS, mxREAL);
   std::shared_ptr<T>** p = reinterpret_cast<std::shared_ptr<T>**>(mxGetData(a));
   p[0] = new std::shared_ptr<T>(ptr);
   return a;
}