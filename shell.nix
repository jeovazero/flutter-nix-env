{ pinnedNixpkgs ? import ./nix/pinned.nix }:
let
  nixpkgs = pinnedNixpkgs { config = { android_sdk.accept_license = true; }; };
  nixpkgsUnstable = import ./nix/pinned-unstable.nix { };

  scrcpy = nixpkgsUnstable.pkgs.scrcpy;

  inherit (nixpkgs) pkgs lib fetchurl;
  inherit (pkgs) jdk8_headless flutter dart;

  # Dart Beta for null-safety
  # only for tests purpose
  baseDartArchive = "https://storage.googleapis.com/dart-archive/channels";
  channel = "beta";
  dartVersion = "2.12.0-259.8.beta";
  dartArchiveUrl = "${baseDartArchive}/${channel}/release/${dartVersion}"
    + "/sdk/dartsdk-linux-x64-release.zip";

  dart_beta = dart.override ({
    version = dartVersion;
    sources = {
      "${dartVersion}-x86_64-linux" = fetchurl {
        url = dartArchiveUrl;
        sha256 =
          "3f99b4bfc3ddb9772b231bf15e8f271db623fd99fc89aa76eff684f2c8188e33";
      };
    };
  });

  # Android
  android = pkgs.androidenv.composeAndroidPackages {
    buildToolsVersions = [ "28.0.3" ];
    platformVersions = [ "29" ];
    abiVersions = [ "x86" "x86_64" ]; # verify
  };

  licensesMap = import ./android-licenses/android-licenses.nix;

  licenceSymbolic = licenseName: licenseHash:
    let licenseFile = pkgs.writeText licenseName ("\n" + licenseHash);
    in ''
      ln -s ${licenseFile} $out/libexec/android-sdk/licenses/${licenseName}
    '';

  licensesSymbolicList =
    lib.attrsets.mapAttrsToList licenceSymbolic licensesMap;

  installPhaseAdditional = ''
    mkdir -p $out/libexec/android-sdk/licenses
  '' + (builtins.concatStringsSep "\n" licensesSymbolicList);

  androidsdk = android.androidsdk.overrideAttrs (oldAttrs: {
    installPhase = oldAttrs.installPhase + installPhaseAdditional;
  });
in pkgs.mkShell {
  # using flutter and dart stable
  buildInputs = [ flutter androidsdk jdk8_headless dart scrcpy ];
  shellHook = ''
    mkdir -p ~/.pub-cache
    export ANDROID_HOME=${androidsdk}/libexec/android-sdk
    export JAVA_HOME=${jdk8_headless.home}
    export PUB_CACHE=~/.pub-cache
  '';
}
