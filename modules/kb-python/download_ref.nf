
process kb_download_ref {
    label params.aligner
    label "low_memory"
    publishDir params.kb_ref_files, mode: "copy"

    output:
	path "index.idx"
	path "t2g.txt"

    script:
    """
    kb ref --tmp ${params.tmpdir} --verbose --workflow standard -d ${params.species} -i index.idx -g t2g.txt
    """
}