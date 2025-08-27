vcpkg_from_github(
	OUT_SOURCE_PATH SOURCE_PATH
	REPO OpenNMT/CTranslate2
	REF v4.3.1
	SHA512 7bf6fdeb40c64bfb26b5cf0e6d837af349bcaeb927be555215b5d4b9f3171dc29dec1ba0d5501cee53fe3cea278f62d27e8cb050de4748dc64ce0c239075c262
)

vcpkg_from_github(
	OUT_SOURCE_PATH CPU_FEATURES_SOURCE_PATH
	REPO google/cpu_features
	REF 8a494eb1e158ec2050e5f699a504fbc9b896a43b
	SHA512 036a63bb0255491bdadcb9949abfb5b357465a9161c31dc0d82f27dc2168f9836baa62beee639da25efdf8a5d88de5110621b4656b005d32a7390478120cc48f
)
file(REMOVE_RECURSE ${SOURCE_PATH}/third_party/cpu_features)
file(RENAME ${CPU_FEATURES_SOURCE_PATH} ${SOURCE_PATH}/third_party/cpu_features)

vcpkg_from_github(
	OUT_SOURCE_PATH CUTLASS_SOURCE_PATH
	REPO NVIDIA/cutlass
	REF bbe579a9e3beb6ea6626d9227ec32d0dae119a49
	SHA512 b7d3cc102d28acee55821a0731d1741572635e677f037c5f78f4a526be4ec4faf8bba7f31226ccb6ac006d40d87c963a72fd9ff495b9fa18131520d1601d2e7a
)
file(REMOVE_RECURSE ${SOURCE_PATH}/third_party/cutlass)
file(RENAME ${CUTLASS_SOURCE_PATH} ${SOURCE_PATH}/third_party/cutlass)

vcpkg_from_github(
	OUT_SOURCE_PATH CXXOPTS_SOURCE_PATH
	REPO jarro2783/cxxopts
	REF c74846a891b3cc3bfa992d588b1295f528d43039
	SHA512 3e92a67f8d6cb1ba0f80e35b47c9beb9ea14d995bb3e296765475ff31a0b499f3080e359fa87a63273e1e8c5396d4af39d9a47dbe6fa06074bb63a642cf6bfda
)
file(REMOVE_RECURSE ${SOURCE_PATH}/third_party/cxxopts)
file(RENAME ${CXXOPTS_SOURCE_PATH} ${SOURCE_PATH}/third_party/cxxopts)

vcpkg_from_github(
	OUT_SOURCE_PATH GOOGLETEST_SOURCE_PATH
	REPO google/googletest
	REF b7d472f1225c5a64943821d8483fecb469d3f382
	SHA512 9acfa443d716ae6724dfad9cd0fdec1c725fd3b2d1bc430dd5e8a3254917cc9d77ed297c42cf013b7ca47165c8057bd59d0a48f25109acfd4e69dec8e45c33da
)
file(REMOVE_RECURSE ${SOURCE_PATH}/third_party/googletest)
file(RENAME ${GOOGLETEST_SOURCE_PATH} ${SOURCE_PATH}/third_party/googletest)

vcpkg_from_github(
	OUT_SOURCE_PATH RUY_SOURCE_PATH
	REPO google/ruy
	REF 363f252289fb7a1fba1703d99196524698cb884d
	SHA512 7e401b212ee5a837fe87fc4fe81ed4aaa3f31e9e363a8aa14517e750dfb895ea8bce4305f26e44c3c34af59a711aee1a70e6d7525a01bcfd12362789a0687904
)
file(REMOVE_RECURSE ${SOURCE_PATH}/third_party/ruy)
file(RENAME ${RUY_SOURCE_PATH} ${SOURCE_PATH}/third_party/ruy)

vcpkg_from_github(
	OUT_SOURCE_PATH SPDLOG_SOURCE_PATH
	REPO gabime/spdlog
	REF 76fb40d95455f249bd70824ecfcae7a8f0930fa3
	SHA512 a9e236144af0b4eaabac1fad358d2188124711b036435deb1e69acb258cac096a8f72eec4508784d8c63f4f526ea29991206277415072df501be5ac52c97fba2
)
file(REMOVE_RECURSE ${SOURCE_PATH}/third_party/spdlog)
file(RENAME ${SPDLOG_SOURCE_PATH} ${SOURCE_PATH}/third_party/spdlog)

vcpkg_from_github(
	OUT_SOURCE_PATH THRUST_SOURCE_PATH
	REPO NVIDIA/thrust
	REF d997cd37a95b0fa2f1a0cd4697fd1188a842fbc8
	SHA512 b3163cb80798dae6fcf9a2a98fd60e14fe7e2f9ded951ea66dc6a5720ed9e5e2b67fffe577c6c7409d0540d035c488d3cfcb4c335ad6e9be48c038a71c9a3494
)
file(REMOVE_RECURSE ${SOURCE_PATH}/third_party/thrust)
file(RENAME ${THRUST_SOURCE_PATH} ${SOURCE_PATH}/third_party/thrust)

# Fix issue with bit_cast ambiguity (std::bit_cast since C++20)
vcpkg_replace_string(${SOURCE_PATH}/include/ctranslate2/bfloat16.h bit_cast< ctranslate2::bit_cast<)

if(VCPKG_TARGET_IS_OSX)
	set(OPENMP_RUNTIME "NONE")
	if(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
		# oneDNN is not available for this platform, use Apple Accelerate for CPU acceleration
		set(WITH_DNNL "OFF")
    	set(WITH_ACCELERATE "ON")
	else()
		# oneDNN is available for this platform, use it for CPU acceleration
		set(WITH_DNNL "ON")
		set(WITH_ACCELERATE "OFF")
	endif()
else()
	set(OPENMP_RUNTIME "COMP")
	set(WITH_DNNL "ON") # use oneDNN for CPU acceleration
	set(WITH_ACCELERATE "OFF") # Apple Accelerate is not available on other platforms
endif()

vcpkg_cmake_configure(
	SOURCE_PATH "${SOURCE_PATH}"
	OPTIONS -DOPENMP_RUNTIME=${OPENMP_RUNTIME} -DWITH_MKL=OFF -DWITH_DNNL=${WITH_DNNL} -DWITH_ACCELERATE=${WITH_ACCELERATE}
)

vcpkg_cmake_install()

vcpkg_install_copyright(FILE_LIST ${SOURCE_PATH}/LICENSE)
