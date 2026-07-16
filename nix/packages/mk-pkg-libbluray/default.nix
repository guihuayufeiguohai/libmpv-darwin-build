{ pkgs ? import ../../utils/default/pkgs.nix
, os ? import ../../utils/default/os.nix
, arch ? pkgs.callPackage ../../utils/default/arch.nix { }
, variant ? import ../../utils/default/variant.nix
}:
let
  name = "libbluray";
  packageLock = {
    version = "1.3.4";
    url = "https://github.com/mpvkit/libbluray-build/releases/download/1.4.0/Libbluray.xcframework.zip";
    sha256 = "bc037d34e2b0b5ab7f202fb371f5fb298136cc66fdf406c2172185d06f53f18d"; # nix-prefetch-url
  };
  inherit (packageLock) version;
  callPackage = pkgs.lib.callPackageWith { inherit pkgs os arch variant; };
  pname = import ../../utils/name/package.nix name;
  src = pkgs.fetchurl { inherit (packageLock) url sha256; };
in
pkgs.stdenvNoCC.mkDerivation {
  name = "${pname}-${os}-${arch}-${variant}-${version}";
  inherit version src;
  nativeBuildInputs = [ pkgs.unzip ];
  dontConfigure = true;
  dontBuild = true;

 installPhase = ''
    mkdir -p $out/include/bluray $out/lib

    case ${os} in
      macos)
        bundle="./macos-arm64_x86_64/Libbluray.framework"
        ;;

      ios)
        # ios 只有 arm64 真机
        if [[ "${arch}" != "arm64" && "${arch}" != "universal" ]]; then
          echo "ios only supports arm64, got ${arch}" >&2
          exit 1
        fi
        bundle="./ios-arm64/Libbluray.framework"
        ;;

      iossimulator)
        # ⚠️ mpvkit 1.3.4 zip 里**没有** simulator 切片，先报错说明
        echo "==================================================" >&2
        echo "libbluray 1.3.4 xcframework has no iossimulator slice" >&2
        echo "either:" >&2
        echo "  1. skip libbluray for iossimulator (recommended)" >&2
        echo "  2. use a newer libbluray-build that includes sim" >&2
        echo "==================================================" >&2
        exit 1
        ;;
    esac

    echo "using bundle: $bundle"

    # Headers 是平铺的 .h，不是 bluray/ 子目录
    # mpv 源码里 #include <bluray/bluray.h>，所以目标要建成 $out/include/bluray/
    cp "$bundle/Headers/"*.h "$out/include/bluray/"

    # 无后缀的 Libbluray 就是静态库，重命名为 libbluray.a
    cp "$bundle/Libbluray" "$out/lib/libbluray.a"
  '';
}
