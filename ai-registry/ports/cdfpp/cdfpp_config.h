#pragma once

#define CDFPP_VERSION "0.11.0"
#define CDFpp_USE_LIBDEFLATE
#define CDFpp_USE_NOMAP

#if defined(__BYTE_ORDER__) && __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#define CDFPP_BIG_ENDIAN
#define CDFpp_ENCODING cdf_encoding::IBMRS
#else
#define CDFPP_LITTLE_ENDIAN
#define CDFpp_ENCODING cdf_encoding::IBMPC
#endif
