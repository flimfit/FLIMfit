#pragma once

#ifdef WIN32

#include <iostream>
#include <Windows.h>


class debugStreambuf : public std::streambuf {
public:
   virtual int_type overflow(int_type c = EOF) {
      if (c != EOF) {
         TCHAR buf[] = { c, '\0' };
         OutputDebugString(buf);
      }
      return c;
   }
};

class Cout2VisualStudioDebugOutput {

   debugStreambuf dbgstream;
   std::streambuf *default_stream;

public:
   Cout2VisualStudioDebugOutput() {
      default_stream = std::cout.rdbuf(&dbgstream);
   }

   ~Cout2VisualStudioDebugOutput() {
      std::cout.rdbuf(default_stream);
   }
};

#else
class Cout2VisualStudioDebugOutput {
};
#endif