#pragma once

#include <mex.h>
#include <string>
#include <vector>
#include <memory>
#include <cv.h>

#define AssertInputCondition(x) checkInputCondition(#x, x);
void checkInputCondition(const char* text, bool condition);

std::string getStringFromMatlab(const mxArray* dat);

void checkSize(const mxArray* array, int needed);
void checkInput(int nrhs, int needed);

mxArray* mxCreateUint64Scalar(uint64_t v);

/*
   Structure handling
*/

mxArray* getFieldFromStruct(const mxArray* s, const char *field);
double getValueFromStruct(const mxArray* s, const char *field, double default_value);
double getValueFromStruct(const mxArray* s, const char *field);

/*
   Argument handling
*/

bool isArgument(int nrhs, const mxArray *prhs[], const char* arg, int nstart = 0);
const mxArray* getNamedArgument(int nrhs, const mxArray *prhs[], const char* arg, int nstart = 0);

/*
   OpenCV handling
*/

cv::Mat getCvMat(const mxArray* im);
mxArray* convertCvMat(const cv::Mat im);

/*
  Vector conversion
*/

template<typename T, typename U>
std::vector<T> getUVector(const mxArray* v)
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
std::vector<T> getVector(const mxArray* v)
{
   if (mxIsDouble(v))
      return getUVector<T, double>(v);
   else if (mxIsSingle(v))
      return getUVector<T, float>(v);
   else if (mxIsInt64(v))
      return getUVector<T, int64_t>(v);
   else if (mxIsInt32(v))
      return getUVector<T, int32_t>(v);
   else if (mxIsInt16(v))
      return getUVector<T, int16_t>(v);
   else if (mxIsInt8(v))
      return getUVector<T, int8_t>(v);
   else if (mxIsUint64(v))
      return getUVector<T, uint64_t>(v);
   else if (mxIsUint32(v))
      return getUVector<T, uint32_t>(v);
   else if (mxIsUint16(v))
      return getUVector<T, uint16_t>(v);
   else if (mxIsUint8(v))
      return getUVector<T, uint8_t>(v);

   return std::vector<T>();
}

template<typename T>
std::vector<T> getVectorFromStruct(const mxArray* s, const char *field)
{
   mxArray* v = getFieldFromStruct(s, field);
   return getVector<T>(v);
}


/*
   Pointer packaging
*/

template<class T>
mxArray* packageSharedPtrForMatlab(const std::shared_ptr<T>& ptr)
{
   // Create pointer reference
   mxArray* ptr_ptr = mxCreateNumericMatrix(1, 1, mxUINT64_CLASS, mxREAL);
   std::shared_ptr<T>** p = reinterpret_cast<std::shared_ptr<T>**>(mxGetData(ptr_ptr));
   p[0] = new std::shared_ptr<T>(ptr);

   const char* fields[] = { "type", "pointer", "valid" };
   mxArray* a = mxCreateStructMatrix(1, 1, 3, fields);
   mxSetFieldByNumber(a, 0, 0, mxCreateString(typeid(T).name()));
   mxSetFieldByNumber(a, 0, 1, ptr_ptr);
   mxSetFieldByNumber(a, 0, 2, mxCreateLogicalScalar(1));
   
   return a;
}

template<class T>
mxArray* validateSharedPointer(const mxArray* a)
{
   if (!mxIsStruct(a))
      mexErrMsgIdAndTxt("MATLAB:FLIMfit:invalidInput",
         "Input should be a structure");

   if (mxGetNumberOfFields(a) != 3)
      mexErrMsgIdAndTxt("MATLAB:FLIMfit:invalidInput",
         "Structure not recognised");

   std::string type = getStringFromMatlab(getFieldFromStruct(a, "type"));
   if (type != typeid(T).name())
      mexErrMsgIdAndTxt("MATLAB:FLIMfit:invalidInput",
         "Incorrect type");

   if (getValueFromStruct(a, "valid") != 1.0)
      mexErrMsgIdAndTxt("MATLAB:FLIMfit:invalidInput",
         "Pointer not valid");

   mxArray* ptr = getFieldFromStruct(a, "pointer");
   if (!mxIsUint64(ptr))
      mexErrMsgIdAndTxt("MATLAB:FLIMfit:invalidInput",
         "Pointer not valid");

   return ptr;
}

template<class T>
std::shared_ptr<T> getSharedPtrFromMatlab(const mxArray* a)
{
   mxArray* ptr = validateSharedPointer<T>(a);

   if (mxGetNumberOfElements(ptr) > 1)
      mexWarnMsgIdAndTxt("MATLAB:mxmalloc:tooManyPointers",
         "Only expected one pointer, will return first");

   return **reinterpret_cast<std::shared_ptr<T>**>(mxGetData(ptr));
}

template<class T>
std::vector<std::shared_ptr<T>> getSharedPtrVectorFromMatlab(const mxArray* a)
{
   validateSharedPointer<T>(a);

   int n = mxGetNumberOfElements(a);
   std::vector<std::shared_ptr<T>> v(n);
   for (int i = 0; i < n; i++)
   {
      mxArray* ptr_i = mxGetField(a, i, "pointer");
      v[i] = **reinterpret_cast<std::shared_ptr<T>**>(mxGetData(ptr_i));
   }

   return v;
}

template<class T>
void releaseSharedPtrFromMatlab(const mxArray* a)
{
   mxArray* ptr = validateSharedPointer<T>(a);
   std::shared_ptr<T>** ptrs = reinterpret_cast<std::shared_ptr<T>**>(mxGetData(ptr));
   int n = mxGetNumberOfElements(ptr);
   for (int i = 0; i < n; i++)
      delete ptrs[i];
}



/*
template<typename T>
T getHandleScalar(const mxArray* handle, const char* prop, T default_value = std::numeric_limits<T>::quiet_NaN())
{
if (mxArray* a = mxGetProperty(handle, 0, prop))
return (T)mxGetScalar(a);

mexWarnMsgIdAndTxt("MATLAB:mxmalloc:invalidInput",
"Unable to retrieve property");

return default_value;
}

template<typename T>
T getHandleArrayIdx(const mxArray* handle, const char* prop, int idx, T default_value = std::numeric_limits<T>::quiet_NaN())
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
*/