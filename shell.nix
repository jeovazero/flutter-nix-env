{ pinnedNixpkgs ? import ./nix/pinned.nix }:
let
  nixpkgs = pinnedNixpkgs {
    config = {
      android_sdk.accept_license = true;
    };
  };

  inherit (nixpkgs) pkgs lib;
  inherit (pkgs) jdk8_headless flutter;

  android = pkgs.androidenv.composeAndroidPackages {
    buildToolsVersions = [ "28.0.3" ];
    platformVersions = [ "29" ];
    abiVersions = [ "x86" "x86_64"];
  };

  licensesMap = import ./android-licenses/android-licenses.nix;

  licenceSymbolic = licenseName: licenseHash:
  let
    licenseFile = pkgs.writeText licenseName ("\n"+licenseHash);
  in
  ''
    ln -s ${licenseFile} $out/libexec/android-sdk/licenses/${licenseName}
  '';

  licensesSymbolicList = lib.attrsets.mapAttrsToList licenceSymbolic licensesMap;

  installPhaseAdditional = ''
    mkdir -p $out/libexec/android-sdk/licenses
  '' + (builtins.concatStringsSep "\n" licensesSymbolicList);

  androidsdk = android.androidsdk.overrideAttrs (oldAttrs: {
    installPhase = oldAttrs.installPhase + installPhaseAdditional;
  });
in
  pkgs.mkShell {
    buildInputs = [
      flutter
      androidsdk
      jdk8_headless
    ];

    shellHook = ''
      export ANDROID_HOME=${androidsdk}/libexec/android-sdk
      export JAVA_HOME=${jdk8_headless.home}
    '';
  }
