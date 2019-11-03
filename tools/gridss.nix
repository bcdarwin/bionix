{bionix}:

with bionix;

rec {
  jar = pkgs.fetchurl {
    url = "https://github.com/PapenfussLab/gridss/releases/download/v2.7.1/gridss-2.7.1-gridss-jar-with-dependencies.jar";
    sha256 = "0g8as418567dpd9vck923g2i18glhvwxlm8jy8khlrk7ja2xvc6p";
  };

  /* Generate configuration file for GRIDSS. Takes attribute sets to GRIDSS ini style format.
  Type: genConfig :: attrSet -> ini file
  */
  genConfig = callBionix ./gridss-configFile.nix {};

  /* Invoke the callVariants tool
  Type: callVariants :: {blacklist :: drv = null, config :: ini = null, heapSize :: String = "31g", ...} -> [bam] -> variants
  */
  callVariants = callBionixE ./gridss-callVariants.nix;

  /* Invoke computeSamTags tool
  Type: computeSamTags :: {config :: ini = null, heapSize :: String = "1G", ...} -> bam -> bam
  */
  computeSamTags = callBionixE ./gridss-computeSamTags.nix;

  /* Invoke softClipsToSplitReads tool
  Type: softClipsToSplitReads :: {alignerStreaming :: Bool = false, config :: ini = null, heapSize :: String = "2G", ...} -> bam -> bam
  */
  softClipsToSplitReads = callBionixE ./gridss-softClipsToSplitReads.nix;

  /* Invoke collectMetrics tool
  Type: collectMetrics :: {thresholdCoverage :: Int = 10000, config :: ini = null, heapSize :: String = "1G", ...} -> bam -> metrics
  */
  collectMetrics = callBionixE ./gridss-collectMetrics.nix;

  /* Invoke extractSVReads tool
  Type: extractSVReads :: {unmappedReads :: Bool = false, minClipLength :: Int = 5, config :: ini = null, ...} -> bam -> bam
  */
  extractSVReads = callBionixE ./gridss-extractSVReads.nix;

  /* Invoke assembly tool
  Type: assemble :: {config :: ini = null, heapSize :: String = "31g", ...} -> [bam] -> bam
  */
  assemble = callBionixE ./gridss-assemble.nix;

  /* Invoke identifyVariants tool
  Type: identifyVariants :: {config :: ini = null, heapSize :: String = "4g", ...} -> [bam] -> VCF
  */
  identifyVariants = exec (attrs: input: ((callBionix ./gridss-variants.nix attrs) input).identify);

  /* Invoke annotateVariants tool
  Type: annotateVariants :: {config :: ini = null, heapSize :: String = "4g", ...} -> [bam] -> VCF
  */
  annotateVariants = exec (attrs: input: ((callBionix ./gridss-variants.nix attrs) input).annotate);

  /* As annotateVariants except include assembly in output */
  annotateAndAssemble = exec (attrs: input: ((callBionix ./gridss-variants.nix attrs) input).annotateAndAssemble);

  /* Preprocess BAM files to extract SV reads and convert soft clips to split reads
  Type: preprocessBam :: bam -> bam
  */
  preprocessBam = with samtools;
    pipe [
      (gridss.extractSVReads {})
      (sort {nameSort = true;})
      (gridss.computeSamTags {})
      (gridss.softClipsToSplitReads {})
      (sort {})
    ];

  /* Call SVs: entire pipeline including preprocessing. It is recommended to use this function rather than the individual above tools.
  Type: [bam] -> GRIDSS result
  */
  call = inputs: gridss.annotateVariants {} (map gridss.preprocessBam inputs);

  /* As call but include assemblies in output */
  callAndAssemble = inputs: gridss.annotateAndAssemble {} (map gridss.preprocessBam inputs);
}
