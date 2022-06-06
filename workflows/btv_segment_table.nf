include { FASTQC   as FASTQC_PRE      } from '../modules/nf-core/modules/fastqc/main'
include { CUTADAPT                    } from '../modules/nf-core/modules/cutadapt/main'
include { FASTQC   as FASTQC_POST     } from '../modules/nf-core/modules/fastqc/main'
include { BOWTIE2_BUILD               } from '../modules/nf-core/modules/bowtie2/build/main'
include { BOWTIE2_ALIGN               } from '../modules/nf-core/modules/bowtie2/align/main'
include { EXTRACT_READ_MAPPING_COUNTS } from '../modules/local/extract_read_mapping_counts.nf'
include { PREPEND_TSV_WITH_ID         } from '../modules/local/prepend_tsv_with_id.nf'
include { MAKE_SEGMENT_TABLE          } from '../modules/local/make_segment_table.nf'
include { MULTIQC                     } from '../modules/nf-core/modules/multiqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from '../modules/nf-core/modules/custom/dumpsoftwareversions/main'


workflow BTV_SEGMENT_TABLE {

  ch_versions = Channel.empty()                                               

  // input files
  /*
   These fastq files are the main input to this workflow
  */

  Channel.fromFilePairs("${params.fastq_dir}/${params.fastq_pattern}", size: -1, checkIfExists: true, maxDepth: 1)
  .map{ name, reads ->

         // define a new empty map named meta for each sample
         // and populate it with id and single_end values
         // for compatibility with nf-core module expected parameters
         // reads are just the list of fastq
         def meta        = [:]

         // this map gets rid of any _S\d+ at the end of sample IDs but leaves fastq
         // names alone.  E.g. strip _S1 from the end of a sample ID..  
         // This is typically sample #s from Illumina basecalling.
         // could cause an issue if sequenced the same sample with 
         // multiple barcodes so was repeated on a sample sheet. 
         meta.id         = name.replaceFirst( /_S\d+$/ ,"")

         // if 2 fastq files then paired end data, so single_end is false
         meta.single_end = reads[1] ? false : true

         // this last statement in the map closure is the return value
         [ meta, reads ] }

  .set { ch_reads }

  // run fastqc on input reads
  FASTQC_PRE ( ch_reads )
  
  ch_versions = ch_versions.mix ( FASTQC_PRE.out.versions )      

  // run cutadapt to trim reads
  // cutadapt parameters are specified in ./conf/modules.config
  CUTADAPT ( ch_reads )

  ch_versions = ch_versions.mix ( CUTADAPT.out.versions ) 

  // run fastqc on post trimmed reads
  FASTQC_POST ( CUTADAPT.out.reads )

  // build bowtie2 index for viral refseq
  BOWTIE2_BUILD ( params.refseq_fasta )
  ch_versions = ch_versions.mix ( BOWTIE2_BUILD.out.versions )

  // map trimmed reads to refseq
  BOWTIE2_ALIGN(CUTADAPT.out.reads,
            BOWTIE2_BUILD.out.index,
            false, // save unaligned
            true)  // sort bam: why not? 

  ch_versions = ch_versions.mix ( BOWTIE2_ALIGN.out.versions )

  // use samtools to quantify the # of reads mapping to each refseq
  EXTRACT_READ_MAPPING_COUNTS ( BOWTIE2_ALIGN.out.bam )

  // prepend sample ID onto read counts
  PREPEND_TSV_WITH_ID ( EXTRACT_READ_MAPPING_COUNTS.out.tsv )

  // create main table outputs
  MAKE_SEGMENT_TABLE( PREPEND_TSV_WITH_ID.out.prepended_tsv_file.collectFile (name: 'all_read_counts.txt') )

  //                                                                          
  // MODULE: Pipeline reporting                                               
  //                                                                          
  CUSTOM_DUMPSOFTWAREVERSIONS (                                               
      ch_versions.unique().collectFile(name: 'collated_versions.yml')         
  )    

  //                                                                          
  // MODULE: MultiQC                                                          
  //                                                                          
  // workflow_summary    = WorkflowRnaseq.paramsSummaryMultiqc(workflow, summary_params)
  // ch_workflow_summary = Channel.value(workflow_summary)                   

  // collect files that will be input to multiqc
  ch_multiqc_files = Channel.empty()
  ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())
  ch_multiqc_files = ch_multiqc_files.mix(FASTQC_PRE.out.zip.collect{it[1]}.ifEmpty([]))
  ch_multiqc_files = ch_multiqc_files.mix(FASTQC_POST.out.zip.collect{it[1]}.ifEmpty([]))
  ch_multiqc_files = ch_multiqc_files.mix(CUTADAPT.out.log.collect{it[1]}.ifEmpty([]))

  // run multiqc
  MULTIQC (
      ch_multiqc_files.collect()
  )
  multiqc_report = MULTIQC.out.report.toList()
  ch_versions    = ch_versions.mix(MULTIQC.out.versions)

}
