#!/usr/bin/env nextflow
////////////////////////////////////////////////////
/*
 * Configuration parameters

 ////////////////////////////////////////////////////
// If kb-aligner used and user specifies that indices have been prebuilt, check if index AND t2g files are supplied

nextflow.enable.dsl=2

if ( params.aligner == 'kb' && params.kb_prebuilt && !(params.kb_index || params.kb_t2g) ){
    exit 1, "If kb has been prebuilt, you need to supply its precomputed index and the transcript to gene .txt file! Otherwise, leave kb_prebuilt to false to run kb ref"
}

// If kb-aligner used and is not prebuilt, check if species are human or mouse. Otherwise, gtf and fasta files must BOTH be supplied.
if ( params.aligner == "kb" && !params.kb_prebuilt && !(params.gtf || params.fasta) && !(params.species == 'human' || params.species == 'mouse') ){
    exit 1, "If kb has not been prebuilt for non human/mouse species, you need to supply the gtf and genome fasta files."
}

// If genome is specified, check if genome exists in the config file
if (params.genomes && params.genome && !params.genomes.containsKey(params.genome)) {
    exit 1, "The provided genome '${params.genome}' is not available in the iGenomes file. Currently the available genomes are ${params.genomes.keySet().join(', ')}"
}

//Check if one of the available aligners is used (alevin, kb, star)
if (params.aligner != 'star' && params.aligner != 'alevin' && params.aligner != 'kb'){
    exit 1, "Invalid aligner option: ${params.aligner}. Valid options: 'star', 'alevin', 'kb'"
}
*/

////////////////////////////////////////////////////
/*
 * Create channels


// Input read files
Channel
    .fromPath( params.input )
    .ifEmpty { exit 1, "Cannot find any reads matching: ${params.input}\nNB: Path needs to be enclosed in quotes!\n\NB: Path requires at least one * wildcard!\n" }

// index file
if (params.kb_index){
    Channel
	.fromPath(params.kb_index)
	.ifEmpty { exit 1, "index file not found: ${params.kb_index}"}
	.set {kb_prebuilt_index}
} else {
  kb_prebuilt_index = Channel.empty()
}

// t2g file
if (params.kb_t2g){
   Channel
	.fromPath(params.kb_t2g)
	.ifEmpty { exit 1, "t2g file not found: ${params.kb_t2g}"}
	.set {kb_prebuilt_t2g}
}  else {
   kb_prebuilt_t2g = Channel.empty()
}
 */

 ////////////////////////////////////////////////////
////////////////////////////////////////////////////
/*
 * Run kb-python pipeline
 */ 
 ////////////////////////////////////////////////////

params.kb_ref_files = "${params.outdir}/reference/kb"
params.tech = params.type + params.chemistry
//params.gtf = "${projectDir}/reference/Homo_sapiens.GRCh38.106.gtf.gz"
//params.fasta = "${projectDir}/reference/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz"

process kb_build_index {
    label params.aligner
    label "mid_memory"
    publishDir params.kb_ref_files, mode: "copy"
    
    input:
        path fasta 
        path gtf 
    
    output:
        file "index.idx" 
        file "t2g.txt"

    script:
    """
    kb ref --tmp ${params.tmpdir} --verbose --workflow standard -i index.idx -g t2g.txt -f1 cDNA.fa ${fasta} ${gtf}
    """
}

process kb_download_ref {
    label params.aligner
    label "low_memory"
    publishDir params.kb_ref_files, mode: "copy"

    output:
	file "index.idx" 
	file "t2g.txt" 

    script:
    """
    kb ref --tmp ${params.tmpdir} --verbose --workflow standard -d ${params.species} -i index.idx -g t2g.txt
    """
}

process kb_count {
    label params.aligner
    label "high_memory"
    tag "${params.tech}"
    publishDir params.outdir, mode: "copy"

    input:
        file reads 
        file index 
        file t2g 

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

Channel
    .fromPath( params.input )
    .ifEmpty { exit 1, "Cannot find any reads matching: ${params.input}\nNB: Path needs to be enclosed in quotes!\n\NB: Path requires at least one * wildcard!\n" }
    .set(read_fastq_inputs)

workflow {
    if ( params.aligner == "kb" ) {
        if ( !params.kb_prebuilt && !( params.gtf && params.fasta )) {
            kb_download_ref()
        }
        else {
            kb_build_index(params.fasta,params.gtf)
        }
    }

    else {
        echo "Still building other pipelines"
        }
}