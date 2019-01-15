#pragma once

#include <boost/align/aligned_allocator.hpp>
#include <vector>

// Aligned allocated
template<class T, std::size_t Alignment = 32>
using aligned_vector = std::vector<T,
   boost::alignment::aligned_allocator<T, Alignment> >;

typedef aligned_vector<double>::const_iterator const_double_iterator;
typedef aligned_vector<double>::iterator double_iterator;