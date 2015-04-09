#include <mex.h>
#include <string>
#include <vector>

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

void CheckInput(int nrhs, int needed)
{
   if (nrhs < needed)
      mexErrMsgIdAndTxt("MATLAB:mxmalloc:invalidInput",
      "Not enough input arguments");
}