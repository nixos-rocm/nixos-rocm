{ stdenv, fetchFromGitHub, cmake, tinyxml2, zlib, amdtbasetools }:
let srcs = {
  versioninfo = fetchFromGitHub {
    owner = "GPUOpen-Tools";
    repo = "common-src-VersionInfo";
    rev = "1f66f52bf900821e002578f06ed78d53faf2268d";
    sha256 = "1rfm39qbj75f7fnaqd2vv1l22z5xcn2x9lkhqz00r6fwg6vx4kiz";
  };
  miniz = fetchFromGitHub {
    owner = "GPUOpen-Tools";
    repo = "common-src-Miniz";
    rev = "a958cde31565769681aa3d7934c3d38c52940f4e";
    sha256 = "189rry9r72baxjavhinz9dwlbyykn9a76a1mikhcph118dw2i4aj";
  };
}; in
stdenv.mkDerivation {
  name = "AMDTOSWrappers";
  version = "2018-10-10";
  src = fetchFromGitHub {
    owner = "GPUOpen-Tools";
    repo = "common-src-AMDTOSWrappers";
    rev = "551f171f3a13f69f937a6918bb36a8012a8ef9d2";
    sha256 = "0bhdhaa4v839q7ag5c9h47s8wb2dvh6gaxz6mkj6nln019jfgzcv";
  };
  postUnpack = ''
    ln -s $PWD/$sourceRoot $PWD/$sourceRoot/AMDTOSWrappers
    ln -s ${srcs.versioninfo} $PWD/$sourceRoot/VersionInfo
    ln -s ${srcs.miniz} $PWD/$sourceRoot/Miniz
  '';
  cmakeFlags = [
    "-DCMAKE_CXX_FLAGS=-DAMDT_PUBLIC"
  ];
  nativeBuildInputs = [ cmake ];
  buildInputs = [ tinyxml2 zlib amdtbasetools ];
  patchPhase = ''
    sed '/#define MINIZ_HEADER_FILE_ONLY/d' -i src/common/osDirectorySerializer.cpp
    sed -e 's,\(include_directories("''${PROJECT_SOURCE_DIR}\)/../"),\1"),' \
        -e 's,\(include_directories("''${PROJECT_SOURCE_DIR}\)/../Miniz"),\1/Miniz"),' \
        -e 's,\(add_library(AMDTOSWrappers\) STATIC,\1 SHARED,' \
        -i CMakeLists.txt
    echo 'add_library(tinyxml SHARED IMPORTED)' >> CMakeLists.txt
    echo 'set_target_properties(tinyxml PROPERTIES IMPORTED_LOCATION ${tinyxml2}/lib/libtinyxml.so)' >> CMakeLists.txt
    echo 'add_library(zlib SHARED IMPORTED)' >> CMakeLists.txt
    echo 'set_target_properties(zlib PROPERTIES IMPORTED_LOCATION ${zlib}/lib/libz.so)' >> CMakeLists.txt
    echo 'target_link_libraries(AMDTOSWrappers tinyxml zlib)' >> CMakeLists.txt
    echo 'set_target_properties(AMDTOSWrappers PROPERTIES PUBLIC_HEADER "Include/osApplication.h;Include/osAtomic.h;Include/osBugReporter.h;Include/osBundle.h;Include/osCallsStackReader.h;Include/osCallStackFrame.h;Include/osCallStack.h;Include/osCGIInputDataReader.h;Include/osChannelEncryptor.h;Include/osChannel.h;Include/osChannelOperators.h;Include/osCommunicationDebugManager.h;Include/osCommunicationDebugThread.h;Include/osCondition.h;Include/osConsole.h;Include/osCpuid.h;Include/osCPUSampledData.h;Include/osCriticalSection.h;Include/osCriticalSectionLocker.h;Include/osDaemon.h;Include/osDebuggingFunctions.h;Include/osDebugLog.h;Include/osDebugLogParser.h;Include/osDesktop.h;Include/osDirectory.h;Include/osDirectorySerializer.h;Include/osDNSQueryThread.h;Include/osDoubleBufferQueue.h;Include/osEnvironmentVariable.h;Include/osExceptionReason.h;Include/osFile.h;Include/osFileLauncher.h;Include/osFilePathByLastAccessDateCompareFunctor.h;Include/osFilePath.h;Include/osFilePermissions.h;Include/osGeneralFunctions.h;Include/osHTTPClient.h;Include/osIOKitForiPhoneDevice.h;Include/osKeyboardListener.h;Include/osLinuxProcFileSystemReader.h;Include/osMachine.h;Include/osMacSystemResourcesSampler.h;Include/osMessageBox.h;Include/osModuleArchitecture.h;Include/osModule.h;Include/osMutex.h;Include/osMutexLocker.h;Include/osNetworkAdapter.h;Include/osNULLSocket.h;Include/osOSDefinitions.h;Include/osOSWrappersDLLBuild.h;Include/osOutOfMemoryHandling.h;Include/osPhysicalMemorySampledData.h;Include/osPipeExecutor.h;Include/osPipeSocketClient.h;Include/osPipeSocket.h;Include/osPipeSocketServer.h;Include/osPortAddress.h;Include/osProcess.h;Include/osProcessSharedFile.h;Include/osProductVersion.h;Include/osRawMemoryBuffer.h;Include/osRawMemoryStream.h;Include/osReadWriteLock.h;Include/osSettingsFileHandler.h;Include/osSharedMemorySocketClient.h;Include/osSharedMemorySocket.h;Include/osSharedMemorySocketServer.h;Include/osSingleApplicationInstance.h;Include/osSocket.h;Include/osStdLibIncludes.h;Include/osStopWatch.h;Include/osStream.h;Include/osStringConstants.h;Include/osSynchronizationObject.h;Include/osSynchronizationObjectLocker.h;Include/osSynchronizedQueue.h;Include/osSystemError.h;Include/osSystemResourcesDataSampler.h;Include/osTCPSocketClient.h;Include/osTCPSocket.h;Include/osTCPSocketServerConnectionHandler.h;Include/osTCPSocketServer.h;Include/osThread.h;Include/osThreadLocalData.h;Include/osTime.h;Include/osTimeInterval.h;Include/osTimer.h;Include/osToAndFromString.h;Include/osTransferableObjectCreator.h;Include/osTransferableObjectCreatorsBase.h;Include/osTransferableObjectCreatorsManager.h;Include/osTransferableObject.h;Include/osTransferableObjectType.h;Include/osUnhandledExceptionHandler.h;Include/osUser.h;Include/osWin32CallStackReader.h;Include/osWin32DebugInfoReader.h;Include/osWin32DebugSymbolsManager.h;Include/osWin32Functions.h;Include/osWrappersInitFunc.h")' >> CMakeLists.txt
    echo "install(TARGETS AMDTOSWrappers LIBRARY DESTINATION $out/lib PUBLIC_HEADER DESTINATION $out/include/AMDTOSWrappers/Include)" >> CMakeLists.txt
  '';
}
