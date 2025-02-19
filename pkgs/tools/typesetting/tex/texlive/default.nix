/* TeX Live user docs
  - source: ../../../../../doc/languages-frameworks/texlive.xml
  - current html: https://nixos.org/nixpkgs/manual/#sec-language-texlive
*/
{ stdenv, lib, fetchurl, runCommand, writeText, buildEnv
, callPackage, ghostscript_headless, harfbuzz
, makeWrapper
, python3, ruby, perl, tk, jdk, bash, snobol4
, coreutils, findutils, gawk, getopt, gnugrep, gnumake, gnupg, gnused, gzip, ncurses, zip
, libfaketime, asymptote, biber-ms, makeFontsConf
, useFixedHashes ? true
, recurseIntoAttrs
}:
let
  # various binaries (compiled)
  bin = callPackage ./bin.nix {
    ghostscript = ghostscript_headless;
    harfbuzz = harfbuzz.override {
      withIcu = true; withGraphite2 = true;
    };
    inherit useFixedHashes;
  };

  # function for creating a working environment from a set of TL packages
  combine = import ./combine.nix {
    inherit bin combinePkgs buildEnv lib makeWrapper writeText runCommand
      stdenv perl libfaketime makeFontsConf bash tl coreutils gawk gnugrep gnused;
    ghostscript = ghostscript_headless;
  };

  tlpdb = import ./tlpdb.nix;

  tlpdbVersion = tlpdb."00texlive.config";

  # the set of TeX Live packages, collections, and schemes; using upstream naming
  overriddenTlpdb = let
    # most format -> engine links are generated by texlinks according to fmtutil.cnf at combine time
    # so we remove them from binfiles, and add back the ones texlinks purposefully ignore (e.g. mptopdf)
    removeFormatLinks = lib.mapAttrs (_: attrs:
      if (attrs ? formats && attrs ? binfiles)
      then let formatLinks = lib.catAttrs "name" (lib.filter (f: f.name != f.engine) attrs.formats);
               binNotFormats = lib.subtractLists formatLinks attrs.binfiles;
           in if binNotFormats != [] then attrs // { binfiles = binNotFormats; } else removeAttrs attrs [ "binfiles" ]
      else attrs);

    orig = removeFormatLinks (removeAttrs tlpdb [ "00texlive.config" ]); in

    lib.recursiveUpdate orig rec {
      #### overrides of texlive.tlpdb

      #### nonstandard script folders
      context.scriptsFolder = "context/stubs/unix";
      cyrillic-bin.scriptsFolder = "texlive-extra";
      fontinst.scriptsFolder = "texlive-extra";
      mptopdf.scriptsFolder = "context/perl";
      pdftex.scriptsFolder = "simpdftex";
      texlive-scripts.scriptsFolder = "texlive";
      texlive-scripts-extra.scriptsFolder = "texlive-extra";
      xetex.scriptsFolder = "texlive-extra";

      #### interpreters not detected by looking at the script extensions
      ctanbib.extraBuildInputs = [ bin.luatex ];
      de-macro.extraBuildInputs = [ python3 ];
      match_parens.extraBuildInputs = [ ruby ];
      optexcount.extraBuildInputs = [ python3 ];
      pdfbook2.extraBuildInputs = [ python3 ];
      texlogsieve.extraBuildInputs = [ bin.luatex ];

      #### perl packages
      crossrefware.extraBuildInputs = [ (perl.withPackages (ps: with ps; [ LWP URI ])) ];
      ctan-o-mat.extraBuildInputs = [ (perl.withPackages (ps: with ps; [ LWP LWPProtocolHttps ])) ];
      ctanify.extraBuildInputs = [ (perl.withPackages (ps: with ps; [ FileCopyRecursive ])) ];
      ctanupload.extraBuildInputs = [ (perl.withPackages (ps: with ps; [ HTMLFormatter WWWMechanize ])) ];
      exceltex.extraBuildInputs = [ (perl.withPackages (ps: with ps; [ SpreadsheetParseExcel ])) ];
      latex-git-log.extraBuildInputs = [ (perl.withPackages (ps: with ps; [ IPCSystemSimple ])) ];
      latexindent.extraBuildInputs = [ (perl.withPackages (ps: with ps; [ FileHomeDir LogDispatch LogLog4perl UnicodeLineBreak YAMLTiny ])) ];
      pax.extraBuildInputs = [ (perl.withPackages (ps: with ps; [ FileWhich ])) ];
      ptex-fontmaps.extraBuildInputs = [ (perl.withPackages (ps: with ps; [ Tk ])) ];
      purifyeps.extraBuildInputs = [ (perl.withPackages (ps: with ps; [ FileWhich ])) ];
      svn-multi.extraBuildInputs = [ (perl.withPackages (ps: with ps; [ TimeDate ])) ];
      texdoctk.extraBuildInputs = [ (perl.withPackages (ps: with ps; [ Tk ])) ];
      ulqda.extraBuildInputs = [ (perl.withPackages (ps: with ps; [ DigestSHA1 ])) ];

      #### python packages
      pythontex.extraBuildInputs = [ (python3.withPackages (ps: with ps; [ pygments ])) ];

      #### other runtime PATH dependencies
      a2ping.extraBuildInputs = [ ghostscript_headless ];
      bibexport.extraBuildInputs = [ gnugrep ];
      checklistings.extraBuildInputs = [ coreutils ];
      cjk-gs-integrate.extraBuildInputs = [ ghostscript_headless ];
      context.extraBuildInputs = [ coreutils ruby ];
      cyrillic-bin.extraBuildInputs = [ coreutils gnused ];
      dtxgen.extraBuildInputs = [ coreutils getopt gnumake zip ];
      dviljk.extraBuildInputs = [ coreutils ];
      epspdf.extraBuildInputs = [ ghostscript_headless ];
      epstopdf.extraBuildInputs = [ ghostscript_headless ];
      fragmaster.extraBuildInputs = [ ghostscript_headless ];
      installfont.extraBuildInputs = [ coreutils getopt gnused ];
      latexfileversion.extraBuildInputs = [ coreutils gnugrep gnused ];
      listings-ext.extraBuildInputs = [ coreutils getopt ];
      ltxfileinfo.extraBuildInputs = [ coreutils getopt gnused ];
      ltximg.extraBuildInputs = [ ghostscript_headless ];
      luaotfload.extraBuildInputs = [ ncurses ];
      makeindex.extraBuildInputs = [ coreutils gnused ];
      pagelayout.extraBuildInputs = [ gnused ncurses ];
      pdfcrop.extraBuildInputs = [ ghostscript_headless ];
      pdftex.extraBuildInputs = [ coreutils ghostscript_headless gnused ];
      pdftex-quiet.extraBuildInputs = [ coreutils ];
      pdfxup.extraBuildInputs = [ coreutils ghostscript_headless ];
      pkfix-helper.extraBuildInputs = [ ghostscript_headless ];
      ps2eps.extraBuildInputs = [ ghostscript_headless ];
      pst2pdf.extraBuildInputs = [ ghostscript_headless ];
      tex4ht.extraBuildInputs = [ ruby ];
      texlive-scripts.extraBuildInputs = [ gnused ];
      texlive-scripts-extra.extraBuildInputs = [ coreutils findutils ghostscript_headless gnused ];
      thumbpdf.extraBuildInputs = [ ghostscript_headless ];
      tpic2pdftex.extraBuildInputs = [ gawk ];
      wordcount.extraBuildInputs = [ coreutils gnugrep ];
      xdvi.extraBuildInputs = [ coreutils gnugrep ];
      xindy.extraBuildInputs = [ gzip ];

      #### adjustments to binaries
      # TODO patch the scripts from bin.* directly in bin.* instead of here

      # TODO we do not build binaries for the following packages (yet!)
      xpdfopen.binfiles = [];

      # mptopdf is a format link, but not generated by texlinks
      # so we add it back to binfiles to generate it from mkPkgBin
      mptopdf.binfiles = (orig.mptopdf.binfiles or []) ++ [ "mptopdf" ];

      # remove man
      texlive-scripts.binfiles = lib.remove "man" orig.texlive-scripts.binfiles;

      # upmendex is "TODO" in bin.nix
      uptex.binfiles = lib.remove "upmendex" orig.uptex.binfiles;

      # teckit_compile seems to be missing from bin.core{,-big}
      # TODO find it!
      xetex.binfiles = lib.remove "teckit_compile" orig.xetex.binfiles;

      # xindy is broken on some platforms unfortunately
      xindy.binfiles = if bin ? xindy
        then lib.subtractLists [ "xindy.mem" "xindy.run" ] orig.xindy.binfiles
        else [];

      #### additional symlinks
      cluttex.binlinks = {
        cllualatex = "cluttex";
        clxelatex = "cluttex";
      };

      epstopdf.binlinks.repstopdf = "epstopdf";
      pdfcrop.binlinks.rpdfcrop = "pdfcrop";

      ptex.binlinks = {
        pdvitomp = bin.metapost + "/bin/pdvitomp";
        pmpost = bin.metapost + "/bin/pmpost";
        r-pmpost = bin.metapost + "/bin/r-pmpost";
      };

      texdef.binlinks = {
        latexdef = "texdef";
      };

      texlive-scripts.binlinks = {
        mktexfmt = "fmtutil";
        texhash = (lib.last tl."texlive.infra".pkgs) + "/bin/mktexlsr";
      };

      texlive-scripts-extra.binlinks = {
        allec = "allcm";
        kpsepath = "kpsetool";
        kpsexpand = "kpsetool";
      };

      # metapost binaries are in bin.metapost instead of bin.core
      uptex.binlinks = {
        r-upmpost = bin.metapost + "/bin/r-upmpost";
        updvitomp = bin.metapost + "/bin/updvitomp";
        upmpost = bin.metapost + "/bin/upmpost";
      };

      #### add PATH dependencies without wrappers
      # TODO deduplicate this code
      a2ping.postFixup = ''
        sed -i '6i$ENV{PATH}='"'"'${lib.makeBinPath a2ping.extraBuildInputs}'"'"' . ($ENV{PATH} ? ":$ENV{PATH}" : '"'''"');' "$out"/bin/a2ping
      '';

      bibexport.postFixup = ''
        sed -i '2iPATH="${lib.makeBinPath bibexport.extraBuildInputs}''${PATH:+:$PATH}"' "$out"/bin/bibexport
      '';

      checklistings.postFixup = ''
        sed -i '2iPATH="${lib.makeBinPath checklistings.extraBuildInputs}''${PATH:+:$PATH}"' "$out"/bin/checklistings
      '';

      cjk-gs-integrate.postFixup = ''
        sed -i '2i$ENV{PATH}='"'"'${lib.makeBinPath cjk-gs-integrate.extraBuildInputs}'"'"' . ($ENV{PATH} ? ":$ENV{PATH}" : '"'''"');' "$out"/bin/cjk-gs-integrate
      '';

      context.postFixup = ''
        sed -i '2iPATH="${lib.makeBinPath [ coreutils ]}''${PATH:+:$PATH}"' "$out"/bin/{contextjit,mtxrunjit}
        sed -i '2iPATH="${lib.makeBinPath [ ruby ]}''${PATH:+:$PATH}"' "$out"/bin/texexec
      '';

      cyrillic-bin.postFixup = ''
        sed -i '2iPATH="${lib.makeBinPath cyrillic-bin.extraBuildInputs}''${PATH:+:$PATH}"' "$out"/bin/rumakeindex
      '';

      dtxgen.postFixup = ''
        sed -i '2iPATH="${lib.makeBinPath dtxgen.extraBuildInputs}''${PATH:+:$PATH}"' "$out"/bin/dtxgen
      '';

      dviljk.postFixup = ''
        sed -i '2iPATH="${lib.makeBinPath dviljk.extraBuildInputs}''${PATH:+:$PATH}"' "$out"/bin/dvihp
      '';

      epstopdf.postFixup = ''
        sed -i '2i$ENV{PATH}='"'"'${lib.makeBinPath epstopdf.extraBuildInputs}'"'"' . ($ENV{PATH} ? ":$ENV{PATH}" : '"'''"');' "$out"/bin/epstopdf
      '';

      fragmaster.postFixup = ''
        sed -i '2i$ENV{PATH}='"'"'${lib.makeBinPath fragmaster.extraBuildInputs}'"'"' . ($ENV{PATH} ? ":$ENV{PATH}" : '"'''"');' "$out"/bin/fragmaster
      '';

      installfont.postFixup = ''
        sed -i '2iPATH="${lib.makeBinPath installfont.extraBuildInputs}''${PATH:+:$PATH}"' "$out"/bin/installfont-tl
      '';

      latexfileversion.postFixup = ''
        sed -i '2iPATH="${lib.makeBinPath latexfileversion.extraBuildInputs}''${PATH:+:$PATH}"' "$out"/bin/latexfileversion
      '';

      listings-ext.postFixup = ''
        sed -i '2iPATH="${lib.makeBinPath listings-ext.extraBuildInputs}''${PATH:+:$PATH}"' "$out"/bin/listings-ext.sh
      '';

      ltxfileinfo.postFixup = ''
        sed -i '2iPATH="${lib.makeBinPath ltxfileinfo.extraBuildInputs}''${PATH:+:$PATH}"' "$out"/bin/ltxfileinfo
      '';

      ltximg.postFixup = ''
        sed -i '2i$ENV{PATH}='"'"'${lib.makeBinPath ltximg.extraBuildInputs}'"'"' . ($ENV{PATH} ? ":$ENV{PATH}" : '"'''"');' "$out"/bin/ltximg
      '';

      luaotfload.postFixup = ''
        sed -i '2ios.setenv("PATH","${lib.makeBinPath luaotfload.extraBuildInputs}" .. (os.getenv("PATH") and ":" .. os.getenv("PATH") or ""))' "$out"/bin/luaotfload-tool
      '';

      makeindex.postFixup = ''
        sed -i '2iPATH="${lib.makeBinPath makeindex.extraBuildInputs}''${PATH:+:$PATH}"' "$out"/bin/mkindex
      '';

      pagelayout.postFixup = ''
        sed -i '2iPATH="${lib.makeBinPath [ gnused ]}''${PATH:+:$PATH}"' "$out"/bin/pagelayoutapi
        sed -i '2iPATH="${lib.makeBinPath [ ncurses ]}''${PATH:+:$PATH}"' "$out"/bin/textestvis
      '';

      pdfcrop.postFixup = ''
        sed -i '2i$ENV{PATH}='"'"'${lib.makeBinPath pdfcrop.extraBuildInputs}'"'"' . ($ENV{PATH} ? ":$ENV{PATH}" : '"'''"');' "$out"/bin/pdfcrop
      '';

      pdftex.postFixup = ''
        sed -i -e '2iPATH="${lib.makeBinPath [ coreutils gnused ]}''${PATH:+:$PATH}"' \
          -e 's!^distillerpath="/usr/local/bin"$!distillerpath="${lib.makeBinPath [ ghostscript_headless ]}"!' \
          "$out"/bin/simpdftex
      '';

      pdftex-quiet.postFixup = ''
        sed -i '2iPATH="${lib.makeBinPath pdftex-quiet.extraBuildInputs}''${PATH:+:$PATH}"' "$out"/bin/pdftex-quiet
      '';

      pdfxup.postFixup = ''
        sed -i '2iPATH="${lib.makeBinPath pdfxup.extraBuildInputs}''${PATH:+:$PATH}"' "$out"/bin/pdfxup
      '';

      pkfix-helper.postFixup = ''
        sed -i '2i$ENV{PATH}='"'"'${lib.makeBinPath pkfix-helper.extraBuildInputs}'"'"' . ($ENV{PATH} ? ":$ENV{PATH}" : '"'''"');' "$out"/bin/pkfix-helper
      '';

      ps2eps.postFixup = ''
        sed -i '2i$ENV{PATH}='"'"'${lib.makeBinPath ps2eps.extraBuildInputs}'"'"' . ($ENV{PATH} ? ":$ENV{PATH}" : '"'''"');' "$out"/bin/ps2eps
      '';

      pst2pdf.postFixup = ''
        sed -i '2i$ENV{PATH}='"'"'${lib.makeBinPath pst2pdf.extraBuildInputs}'"'"' . ($ENV{PATH} ? ":$ENV{PATH}" : '"'''"');' "$out"/bin/pst2pdf
      '';

      tex4ht.postFixup = ''
        sed -i -e '2iPATH="${lib.makeBinPath tex4ht.extraBuildInputs}''${PATH:+:$PATH}"' -e 's/\\rubyCall//g;' "$out"/bin/htcontext
      '';

      texlive-scripts.postFixup = ''
        sed -i '2iPATH="${lib.makeBinPath texlive-scripts.extraBuildInputs}''${PATH:+:$PATH}"' "$out"/bin/{fmtutil-user,mktexmf,mktexpk,mktextfm,updmap-user}
      '';

      thumbpdf.postFixup = ''
        sed -i '2i$ENV{PATH}='"'"'${lib.makeBinPath thumbpdf.extraBuildInputs}'"'"' . ($ENV{PATH} ? ":$ENV{PATH}" : '"'''"');' "$out"/bin/thumbpdf
      '';

      tpic2pdftex.postFixup = ''
        sed -i '2iPATH="${lib.makeBinPath tpic2pdftex.extraBuildInputs}''${PATH:+:$PATH}"' "$out"/bin/tpic2pdftex
      '';

      wordcount.postFixup = ''
        sed -i '2iPATH="${lib.makeBinPath wordcount.extraBuildInputs}''${PATH:+:$PATH}"' "$out"/bin/wordcount
      '';

      # TODO patch in bin.xdvi
      xdvi.postFixup = ''
        sed -i '2iPATH="${lib.makeBinPath xdvi.extraBuildInputs}''${PATH:+:$PATH}"' "$out"/bin/xdvi
      '';

      xindy.postFixup = ''
        sed -i '2i$ENV{PATH}='"'"'${lib.makeBinPath xindy.extraBuildInputs}'"'"' . ($ENV{PATH} ? ":$ENV{PATH}" : '"'''"');' "$out"/bin/{texindy,xindy}
      '';

      #### other script fixes
      # misc tab and python3 fixes
      ebong.postFixup = ''
        sed -Ei 's/import sre/import re/; s/file\(/open(/g; s/\t/        /g; s/print +(.*)$/print(\1)/g' "$out"/bin/ebong
      '';

      # find files in script directory, not binary directory
      # add runtime dependencies to PATH
      epspdf.postFixup = ''
        sed -i '2ios.setenv("PATH","${lib.makeBinPath epspdf.extraBuildInputs}" .. (os.getenv("PATH") and ":" .. os.getenv("PATH") or ""))' "$out"/bin/epspdf
        substituteInPlace "$out"/bin/epspdftk --replace '[info script]' "\"$scriptsFolder/epspdftk.tcl\""
      '';

      # find files in script directory, not in binary directory
      latexindent.postFixup = ''
        substituteInPlace "$out"/bin/latexindent --replace 'use FindBin;' "BEGIN { \$0 = '$scriptsFolder' . '/latexindent.pl'; }; use FindBin;"
      '';

      # Patch texlinks.sh back to 2015 version;
      # otherwise some bin/ links break, e.g. xe(la)tex.
      # add runtime dependencies to PATH
      texlive-scripts-extra.postFixup = ''
        patch -R "$out"/bin/texlinks < '${./texlinks.diff}'
        sed -i '2iPATH="${lib.makeBinPath [ coreutils ]}''${PATH:+:$PATH}"' "$out"/bin/{allcm,dvired,mkocp,ps2frag}
        sed -i '2iPATH="${lib.makeBinPath [ coreutils findutils ]}''${PATH:+:$PATH}"' "$out"/bin/allneeded
        sed -i '2iPATH="${lib.makeBinPath [ coreutils ghostscript_headless ]}''${PATH:+:$PATH}"' "$out"/bin/dvi2fax
        sed -i '2iPATH="${lib.makeBinPath [ gnused ]}''${PATH:+:$PATH}"' "$out"/bin/{kpsetool,texconfig,texconfig-sys}
        sed -i '2iPATH="${lib.makeBinPath [ coreutils gnused ]}''${PATH:+:$PATH}"' "$out"/bin/texconfig-dialog
      '';

      # patch interpreter
      texosquery.postFixup = ''
        substituteInPlace "$out"/bin/* --replace java "$interpJava"
      '';

      # hardcode revision numbers (since texlive.infra, tlshell are not in either system or user texlive.tlpdb)
      tlshell.postFixup = ''
        substituteInPlace "$out"/bin/tlshell \
          --replace '[dict get $::pkgs texlive.infra localrev]' '${toString orig."texlive.infra".revision}' \
          --replace '[dict get $::pkgs tlshell localrev]' '${toString orig.tlshell.revision}'
      '';
      #### dependency changes

      # it seems to need it to transform fonts
      xdvi.deps = (orig.xdvi.deps or []) ++  [ "metafont" ];

      # remove dependency-heavy packages from the basic collections
      collection-basic.deps = lib.subtractLists [ "metafont" "xdvi" ] orig.collection-basic.deps;

      # add them elsewhere so that collections cover all packages
      collection-metapost.deps = orig.collection-metapost.deps ++ [ "metafont" ];
      collection-plaingeneric.deps = orig.collection-plaingeneric.deps ++ [ "xdvi" ];

      #### misc

      # tlpdb lists license as "unknown", but the README says lppl13: http://mirrors.ctan.org/language/arabic/arabi-add/README
      arabi-add.license = [  "lppl13c" ];

      # TODO: remove this when updating to texlive-2023, npp-for-context is no longer in texlive
      # tlpdb lists license as "noinfo", but it's gpl3: https://github.com/luigiScarso/context-npp
      npp-for-context.license = [  "gpl3Only" ];

      texdoc = {
        extraRevision = "-tlpdb${toString tlpdbVersion.revision}";
        extraVersion = "-tlpdb-${toString tlpdbVersion.revision}";

        # build Data.tlpdb.lua (part of the 'tlType == "run"' package)
        postUnpack = ''
          if [[ -f "$out"/scripts/texdoc/texdoc.tlu ]]; then
            unxz --stdout "${tlpdbxz}" > texlive.tlpdb

            # create dummy doc file to ensure that texdoc does not return an error
            mkdir -p support/texdoc
            touch support/texdoc/NEWS

            TEXMFCNF="${bin.core}"/share/texmf-dist/web2c TEXMF="$out" TEXDOCS=. TEXMFVAR=. \
              "${bin.luatex}"/bin/texlua "$out"/scripts/texdoc/texdoc.tlu \
              -c texlive_tlpdb=texlive.tlpdb -lM texdoc

            cp texdoc/cache-tlpdb.lua "$out"/scripts/texdoc/Data.tlpdb.lua
          fi
        '';
      };

      "texlive.infra" = {
        extraRevision = ".tlpdb${toString tlpdbVersion.revision}";
        extraVersion = "-tlpdb-${toString tlpdbVersion.revision}";

        # add license of tlmgr and TeXLive::* perl packages and of bin.core
        license = [ "gpl2Plus" ] ++ lib.toList bin.core.meta.license.shortName ++ orig."texlive.infra".license or [ ];

        scriptsFolder = "texlive";
        extraBuildInputs = [ coreutils gnused gnupg (lib.last tl.kpathsea.pkgs) (perl.withPackages (ps: with ps; [ Tk ])) ];

        # make tlmgr believe it can use kpsewhich to evaluate TEXMFROOT
        postFixup = ''
          substituteInPlace "$out"/bin/tlmgr \
            --replace 'if (-r "$bindir/$kpsewhichname")' 'if (1)'
          sed -i '2i$ENV{PATH}='"'"'${lib.makeBinPath [ gnupg ]}'"'"' . ($ENV{PATH} ? ":$ENV{PATH}" : '"'''"');' "$out"/bin/tlmgr
          sed -i '2iPATH="${lib.makeBinPath [ coreutils gnused (lib.last tl.kpathsea.pkgs) ]}''${PATH:+:$PATH}"' "$out"/bin/mktexlsr
        '';

        # add minimal texlive.tlpdb
        postUnpack = ''
          if [[ "$tlType" == "tlpkg" ]] ; then
            xzcat "${tlpdbxz}" | sed -n -e '/^name \(00texlive.config\|00texlive.installation\)$/,/^$/p' > "$out"/texlive.tlpdb
          fi
        '';
      };
    }; # overrides

  version = {
    # day of the snapshot being taken
    year = "2023";
    month = "03";
    day = "19";
    # TeX Live version
    texliveYear = 2022;
    # final (historic) release or snapshot
    final = true;
  };

  # The tarballs on CTAN mirrors for the current release are constantly
  # receiving updates, so we can't use those directly. Stable snapshots
  # need to be used instead. Ideally, for the release branches of NixOS we
  # should be switching to the tlnet-final versions
  # (https://tug.org/historic/).
  mirrors = with version; lib.optionals final  [
    # tlnet-final snapshot; used when texlive.tlpdb is frozen
    # the TeX Live yearly freeze typically happens in mid-March
    "http://ftp.math.utah.edu/pub/tex/historic/systems/texlive/${toString texliveYear}/tlnet-final"
    "ftp://tug.org/texlive/historic/${toString texliveYear}/tlnet-final"
  ] ++ [
    # daily snapshots hosted by one of the texlive release managers;
    # used for non-final snapshots and as fallback for final snapshots that have not reached yet the historic mirrors
    # please note that this server is not meant for large scale deployment and should be avoided on release branches
    # https://tug.org/pipermail/tex-live/2019-November/044456.html
    "https://texlive.info/tlnet-archive/${year}/${month}/${day}/tlnet"
  ];

  tlpdbxz = fetchurl {
    urls = map (up: "${up}/tlpkg/texlive.tlpdb.xz") mirrors;
    hash = "sha256-vm7DmkH/h183pN+qt1p1wZ6peT2TcMk/ae0nCXsCoMw=";
  };

  tlpdbNix = runCommand "tlpdb.nix" {
    inherit tlpdbxz;
    tl2nix = ./tl2nix.sed;
  }
  ''
    xzcat "$tlpdbxz" | sed -rn -f "$tl2nix" | uniq > "$out"
  '';

  # map: name -> fixed-output hash
  fixedHashes = lib.optionalAttrs useFixedHashes (import ./fixed-hashes.nix);

  buildTeXLivePackage = import ./build-texlive-package.nix {
    inherit lib fetchurl runCommand bash jdk perl python3 ruby snobol4 tk;
    texliveBinaries = bin;
  };

  tl = lib.mapAttrs (pname: { revision, extraRevision ? "", ... }@args:
    buildTeXLivePackage (args
      # NOTE: the fixed naming scheme must match generate-fixed-hashes.nix
      // { inherit mirrors pname; fixedHashes = fixedHashes."${pname}-${toString revision}${extraRevision}" or { }; }
      // lib.optionalAttrs (args ? deps) { deps = map (n: tl.${n}) (args.deps or [ ]); })
  ) overriddenTlpdb;

  # combine a set of TL packages into a single TL meta-package
  combinePkgs = pkgList: lib.catAttrs "pkg" (
    let
      # a TeX package is an attribute set { pkgs = [ ... ]; ... } where pkgs is a list of derivations
      # the derivations make up the TeX package and optionally (for backward compatibility) its dependencies
      tlPkgToSets = { pkgs, ... }: map ({ tlType, version ? "", outputName ? "", ... }@pkg: {
          # outputName required to distinguish among bin.core-big outputs
          key = "${pkg.pname or pkg.name}.${tlType}-${version}-${outputName}";
          inherit pkg;
        }) pkgs;
      pkgListToSets = lib.concatMap tlPkgToSets; in
    builtins.genericClosure {
      startSet = pkgListToSets pkgList;
      operator = { pkg, ... }: pkgListToSets (pkg.tlDeps or []);
    });

  assertions = with lib;
    assertMsg (tlpdbVersion.year == version.texliveYear) "TeX Live year in texlive does not match tlpdb.nix, refusing to evaluate" &&
    assertMsg (tlpdbVersion.frozen == version.final) "TeX Live final status in texlive does not match tlpdb.nix, refusing to evaluate" &&
    (!useFixedHashes ||
      (let all = concatLists (catAttrs "pkgs" (attrValues tl));
         fods = filter (p: isDerivation p && p.tlType != "bin") all;
      in builtins.all (p: assertMsg (p ? outputHash) "The TeX Live package '${p.pname + lib.optionalString (p.tlType != "run") ("." + p.tlType)}' does not have a fixed output hash. Please read UPGRADING.md on how to build a new 'fixed-hashes.nix'.") fods));

in
  tl // {

    tlpdb = {
      # nested in an attribute set to prevent them from appearing in search
      nix = tlpdbNix;
      xz = tlpdbxz;
    };

    bin = assert assertions; bin // {
      # for backward compatibility
      latexindent = lib.findFirst (p: p.tlType == "bin") tl.latexindent.pkgs;
    };

    combine = assert assertions; combine;

    # Pre-defined combined packages for TeX Live schemes,
    # to make nix-env usage more comfortable and build selected on Hydra.
    combined = with lib;
      let
        # these license lists should be the sorted union of the licenses of the packages the schemes contain.
        # The correctness of this collation is tested by tests.texlive.licenses
        licenses = with lib.licenses; {
          scheme-basic = [ free gfl gpl1Only gpl2 gpl2Plus knuth lgpl21 lppl1 lppl13c mit ofl publicDomain ];
          scheme-context = [ bsd2 bsd3 cc-by-sa-40 free gfl gfsl gpl1Only gpl2 gpl2Plus gpl3 gpl3Plus knuth lgpl2 lgpl21
            lppl1 lppl13c mit ofl publicDomain x11 ];
          scheme-full = [ artistic1-cl8 artistic2 asl20 bsd2 bsd3 bsdOriginal cc-by-10 cc-by-40 cc-by-sa-10 cc-by-sa-20
            cc-by-sa-30 cc-by-sa-40 cc0 fdl13Only free gfl gfsl gpl1Only gpl2 gpl2Plus gpl3 gpl3Plus isc knuth
            lgpl2 lgpl21 lgpl3 lppl1 lppl12 lppl13a lppl13c mit ofl publicDomain x11 ];
          scheme-gust = [ artistic1-cl8 asl20 bsd2 bsd3 cc-by-40 cc-by-sa-40 cc0 fdl13Only free gfl gfsl gpl1Only gpl2
            gpl2Plus gpl3 gpl3Plus knuth lgpl2 lgpl21 lppl1 lppl12 lppl13a lppl13c mit ofl publicDomain x11 ];
          scheme-infraonly = [ gpl2 gpl2Plus lgpl21 ];
          scheme-medium = [ artistic1-cl8 asl20 bsd2 bsd3 cc-by-40 cc-by-sa-20 cc-by-sa-30 cc-by-sa-40 cc0 fdl13Only
            free gfl gpl1Only gpl2 gpl2Plus gpl3 gpl3Plus isc knuth lgpl2 lgpl21 lgpl3 lppl1 lppl12 lppl13a lppl13c mit ofl
            publicDomain x11 ];
          scheme-minimal = [ free gpl1Only gpl2 gpl2Plus knuth lgpl21 lppl1 lppl13c mit ofl publicDomain ];
          scheme-small = [ asl20 cc-by-40 cc-by-sa-40 cc0 fdl13Only free gfl gpl1Only gpl2 gpl2Plus gpl3 gpl3Plus knuth
            lgpl2 lgpl21 lppl1 lppl12 lppl13a lppl13c mit ofl publicDomain x11 ];
          scheme-tetex = [ artistic1-cl8 asl20 bsd2 bsd3 cc-by-40 cc-by-sa-10 cc-by-sa-20 cc-by-sa-30 cc-by-sa-40 cc0
            fdl13Only free gfl gpl1Only gpl2 gpl2Plus gpl3 gpl3Plus isc knuth lgpl2 lgpl21 lgpl3 lppl1 lppl12 lppl13a
            lppl13c mit ofl publicDomain x11];
        };
      in recurseIntoAttrs (
      mapAttrs
        (pname: attrs:
          addMetaAttrs rec {
            description = "TeX Live environment for ${pname}";
            platforms = lib.platforms.all;
            maintainers = with lib.maintainers;  [ veprbl ];
            license = licenses.${pname};
          }
          (combine {
            ${pname} = attrs;
            extraName = "combined" + lib.removePrefix "scheme" pname;
            extraVersion = with version; if final then "-final" else ".${year}${month}${day}";
          })
        )
        { inherit (tl)
            scheme-basic scheme-context scheme-full scheme-gust scheme-infraonly
            scheme-medium scheme-minimal scheme-small scheme-tetex;
        }
    );
  }
