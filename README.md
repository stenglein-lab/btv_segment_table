# btv_segment_table
A pipeline to quantify #s of reads mapping to bluetongue virus (BTV) segments in a co-infection/reassortment experiment

## How to run:

**Step 1:** make sure you are running on a computer that has nextflow and singularity installed.  See [Dependencies section](#dependencies).

**Step 2:** your fastq files must be available to the pipeline and you should know what directory they are in.  In the example below, fastq files are in the directory `/path/to/fastq`

**Step 3:** ensure you are using the correct BTV reference sequences.  See [this section](#btv-reference-sequence) for more information.

**Step 4:** actually run the pipeline.  Use netflow to run the pipeline.  This command line tells nextflow to download the pipeline code from [this repository](https://github.com/stenglein-lab/btv_segment_table) and to run it using singularity to handle software [dependencies](#dependencies).  You must tell the pipeline where your fastq files are, using the --fastq_dir option.

```
nextflow run stenglein-lab/btv_segment_table -profile singularity --fastq_dir /path/to/fastq
```

## Output

The pipeline output will be placed in a `results` directory in the directory you run the nextflow command from (for this reason, it is good to run each analysis in a dedicated directory).  

The main pipeline output is two tables:

1. segment_tables.txt: this file contains the #s of reads mapping to each segment for each BTV genotype in each dataset.
2. all_segment_counts_tidy.txt: this file contains the #s of reads mapping to each segment for each dataset and genotype. This is in tidyverse-style 'tidy' = 'long' [format](https://tidyr.tidyverse.org/articles/tidy-data.html), so would be appropriate for import into an R script and further analysis using tidyverse/ggplot2.  

## Dependencies

This pipeline has two main dependencies: nextflow and singularity.  These programs must be installed on your computer to run this pipeline.

### Nextflow

To run the pipeline you will need to be working on a computer that has nextflow installed. Installation instructions can be [found here](https://www.nextflow.io/docs/latest/getstarted.html#installation).  To test if you have nextflow installed, run:

```
nextflow -version
```

This pipeline requires nextflow version > 22.04

### Singularity 

The pipeline uses singularity containers to run programs like bowtie2 and R.  To use these containers you must be running the pipeline on a computer that has [singularity](https://sylabs.io/singularity) [installed](https://sylabs.io/guides/latest/admin-guide/installation.html).  To test if singularity is installed, run:

```
singularity --version
```


Singularity containers will be automatically downloaded and stored in a directory named `singularity_cacheDir` in your home directory.  They will only be downloaded once.


## Configuration options

### BTV Reference Sequence

The BTV reference sequences must be supplied to the pipeline in FASTA format.  The pipeline comes with a default reference sequence file, [here](./input/refseq/btv_refseq.fasta)).

It is possible to provide a FASTA file with different BTV reference sequences.  When you run the pipeline, simply use the --refseq_fasta command line option, for instance:

```
nextflow run stenglein-lab/btv_segment_table -profile singularity --fastq_dir /path/to/fastq --refseq_fasta /path/to/btv/refseq.fasta
```

#### Reference sequence naming

The BTV reference sequences are expected to be named BTV#_seg#, for instance: BTV2_seg8 or BTV17_seg1.  If sequences are named differently, the pipeline will error.

See [this file](./input/refseq/btv_refseq.fasta) for an example of BTV reference sequences with correct naming.

### Primers

The pipeline uses cutadapt to trim primers off of reads.  The primer sequences should supplied in a FASTA format file.  The pipeline uses [this file](./input/refseq/BTV_primers.fasta) of primer sequences by default.  A different file can be supplied using the --primers_to_trim_file option, e.g.:

```
nextflow run stenglein-lab/btv_segment_table -profile singularity --fastq_dir /path/to/fastq --primers_to_trim_file /path/to/btv/primer_sequences.fasta
```

### All configuration options

The [nextflow.config](./nextflow.config) file contains default values for all configuration options.  The default value for any of these options can be overridden on the command line.  For instance:

```
# run pipeline with bowtie2 local mode instead of default end-to-end
nextflow run stenglein-lab/btv_segment_table -profile singularity --bt_mode local
```




## Old way of running this pipeline

I implemented this pipeline in nextflow/[dsl2](https://www.nextflow.io/docs/latest/dsl2.html) syntax, and designed it to be [run from github](https://www.nextflow.io/docs/latest/sharing.html).  I also followed the [nf-core way](https://nf-co.re/developers/guidelines) of using dsl2 modules and used some off-the-shelf [nf-core modules](https://github.com/nf-core/modules). This pipeline is relatively simple so in some ways using this approach may be overly complicated.  But I had been meaning to learn dsl2 nextflow, so I used this as a learning opportunity.

Before this nextflow implementation, we used a series of bash scripts to analyze datasets.  The main steps were:

1. Clean up data using a script like [this one](./scripts/run_preprocessing_pipeline_one_sample_btv)
2. Map reads to a BTV reference sequence, using a script like [this](./scripts/run_bt_align_paired_endtoend)
3. Tabulate reads mapping to different segments using a script like [this](./scripts/make_segment_table_from_sam)

We would use the [simple_scheduler script](https://github.com/stenglein-lab/stenglein_lab_scripts/blob/master/simple_scheduler) to run these for multiple datasets.

The pipeline does basically the same workflow now and looking at these simpler bash scripts can help you understand what is happening.  The current nextflow/dsl2/singularity/nf-core implementation is powerful but it can be more difficult to follow what the pipeline is actually doing.

Note that if you run the pipeline from github, as described above, the pipeline code will be downloaded and cached in directory: `$HOME/.nextflow/assets/stenglein-lab/btv_segment_table/`




#### nf-core modules:

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/master/LICENSE).

> The nf-core framework for community-curated bioinformatics pipelines.
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> Nat Biotechnol. 2020 Feb 13. doi: 10.1038/s41587-020-0439-x.
