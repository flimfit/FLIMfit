#include <dlib/optimization.h>
#include "AlignedVectors.h"

typedef std::vector<float>::iterator float_iterator;

typedef dlib::matrix<double, 0, 1> column_vector;

class LinearMLModel
{
public:
   typedef ::column_vector column_vector;
   typedef dlib::matrix<double> general_matrix;

   LinearMLModel(int n, int nl, double_iterator a, int adim);

   void setData(float_iterator y);

   double operator()(const column_vector& x) const;
   void get_derivative_and_hessian(const column_vector& x, column_vector& J, general_matrix& H) const;
   
protected:

   int n;
   int nl;
   int adim;

   double_iterator a;
   float_iterator y;

   mutable column_vector beta;
   mutable column_vector mu;

   double const_chi;
};
