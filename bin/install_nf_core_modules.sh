#!/bin/bash 

# install off-the-shelf nf-core modules that will be used in this pipeline
# MDS 10/18/2022

nf-core modules install fastq
nf-core modules install multiqc
nf-core modules install bowtie2/align
nf-core modules install bowtie2/build
nf-core modules install cutadapt
nf-core modules install custom/dumpsoftwareversions
nf-core modules install spades

# no module for:
# cd-hit-dup
