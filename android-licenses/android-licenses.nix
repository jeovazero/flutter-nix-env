# licenses for toolsVersion = "26.1.1";
let
  nixpkgs = import ../nix/pinned.nix;
  inherit (nixpkgs) pkgs lib;
  inherit (builtins) hashString readFile mapAttrs;


  allLicenses = {
    "android-googletv-license" = ./android-googletv-license;
    "android-sdk-license" = ./android-sdk-license;
    "android-sdk-arm-dbt-license" = ./android-sdk-arm-dbt-license;
    "android-sdk-preview-license" = ./android-sdk-preview-license;
    "mips-android-sysimage-license" = ./mips-android-sysimage-license;
    "google-gdk-license" = ./google-gdk-license;
  };

  licenseToHash = name: license: (hashString "sha1" (readFile license));
  licensesMap = mapAttrs licenseToHash allLicenses;
in
  licensesMap
