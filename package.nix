{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  qt6,
  libGL,
  libusb1,
  autoPatchelfHook,
  patchelf,
}:

stdenv.mkDerivation {
  pname = "obsbot-camera-control";
  version = "0-unstable-2025-01-31";

  src = fetchFromGitHub {
    owner = "aaronsb";
    repo = "obsbot-camera-control";
    rev = "f1abe649aaa7deec091a3edda6d86bf67d8778ae";
    hash = "sha256-o5xYD1vQoxM7Dh4aDszzi32Wn5UQ8AtmmmL3InA6WGU=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    qt6.wrapQtAppsHook
    autoPatchelfHook
    patchelf
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtmultimedia
    libGL
    libusb1
    stdenv.cc.cc.lib  # libstdc++
  ];

  # SDK library is included in the repo - copy to output before autoPatchelf
  preBuild = ''
    # Ensure SDK lib directory exists for linking
    export LD_LIBRARY_PATH="$PWD/../sdk/lib:$LD_LIBRARY_PATH"
  '';

  # autoPatchelf will find libdev.so in $out/lib
  autoPatchelfIgnoreMissingDeps = [ "libdev.so" ];

  installPhase = ''
    runHook preInstall

    # Install binaries
    mkdir -p $out/bin $out/lib $out/share/applications $out/share/icons/hicolor/scalable/apps

    # Install SDK library FIRST (needed for autoPatchelf)
    # The binary expects libdev.so.1.0.2, so copy with correct name and create symlinks
    install -Dm755 ../sdk/lib/libdev.so $out/lib/libdev.so.1.0.2
    ln -s libdev.so.1.0.2 $out/lib/libdev.so.1
    ln -s libdev.so.1.0.2 $out/lib/libdev.so

    # Install executables from bin directory (CMake outputs to source/bin/)
    install -Dm755 ../bin/obsbot-gui $out/bin/obsbot-gui
    install -Dm755 ../bin/obsbot-cli $out/bin/obsbot-cli || true

    # Create desktop entry
    cat > $out/share/applications/obsbot-control.desktop << 'EOF'
[Desktop Entry]
Name=OBSBOT Control
Comment=Control OBSBOT cameras on Linux
Exec=obsbot-gui
Icon=obsbot-control
Terminal=false
Type=Application
Categories=Video;AudioVideo;
EOF

    # Install icon if available
    if [ -f ../resources/icons/obsbot.svg ]; then
      install -Dm644 ../resources/icons/obsbot.svg $out/share/icons/hicolor/scalable/apps/obsbot-control.svg
    fi

    runHook postInstall
  '';

  # Fix RPATH before autoPatchelf runs - remove /build/ references
  preFixup = ''
    # Remove /build/ from RPATH and add $out/lib for libdev.so
    patchelf --remove-rpath $out/bin/obsbot-gui
    patchelf --remove-rpath $out/bin/obsbot-cli || true
  '';

  # Let autoPatchelf find libdev.so in $out/lib
  appendRunpaths = [ "$out/lib" ];

  dontWrapQtApps = false;

  meta = {
    description = "Native Qt6 GUI for controlling OBSBOT cameras on Linux";
    homepage = "https://github.com/aaronsb/obsbot-camera-control";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "obsbot-gui";
  };
}
