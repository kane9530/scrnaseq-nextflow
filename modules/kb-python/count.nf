params.tech = params.type + params.chemistry

process kb_count {
    label params.aligner
    label "mid_memory"
    tag params.tech
    publishDir params.outdir, mode: "copy"

    input:
        path reads 
        path index 
        path t2g 

    output:
    	file '*' 

    script:
    """
    kb count --tmp ${params.tmpdir} \\
    -i ${index} \\
    -g ${t2g} \\
    -x ${params.tech} \\
    -t 8 \\
    --filter bustools \\
    ${reads}
    """    
}