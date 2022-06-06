process PREPEND_TSV_WITH_ID {
    tag "$tsv"
    label 'process_low'

    // we just need a base linux environment for this module
    // which is an assumption of the nextflow pipeline

    // no conda environment for a base linux system
    // conda (params.enable_conda ? 'bioconda::samtools=1.15.1' : null)

    // not sure if using a singularity container here even makes sense...
    /*
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04'
        'quay.io/biocontainers/ubuntu:20.04' }"
    */

    input:
    tuple val(meta), path(tsv)                                                

    output:
    tuple val(meta), path ("*.prepended.tsv") , emit: prepended_tsv
    path ("*prepended.tsv") ,                   emit: prepended_tsv_file
    path "versions.yml" ,                       emit: versions

    when:
    task.ext.when == null || task.ext.when

    // def args = task.ext.args ?: ''
    // def prefix = task.ext.prefix ?: "${meta.id}"                                

    shell:
    // prepend tsv output with a column containing sample ID (or value of task.ext.prefix)
    '''
    cat !{tsv} | awk '{print "!{meta.id}" "\t" $0}' > "!{tsv}.!{meta.id}.prepended.tsv"
    

    cat <<-END_VERSIONS > versions.yml
    "!{task.process}":
    END_VERSIONS
    '''
}
