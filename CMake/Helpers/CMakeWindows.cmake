set_directory_properties(PROPERTIES VS_STARTUP_PROJECT Etterna)

# Windows prefers the binary to be placed in the Program Directory
# To be changed when swiched to an out-of-source build
set_target_properties(Etterna PROPERTIES
	RUNTIME_OUTPUT_DIRECTORY "${PROJECT_SOURCE_DIR}/Program"
	RUNTIME_OUTPUT_DIRECTORY_RELEASE "${PROJECT_SOURCE_DIR}/Program"
	RUNTIME_OUTPUT_DIRECTORY_DEBUG "${PROJECT_SOURCE_DIR}/Program"
	RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${PROJECT_SOURCE_DIR}/Program")

# Universal Build Options
set(ETTERNA_COMPILE_FLAGS "/MP8 /GL /arch:SSE2")
set(ETTERNA_LINK_FLAGS "/SUBSYSTEM:WINDOWS /SAFESEH:NO /LTCG")

# Build type dependant compile flags
if (CMAKE_BUILD_TYPE STREQUAL "Release")
	set_target_properties(SQLiteCpp sqlite3 jsoncpp lua uWS discord-rpc PROPERTIES COMPILE_FLAGS "/MT") # The following libraries are set to be dynamically linked. These compile flags switch them to be statically linked.
	set(ETTERNA_COMPILE_FLAGS "${ETTERNA_COMPILE_FLAGS} /MT")
	set(ETTERNA_LINK_FLAGS "${ETTERNA_LINK_FLAGS} /NODEFAULTLIB:\"LIBCMT\"")
elseif (CMAKE_BUILD_TYPE STREQUAL "Debug")
	# TODO: Fix Debug build configuration
	# At the moment, to build with debug information, use RelWithDebInfo.
	# This issue with this is with CMake not linking everything properly with the /MTd compile flag
	# To build with the Debug C Runtime library, everything must be compiled with said CRT.
	# To build with this build type, give all the target targets the correct link flags.
endif()
set_target_properties(Etterna PROPERTIES LINK_FLAGS ${ETTERNA_LINK_FLAGS})
set_target_properties(Etterna PROPERTIES COMPILE_FLAGS ${ETTERNA_COMPILE_FLAGS})

list(APPEND cdefs CURL_STATICLIB GLEW_STATIC)
set_target_properties(Etterna PROPERTIES COMPILE_DEFINITIONS "${cdefs}")

# Linking - Windows Only
target_link_libraries(Etterna curl)
target_link_libraries(Etterna ffmpeg)

find_package(DirectX REQUIRED)
get_filename_component(DIRECTX_LIBRARY_DIR "${DIRECTX_LIBRARIES}" DIRECTORY)
target_link_directories(Etterna PUBLIC ${DIRECTX_LIBRARY_DIR})
target_include_directories(Etterna PRIVATE ${DIRECTX_INCLUDE_DIR})

# DLL - Copy to run directory
if(CMAKE_SIZEOF_VOID_P EQUAL 8) # If 64bit
	set(ARCH 64bit)
else()
	set(ARCH 32bit)
endif()

list(APPEND WIN_DLLS
	"${PROJECT_SOURCE_DIR}/extern/ffmpeg/windows/${ARCH}/avcodec-55.dll"
	"${PROJECT_SOURCE_DIR}/extern/ffmpeg/windows/${ARCH}/avformat-55.dll"
	"${PROJECT_SOURCE_DIR}/extern/ffmpeg/windows/${ARCH}/avutil-52.dll"
	"${PROJECT_SOURCE_DIR}/extern/ffmpeg/windows/${ARCH}/swscale-2.dll"
	"${PROJECT_SOURCE_DIR}/extern/libcurl/windows/${ARCH}/libcurl.dll")

if(ARCH STREQUAL "32bit")
	list(APPEND WIN_DLLS "${OPENSSL_ROOT_DIR}/libssl-1_1.dll" "${OPENSSL_ROOT_DIR}/libcrypto-1_1.dll") 			# SSL
else() # 64bit
	list(APPEND WIN_DLLS "${OPENSSL_ROOT_DIR}/libssl-1_1-x64.dll" "${OPENSSL_ROOT_DIR}/libcrypto-1_1-x64.dll") 	# SSL
	list(APPEND WIN_DLLS "${PROJECT_SOURCE_DIR}/extern/libcurl/windows/${ARCH}/libcurl.dll") 					# CURL
endif()

foreach(dll ${WIN_DLLS})
	file(COPY "${dll}" DESTINATION "${PROJECT_SOURCE_DIR}/Program/")
endforeach()

# CPack
set(CPACK_GENERATOR "NSIS")
SET(CPACK_NSIS_INSTALL_ROOT "C:\\\\Games") # Default install directory
set(CPACK_NSIS_EXECUTABLES_DIRECTORY "Etterna\\\\Program")
set(CPACK_NSIS_MUI_FINISHPAGE_RUN "Etterna.exe")
set(CPACK_NSIS_MUI_ICON ${PROJECT_SOURCE_DIR}/Installer/Install.ico)
set(CPACK_NSIS_MUI_WELCOMEFINISHPAGE_BITMAP ${PROJECT_SOURCE_DIR}/Installer/welcome-ett.bmp)
set(CPACK_NSIS_ENABLE_UNINSTALL_BEFORE_INSTALL ON)

## Switch the strings below to use backslashes. NSIS requires it for those variables in particular. Copied from original script.
string(REGEX REPLACE "/" "\\\\\\\\" CPACK_SM_NSIS_HEADER_BITMAP "${CPACK_SM_NSIS_HEADER_BITMAP}")
string(REGEX REPLACE "/" "\\\\\\\\" CPACK_NSIS_MUI_WELCOMEFINISHPAGE_BITMAP "${CPACK_NSIS_MUI_WELCOMEFINISHPAGE_BITMAP}")

include(CPack)