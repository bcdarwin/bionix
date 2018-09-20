{ stdenv
, callPackage
, lib
, samtools
, nameSort ? false
, flags ? null
}:

input:

with lib;

stdenv.mkDerivation {
  name = "samtools-sort";
  buildInputs = [ samtools ];
  buildCommand = ''
    samtools sort -@ $NIX_BUILD_CORES ${optionalString nameSort "-n"} ${optionalString (flags != null) flags} ${input} > $out
  '';
}