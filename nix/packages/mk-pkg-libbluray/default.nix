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
    mkdir -p $out/include $out/lib
    root="$sourceRoot/Libbluray.xcframework"

    case ${os} in
      macos)
        # macos-arm64_x86_64 是 fat (arm64+x86_64)，universal 一档
        bundle="$root/macos-arm64_x86_64/Libbluray.framework"
        ;;

      ios)
        # ios 只有 arm64 真机，arch 参数这里其实恒为 arm64，但留个 case 防以后
        if [[ "${arch}" != "arm64" && "${arch}" != "universal" ]]; then
          echo "ios only supports arm64, got ${arch}" >&2
          exit 1
        fi
        bundle="$root/ios-arm64/Libbluray.framework"
        ;;

      iossimulator)
        # ⚠️ mpvkit 1.3.4 zip 里**没有** simulator 切片，这里先 placeholder
        # 如果你换了带 sim 的版本（比如自己编的 / libbluray-build 1.4.1+），
        # 按 arch 分流：
        #   arm64     → ios-arm64-simulator 或 ios-arm64_x86_64-simulator 里拆 thin
        #   amd64     → ios-arm64_x86_64-simulator 里拆 thin x86_64
        #   universal → ios-arm64_x86_64-simulator 直接用 fat
        case ${arch} in
          arm64)
            bundle="$root/ios-arm64-simulator/Libbluray.framework"      # 新命名（Xcode 15+）
            # bundle="$root/ios-arm64_x86_64-simulator/Libbluray.framework"  # 旧命名 fat
            ;;
          amd64)
            bundle="$root/ios-arm64_x86_64-simulator/Libbluray.framework"
            ;;
          universal)
            bundle="$root/ios-arm64_x86_64-simulator/Libbluray.framework"
            ;;
        esac
        # 如果 zip 里没这档，下面 cp 会 fail，故意的——让你早点发现
        ;;

      *)
        echo "unsupported os: ${os}" >&2
        exit 1
        ;;
    esac

    echo "using bundle: $bundle"
    cp -r "$bundle/Headers/bluray" "$out/include/bluray"
    cp "$bundle/Libbluray" "$out/lib/libbluray.a"
  '';
}
