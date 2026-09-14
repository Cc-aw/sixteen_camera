#ifndef OPENCV_RVV_BAREMETAL_COMPAT_HPP
#define OPENCV_RVV_BAREMETAL_COMPAT_HPP

#include <cmath>

// This GCC/newlib configuration exposes ::cbrt but does not import it into
// std::. OpenCV's public headers use std::cbrt even when the selected kernel
// does not. Keep the workaround local to standalone bare-metal source builds.
#if defined(__NEWLIB__) && !defined(_GLIBCXX_USE_C99_MATH_TR1)
namespace std
{
using ::cbrt;
}
#endif

#endif
