{ pkgs ? import ../../utils/default/pkgs.nix
, os ? import ../../utils/default/os.nix
, arch ? pkgs.callPackage ../../utils/default/arch.nix { }
, variant ? import ../../utils/default/variant.nix
}:
let
  name = "libbluray";
  packageLock = {
    version = "1.4.0-ci-fix";
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
  mkdir -p $out/include/bluray $out/lib $out/lib/pkgconfig

  case ${os} in
    macos)
      bundle="./macos-arm64_x86_64/Libbluray.framework"
      ;;
    ios)
      bundle="./ios-arm64/Libbluray.framework"
      ;;
    iossimulator)
      bundle="./ios-arm64/Libbluray.framework"
      ;;
  esac

  # 复制头文件
  cp "$bundle/Headers/"*.h "$out/include/bluray/"

  # 复制静态库并重命名
  cp "$bundle/Libbluray" "$out/lib/libbluray.a"

  # 创建 pkg-config 文件
  cat > "$out/lib/pkgconfig/libbluray.pc" << 'PKGCONFIG'
prefix=@out@
exec_prefix=''${prefix}
libdir=''${exec_prefix}/lib
includedir=''${prefix}/include

Name: libbluray
Description: Blu-ray disc playback library
Version: @version@
Requires:
Libs: -L''${libdir} -lbluray
Cflags: -I''${includedir}
PKGCONFIG
  sed -i "s|@out@|$out|g; s|@version@|${version}|g" "$out/lib/pkgconfig/libbluray.pc"
'';
}
