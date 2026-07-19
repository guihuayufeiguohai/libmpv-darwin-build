# nix/packages/mk-pkg-curl/default.nix
{
  pkgs ? import ../../utils/default/pkgs.nix,
  os ? import ../../utils/default/os.nix,
  arch ? pkgs.callPackage ../../utils/default/arch.nix { },
}:

let
  name = "curl";
  version = "8.21.0";

  callPackage = pkgs.lib.callPackageWith { inherit pkgs os arch; };

  nativeFile = callPackage ../../utils/native-file/default.nix { };
  crossFile = callPackage ../../utils/cross-file/default.nix { };

  pname = import ../../utils/name/package.nix name;

  # 硬编码 src，测试完迁回 packages.lock.nix 即可
  src = pkgs.fetchurl {
    url = "https://curl.se/download/curl-${version}.tar.gz";
    # 先用 fakeHash 让 nix 报错打出真 hash，再替换回来
    hash = pkgs.lib.fakeHash;
    # 真 hash 拿到后长这样（SRI 格式）：
    # sha256 = "sha256-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=";
  };

    targetStdenv =
    if os == "macos" then pkgs.stdenv
    else if os == "ios" then pkgs.pkgsCross.iphone64.stdenv
    else throw "mk-pkg-curl: unsupported os=${os}";

in

targetStdenv.mkDerivation {
  name = "${pname}-${os}-${arch}-${version}";
  pname = pname;
  inherit version src;

  enableParallelBuilding = true;

  nativeBuildInputs = [
    pkgs.pkg-config
  ];

  buildInputs = [ pkgs.zlib ]
    ++ pkgs.lib.optional (os != "macos") pkgs.libiconv;

  configureFlags = [
    "--with-secure-transport"
    "--disable-shared"
    "--enable-static"
    "--without-libidn2"
    "--without-nghttp2"
    "--without-brotli"
    "--without-zstd"
  ] ++ pkgs.lib.optionals (os == "ios") [
    "--host=${targetStdenv.hostPlatform.config}"
  ];

  # 官方 release tarball 自带 configure，不需要 autoconf/automake/libtool
  # 如果你是 git checkout 源码才需要那套
}
