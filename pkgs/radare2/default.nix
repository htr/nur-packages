{ stdenv, fetchFromGitHub, buildPackages, pkgconfig, libusb-compat-0_1, readline
, libewf, perl, zlib, openssl, libuv, file, libzip, xxHash, gtk2 ? null
, vte ? null, gtkdialog ? null, python3 ? null, ruby ? null, lua ? null
, useX11 ? false, rubyBindings ? false, pythonBindings ? false
, luaBindings ? false }:

assert useX11 -> (gtk2 != null && vte != null && gtkdialog != null);
assert rubyBindings -> ruby != null;
assert pythonBindings -> python3 != null;

let
  inherit (stdenv.lib) optional;

  generic = { version_commit, # unused
    gittap, gittip, rev, version, sha256, cs_ver, cs_sha256 }:
    stdenv.mkDerivation {
      pname = "radare2";
      inherit version;

      src = fetchFromGitHub {
        owner = "radare";
        repo = "radare2";
        inherit rev sha256;
      };

      postPatch = let
        capstone = fetchFromGitHub {
          owner = "aquynh";
          repo = "capstone";
          # version from $sourceRoot/shlr/Makefile
          rev = cs_ver;
          sha256 = cs_sha256;
        };
      in ''
        mkdir -p build/shlr
        cp -r ${capstone} capstone-${cs_ver}
        chmod -R +w capstone-${cs_ver}
        # radare 3.3 compat for radare2-cutter
        (cd shlr && ln -s ../capstone-${cs_ver} capstone)
        tar -czvf shlr/capstone-${cs_ver}.tar.gz capstone-${cs_ver}
        # necessary because they broke the offline-build:
        # https://github.com/radare/radare2/commit/6290e4ff4cc167e1f2c28ab924e9b99783fb1b38#diff-a44d840c10f1f1feaf401917ae4ccd54R258
        # https://github.com/radare/radare2/issues/13087#issuecomment-465159716
        curl() { true; }
        export -f curl
      '';

      postInstall = ''
        install -D -m755 $src/binr/r2pm/r2pm $out/bin/r2pm
      '';

      WITHOUT_PULL = "1";
      makeFlags = [
        "GITTAP=${gittap}"
        "GITTIP=${gittip}"
        "RANLIB=${stdenv.cc.bintools.bintools}/bin/${stdenv.cc.bintools.targetPrefix}ranlib"
      ];
      configureFlags = [
        "--with-sysmagic"
        "--with-syszip"
        "--with-sysxxhash"
        "--with-openssl"
      ];

      enableParallelBuilding = true;
      depsBuildBuild = [ buildPackages.stdenv.cc ];

      nativeBuildInputs = [ pkgconfig ];
      buildInputs =
        [ file readline libusb-compat-0_1 libewf perl zlib openssl libuv ]
        ++ optional useX11 [ gtkdialog vte gtk2 ]
        ++ optional rubyBindings [ ruby ] ++ optional pythonBindings [ python3 ]
        ++ optional luaBindings [ lua ];

      propagatedBuildInputs = [
        # radare2 exposes r_lib which depends on these libraries
        file # for its list of magic numbers (`libmagic`)
        libzip
        xxHash
      ];

      meta = {
        description =
          "unix-like reverse engineering framework and commandline tools";
        homepage = "http://radare.org/";
        license = stdenv.lib.licenses.gpl2Plus;
        maintainers = with stdenv.lib.maintainers; [ raskin makefu mic92 ];
        platforms = with stdenv.lib.platforms; linux;
        inherit version;
      };
    };
in {
  #<generated>
  # DO NOT EDIT! Automatically generated by ./update.py
  radare2 = generic {
    version_commit = "25219";
    gittap = "4.5.1";
    gittip = "293cf5ae65ba4e28828095dcae212955593ba255";
    rev = "4.5.1";
    version = "4.5.1";
    sha256 = "0qigy1px0jy74c5ig73dc2fqjcy6vcy76i25dx9r3as6zfpkkaxj";
    cs_ver = "4.0.2";
    cs_sha256 = "0y5g74yjyliciawpn16zhdwya7bd3d7b1cccpcccc2wg8vni1k2w";
  };
  r2-for-cutter = generic {
    version_commit = "25219";
    gittap = "4.5.0";
    gittip = "9d7eda5ec7367d1682e489e92d1be8e37e459296";
    rev = "9d7eda5ec7367d1682e489e92d1be8e37e459296";
    version = "2020-07-17";
    sha256 = "1vnvfgg48bccm41pdyjsql6fy1pymmfnip4w2w56b45d7rqcc3v8";
    cs_ver = "4.0.2";
    cs_sha256 = "0y5g74yjyliciawpn16zhdwya7bd3d7b1cccpcccc2wg8vni1k2w";
  };
  #</generated>
}
