process MAKE_SEGMENT_TABLE {
    tag "$tsv"
    label 'process_low'

    conda (params.enable_conda ? 'conda-forge::r-tidyverse=1.3.1' : null) 
    // why aren't singularity biocontainers updated to a newer tidyverse version?
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/r-tidyverse:1.2.1' : 
        'quay.io/biocontainers/r-tidyverse:1.2.1' }"

    input:
    path(tsv)                                                

    output:
    path "segment_tables.txt" ,          emit: segment_table
    path "all_segment_counts_tidy.txt" , emit: tidy_tsv
    path "versions.yml" ,                emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    # make a copy of input file so can be output to results dir
    cp $tsv all_segment_counts_tidy.txt

    # make a slightly untidy table too
    make_segment_table.R $tsv segment_tables.txt
    

    cat <<-END_VERSIONS > versions.yml
    "!{task.process}":
        R: \$(echo \$(R --version 2>&1))
    END_VERSIONS
    """
}
