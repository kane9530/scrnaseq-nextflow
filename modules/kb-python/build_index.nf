process kb_build_index {
    label params.aligner
    label "mid_memory"
    publishDir params.kb_ref_files, mode: "copy"
    
    input:
        path fasta 
        path gtf 
    
    output:
        path "index.idx" , emit: index_file
        path "t2g.txt", emit: t2g_file

    script:
    """
    kb ref --tmp ${params.tmpdir} --verbose --workflow standard -i index.idx -g t2g.txt -f1 cDNA.fa ${fasta} ${gtf}
    """
}
