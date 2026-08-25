vcpkg_download_distfile(ANTLR4_JAR
    URLS "https://www.antlr.org/download/antlr-4.13.2-complete.jar"
    FILENAME "antlr-4.13.2-complete.jar"
    SHA512 22569a011d207fb8f33e7e71162542a5748cc3daa67eec59cbdc2aeb0894c331dfb8b6100ea88529c6cea72672cbddd77ca6134ddf331685d68b3e72b4e0a914
)
vcpkg_download_distfile(ANTLR4_LICENSE
    URLS "https://raw.githubusercontent.com/antlr/antlr4/4.13.2/LICENSE.txt"
    FILENAME "antlr4-4.13.2-LICENSE.txt"
    SHA512 3fa06f1bdcecccc72cce39fcf65fdb499b5590ea946b385d7b1ff862ee53ce3d9f018fc1e541e63d80c791d6d1ac3501a87eb1e5feb45b924ce1f2c15691216d
)

set(VCPKG_POLICY_EMPTY_INCLUDE_FOLDER enabled)

file(INSTALL "${ANTLR4_JAR}"
     DESTINATION "${CURRENT_PACKAGES_DIR}/tools/${PORT}")
vcpkg_install_copyright(FILE_LIST "${ANTLR4_LICENSE}")
