# mk-pkg-curl/default.nix
{
  pkgs ? import ../../utils/default/pkgs.nix,
  os ? import ../../utils/default/os.nix,
  arch ? pkgs.callPackage ../../utils/default/arch.nix { },
  variant ? import ../../utils/default/variant.nix,
}:

let
  name = "curl";
  packageLock = (import ../../../packages.lock.nix).${name} or null;
  version = if packageLock != null then packageLock.version else "8.11.0";

  # 根据目标平台选择正确的 stdenv
  targetSystem =
    if os == "ios" then "aarch64-apple-ios"
    else if os == "macos" then "aarch64-apple-darwin"
    else "x86_64-unknown-linux-gnu";  # 这里只处理 Apple 平台

  # 使用 Nixpkgs 的交叉编译基础设施
  pkgsCross = pkgs.pkgsCross.${targetSystem};

  # 从交叉编译的 Nixpkgs 中获取 curl
  curlPackage = pkgsCross.curl.overrideAttrs (old: {
    # 可根据需要调整构建配置
    configureFlags = old.configureFlags ++ [
      "--with-darwinssl"        # 使用 iOS/macOS 原生 SecureTransport
      "--disable-ldap"
      "--without-libpsl"
    ];
    # 移除不必要的依赖
    buildInputs = with pkgsCross; [ zlib ];
  });
in
curlPackage
