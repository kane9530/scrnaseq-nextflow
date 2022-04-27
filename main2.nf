#!/usr/bin/env nextflow
////////////////////////////////////////////////////
/*
 * Configuration parameters
*/
 ////////////////////////////////////////////////////
// If kb-aligner used and user specifies that indices have been prebuilt, check if index AND t2g files are supplied

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

////////////////////////////////////////////////////
/*
 * Run kb-python pipeline
 */ 
 ////////////////////////////////////////////////////

include { kb_count } from './modules/kb-python/count'
include { kb_build_index } from './modules/kb-python/build_index'

params.tech = params.type + params.chemistry
fastq_input = Channel.fromPath(params.input) | collect

workflow {
    kb_build_index(params.fasta, params.gtf)
    kb_count(fastq_input, 
             kb_build_index.out.index_file,
             kb_build_index.out.t2g_file)
}