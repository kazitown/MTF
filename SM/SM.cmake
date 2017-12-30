option(WITH_TEMPLATED "Enable templated implementations of search methods (faster at runtime but take much longer to compile)" ON)
option(WITH_FLANN "Enable FLANN based NN tracker" ON)
option(WITH_GRID_TRACKERS "Enable Grid trackers (RANSAC/LMS SMs) and RKLT" ON)
option(WITH_FEAT "Enable Feature based Tracker (requires nonfree OpenCV module)" ON)
option(WITH_REGNET "Enable regression network search method (requires a custom version of Caffe to be present)" OFF)

set(SEARCH_METHODS "")
set(SEARCH_METHODS_NT ESM AESM FCLK ICLK FALK IALK FCSD PF NN GNN)
set(SEARCH_PARAMS FCLK ICLK FALK IALK ESM NN GNN PF Cascade Parallel Pyramidal)
set(COMPOSITE_SEARCH_METHODS CascadeTracker ParallelTracker PyramidalTracker LineTracker)
if(WITH_TEMPLATED)
	set(SEARCH_METHODS ${SEARCH_METHODS} ESM FCLK ICLK FALK IALK PF)
	set(COMPOSITE_SEARCH_METHODS ${COMPOSITE_SEARCH_METHODS} PyramidalSM ParallelSM CascadeSM)
else(WITH_TEMPLATED)
	message(STATUS "Templated implementations of SMs are disabled")
	set(MTF_DEFINITIONS ${MTF_DEFINITIONS} DISABLE_TEMPLATED_SM)	
endif()
if(WITH_GRID_TRACKERS)
	set(COMPOSITE_SEARCH_METHODS ${COMPOSITE_SEARCH_METHODS} GridTracker GridTrackerCV)
	if(WITH_TEMPLATED)
		set(COMPOSITE_SEARCH_METHODS ${COMPOSITE_SEARCH_METHODS} GridTrackerFlow RKLT)
	endif(WITH_TEMPLATED)
	set(SEARCH_METHODS_NT ${SEARCH_METHODS_NT} GridTrackerFlow RKLT)
	set(SEARCH_PARAMS ${SEARCH_PARAMS} GridTrackerFlow RKLT)
endif(WITH_GRID_TRACKERS)
if(WITH_FEAT)		
	if(NOT "${OpenCV_VERSION}" STREQUAL "3")̀
	# message(STATUS "OpenCV_LIBRARIES: ${OpenCV_LIBRARIES}")
		findSubPart("${OpenCV_LIBRARIES}" "opencv_nonfree" CV_NONFREE_FOUND)
	else()
		findSubPart("${OpenCV_LIBRARIES}" "opencv_xfeatures2d" CV_NONFREE_FOUND)
	endif()
	message(STATUS "OpenCV_VERSION: ${OpenCV_VERSION}")
	if(CV_NONFREE_FOUND)	
		message(STATUS "Feature based grid tracker is enabled")
		set(COMPOSITE_SEARCH_METHODS ${COMPOSITE_SEARCH_METHODS} FeatureTracker)
		set(FEAT_ENABLED ON)
	else(CV_NONFREE_FOUND)
		message(STATUS "OpenCV nonfree module not found so disabling the feature based grid tracker")			
		set(MTF_DEFINITIONS ${MTF_DEFINITIONS} DISABLE_FEAT)
		set(FEAT_ENABLED OFF)
	endif(CV_NONFREE_FOUND)
else(WITH_FEAT)
	message(STATUS "Feature based grid tracker disabled")
	set(MTF_DEFINITIONS ${MTF_DEFINITIONS} DISABLE_FEAT)
	set(FEAT_ENABLED OFF)
endif(WITH_FEAT)
if(WITH_REGNET)
	set(SEARCH_METHODS_NT ${SEARCH_METHODS_NT} RegNet)
else(WITH_REGNET)
	message(STATUS "RegNet disabled")
	set(MTF_DEFINITIONS ${MTF_DEFINITIONS} DISABLE_REGNET)
endif(WITH_REGNET)
if(WITH_FLANN)
	find_package(FLANN)
	if(FLANN_FOUND) 
		set(SEARCH_METHODS ${SEARCH_METHODS} NN GNN FGNN)
		set(SEARCH_PARAMS ${SEARCH_PARAMS} FLANN)
		set(MTF_LIBS ${MTF_LIBS} ${FLANN_LIBS})
		set(MTF_EXT_INCLUDE_DIRS ${MTF_EXT_INCLUDE_DIRS} ${FLANN_INCLUDE_DIRS})
		if (WIN32)
			set(MTF_DEFINITIONS ${MTF_DEFINITIONS} DISABLE_HDF5)
		else()
			find_package(HDF5)		
			if(HDF5_FOUND)
				message(STATUS "Found HDF5 headers at: " ${HDF5_INCLUDE_DIRS})
				if (WIN32)
					set(MTF_LIBS ${MTF_LIBS} ${HDF5_C_STATIC_LIBRARY})
					message(STATUS "Found HDF5 C++ libraries: ${HDF5_C_STATIC_LIBRARY}")
				else()
					set(MTF_LIBS ${MTF_LIBS} ${HDF5_LIBRARIES})
					message(STATUS "Found HDF5 C++ libraries: ${HDF5_LIBRARIES}")
				endif()
				set(MTF_EXT_INCLUDE_DIRS ${MTF_EXT_INCLUDE_DIRS} ${HDF5_INCLUDE_DIRS})
			else()
				set(MTF_DEFINITIONS ${MTF_DEFINITIONS} DISABLE_HDF5)
			endif()
		endif()		
	else()
		message(STATUS "FLANN not found so the templated version of NN has been disabled")
		set(MTF_DEFINITIONS ${MTF_DEFINITIONS} DISABLE_FLANN DISABLE_HDF5)
		set(SEARCH_PARAMS ${SEARCH_PARAMS} FLANNCV)
	endif()

else()
	set(MTF_DEFINITIONS ${MTF_DEFINITIONS} DISABLE_FLANN DISABLE_HDF5)
	set(SEARCH_PARAMS ${SEARCH_PARAMS} FLANNCV)
	message(STATUS "FLANN based NN is disabled")
endif()
set(SEARCH_METHODS ${SEARCH_METHODS} ${COMPOSITE_SEARCH_METHODS})

addPrefix("${SEARCH_METHODS_NT}" "NT/" SEARCH_METHODS_NT)
set(SEARCH_METHODS ${SEARCH_METHODS} ${SEARCH_METHODS_NT})

addPrefixAndSuffix("${SEARCH_METHODS}" "SM/src/" ".cc" SEARCH_METHODS_SRC)
addPrefixAndSuffix("${SEARCH_PARAMS}" "SM/src/" "Params.cc" SEARCH_PARAMS_SRC)

set(MTF_SRC ${MTF_SRC} ${SEARCH_METHODS_SRC} ${SEARCH_PARAMS_SRC})
set(MTF_INCLUDE_DIRS ${MTF_INCLUDE_DIRS} SM/include)
