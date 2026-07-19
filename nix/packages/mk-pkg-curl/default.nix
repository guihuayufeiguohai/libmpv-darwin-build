{
  pkgs ? import ../../utils/default/pkgs.nix,
  os ? import ../../utils/default/os.nix,
  arch ? pkgs.callPackage ../../utils/default/arch.nix { },
  variant ? import ../../utils/default/variant.nix,
}:

if os == "ios" then
  pkgs.pkgsCross.iphone64.curl   # iOS arm64 交叉编译的 curl
else if os == "macos" then
  pkgs.curl                       # macOS 原生 curl
else
  pkgs.curl                       # 其他平台回退
