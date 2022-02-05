find_program(LINUXDEPLOY_EXECUTABLE linuxdeploy linuxdeploy-x86_64.AppImage)
find_program(MACDEPLOYQT_EXECUTABLE macdeployqt HINTS "${_qt_bin_dir}")
find_program(ANDROIDDEPLOYQT_EXECUTABLE androiddeployqt HINTS "${_qt_bin_dir}")

set(CPACK_GENERATOR)
set(CPACK_PACKAGE_EXECUTABLES qfield;QField)
set(CPACK_PACKAGE_HOMEPAGE_URL "https://qfield.org")
# set(CPACK_PACKAGE_ICON "${CMAKE_SOURCE_DIR}/images/icons/qfield_logo.png")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_SOURCE_DIR}/LICENSE")
# set(CPACK_STRIP_FILES TRUE)
set(CPACK_PACKAGE_VERSION_MAJOR ${CMAKE_PROJECT_VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR ${CMAKE_PROJECT_VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH ${CMAKE_PROJECT_VERSION_PATCH})

function(macdeployqt bundle targetdir _PACKAGER)
    file(GENERATE OUTPUT ${CMAKE_BINARY_DIR}/CPackMacDeployQt-${_PACKAGER}.cmake
                  CONTENT "execute_process(COMMAND \"${MACDEPLOYQT_EXECUTABLE}\" \"${CPACK_PACKAGE_DIRECTORY}/_CPack_Packages/Darwin/${_PACKAGER}/${targetdir}/${bundle}\" -always-overwrite)")
    install(SCRIPT ${CMAKE_BINARY_DIR}/CPackMacDeployQt-${_PACKAGER}.cmake COMPONENT Runtime)
    include(InstallRequiredSystemLibraries)
endfunction()

if(WIN32)
    # message(STATUS "   + WIX                             YES ")
    # set(CPACK_WIX_UPGRADE_GUID 357E1535-9094-4550-8B42-D01EFD885686)
    # set(CPACK_WIX_PRODUCT_ICON we need a ico)
    # set(CPACK_WIX_PRODUCT_LOGO "${CMAKE_SOURCE_DIR}/images/icons/qfield_logo.png")
    # set(CPACK_WIX_TEMPLATE "${CMAKE_SOURCE_DIR}/cmake/windows/template.wxs.in")
    # set(CPACK_WIX_EXTRA_SOURCES "${CMAKE_SOURCE_DIR}/cmake/windows/shortcuts.wxs")
    # set(CPACK_GENERATOR "WIX")

    message(STATUS "   + NSIS                             YES ")
    list(APPEND CPACK_GENERATOR "NSIS")
endif()

get_target_property(qmake_executable Qt5::qmake IMPORTED_LOCATION)

set(CPACK_OUTPUT_CONFIG_FILE "${CMAKE_BINARY_DIR}/BundleConfig.cmake")

set(CPACK_PACKAGE_INSTALL_DIRECTORY "${PROJECT_NAME}")
set(CPACK_PACKAGE_DIRECTORY "${CMAKE_BINARY_DIR}")
set(CPACK_PACKAGING_INSTALL_PREFIX "/usr")

add_custom_target(bundle
                  COMMAND ${CMAKE_CPACK_COMMAND} "--config" "${CMAKE_BINARY_DIR}/BundleConfig.cmake"
                  COMMENT "Running CPACK. Please wait..."
                  DEPENDS qfield)

# Qt IFW packaging framework
if(BINARYCREATOR_EXECUTABLE)
    list(APPEND CPACK_GENERATOR IFW)
    message(STATUS "   + Qt Installer Framework               YES ")
else()
    message(STATUS "   + Qt Installer Framework                NO ")
endif()


if(LINUXDEPLOY_EXECUTABLE)
    message(STATUS "   + AppImage                             YES ")
    set(CPACK_GENERATOR "External;${CPACK_GENERATOR}")
    configure_file(${CMAKE_CURRENT_SOURCE_DIR}/platform/linux/CPackLinuxDeployQt.cmake.in "${CMAKE_BINARY_DIR}/CPackExternal.cmake")
    set(CPACK_EXTERNAL_PACKAGE_SCRIPT "${CMAKE_BINARY_DIR}/CPackExternal.cmake")
else()
    message(STATUS "   + AppImage                              NO ")
endif()

if(ANDROIDDEPLOYQT_EXECUTABLE)
    message(STATUS "   + Android                              YES ")
    set(CPACK_GENERATOR "External;${CPACK_GENERATOR}")
    set(AT "@")
    set(WITH_ALL_FILES_ACCESS OFF CACHE STRING "[ANDROID] Enable All Files Access and get a free chat with Google support if you upload to Play Store."
    if(WITH_ALL_FILES_ACCESS)
      set(ALL_FILES_ACCESS "<uses-permission android:name=\"android.permission.MANAGE_EXTERNAL_STORAGE\" />")
    endif()
    configure_file(${CMAKE_SOURCE_DIR}/platform/android/AndroidManifest.xml.in ${CMAKE_SOURCE_DIR}/platform/android/AndroidManifest.xml @ONLY)
    configure_file(${CMAKE_SOURCE_DIR}/platform/android/generated.xml.in ${CMAKE_SOURCE_DIR}/platform/android/generated.xml @ONLY)
    configure_file(${CMAKE_SOURCE_DIR}/platform/android/build.gradle.in ${CMAKE_SOURCE_DIR}/platform/android/build.gradle @ONLY)
    configure_file(${CMAKE_SOURCE_DIR}/platform/android/CPackAndroidDeployQt.cmake.in "${CMAKE_BINARY_DIR}/CPackExternal.cmake" @ONLY)
    set(CPACK_EXTERNAL_PACKAGE_SCRIPT "${CMAKE_BINARY_DIR}/CPackExternal.cmake")
endif()

if(APPLE AND NOT IOS)
    set(CPACK_BUNDLE_PLIST "${CMAKE_BINARY_DIR}/Info.plist")
    set(CPACK_DMG_VOLUME_NAME "${PROJECT_NAME}")
    set(CPACK_DMG_FORMAT "UDBZ")
    set(CPACK_GENERATOR "External;${CPACK_GENERATOR}")
    message(STATUS "   + macdeployqt/DnD                      YES ")
    configure_file(${CMAKE_SOURCE_DIR}/platform/macos/CPackMacDeployQt.cmake.in "${CMAKE_BINARY_DIR}/CPackExternal.cmake")
    set(CPACK_EXTERNAL_PACKAGE_SCRIPT "${CMAKE_BINARY_DIR}/CPackExternal.cmake")
endif()
include(CPack)
