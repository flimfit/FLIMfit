#pragma once

#include <mex.h>
#include <string>
#include <vector>
#include <memory>
#include <cv.h>

/*
   Input validation
*/

#define AssertInputCondition(x) checkInputCondition(#x, x);
inline void checkInputCondition(const char* text, bool condition)
{
   if (!condition)
      mexErrMsgIdAndTxt("FLIMfitMex:invalidInput", text);
}

inline void checkSize(const mxArray* array, int needed)
{
   if (needed != mxGetNumberOfElements(array))
      mexErrMsgIdAndTxt("MATLAB:mxmalloc:invalidInput",
         "Input array is the wrong size");
}

inline void checkInput(int nrhs, int needed)
{
   if (nrhs < needed)
      mexErrMsgIdAndTxt("MATLAB:mxmalloc:invalidInput",
         "Not enough input arguments");
}

/*
   uint64 convenience
*/

inline mxArray* mxCreateUint64Scalar(uint64_t v)
{
   mxArray* m = mxCreateNumericMatrix(1, 1, mxUINT64_CLASS, mxREAL);
   uint64_t* mp = (uint64_t*)mxGetData(m);
   mp[0] = v;
   return m;
}

/*
   String handling
*/

inline std::string getStringFromMatlab(const mxArray* dat)
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

/*
   Structure handling
*/


inline mxArray* getFieldFromStruct(const mxArray* s, const char *field)
{
   int field_number = mxGetFieldNumber(s, field);
   if (field_number == -1)
   {
      std::string err = std::string("Missing field in structure: ").append(field);
      mexErrMsgIdAndTxt("FLIMfit:missingField", err.c_str());
   }

   return mxGetFieldByNumber(s, 0, field_number);
}

inline double getValueFromStruct(const mxArray* s, const char *field, double default_value)
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

inline double getValueFromStruct(const mxArray* s, const char *field)
{
   const mxArray* v = getFieldFromStruct(s, field);

   if (!mxIsScalar(v))
   {
      std::string err = std::string("Expected field to be scalar: ").append(field);
      mexErrMsgIdAndTxt("FLIMfit:missingField", err.c_str());
   }

   return mxGetScalar(v);
}

/*
   Argument handling
*/

inline bool isArgument(int nrhs, const mxArray *prhs[], const char* arg, int nstart = 0)
{
   for (int i = nstart; (i + 1) < nrhs; i++)
   {
      if (mxIsChar(prhs[i]) && getStringFromMatlab(prhs[i]) == arg)
         return true;
   }
   return false;
}

inline const mxArray* getNamedArgument(int nrhs, const mxArray *prhs[], const char* arg, int nstart = 0)
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

/*
   OpenCV handling
*/

inline cv::Mat getCvMat(const mxArray* im)
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

inline mxArray* convertCvMat(const cv::Mat im)
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