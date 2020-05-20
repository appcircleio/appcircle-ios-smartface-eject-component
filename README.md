# Appcircle Smartface Eject For iOS

Smartface Generator step is specific to the Smartface projects and it generates a Xcode project for building iOS applications.

Required Input Variables
- `$AC_REPOSITORY_DIR`: Specifies the cloned repository directory.
- `$AC_XCODE_LIST_DIR`: Specifies the xcode folder list directory. Current xcode folder structure examples : /Applications/Xcode/10.3/Xcode or /Applications/Xcode/11.0/Xcode
- `$AC_INCLUDE_XCODE_PROJECT`: Specifies whether Smartface xcode project is in output.

Optional Input Variables
- `$AC_SMARTFACE_CLI_VERSION`: Specifies the Smartface CLI version. Defaults to: latest
- `$AC_SMARTFACE_PLAYER_VERSION`: Specifies the Smartface iOS player version. Defaults to: latest

Output Variables
- `$AC_PROJECT_PATH`: Smartface Project Path.
- `$AC_SCHEME`: Smartface scheme.
- `$AC_XCODE_VERSION`: Smartface xcode version.
- `$AC_BUNDLE_IDENTIFIERS`: Smartface bundle identifiers.
