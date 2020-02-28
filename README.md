# Flutter Pdfium Test

This project is build with the help of following repo.
https://github.com/scientifichackers/flutter-pdfium

# Android Support
The above repo has used flutter desktop to run the Pdfium viewer.
However I managed to import Android libraries based on the following repo.
https://github.com/benjinus/android-support-pdfium

Loaded the prebuid Dynamic library as mentioned here.
https://github.com/dart-lang/ffi/issues/25

#### Step 1: libpdfsdk.so in android/src/main/jniLibs/ in their respective platform folders

![Alt text](docs/images/jnilibsfolder.PNG?raw=true "jniLibs Location")

#### Step 2: in android/build.gradle
Follow the issue thread for more information.

#### Step 3: Loaded pdfium dart codes to the project's lib folder. Might need to import dart:ffi
From this repo's lib folder https://github.com/scientifichackers/flutter-pdfium

#### Step 4: Sort relative links in the .dart files

