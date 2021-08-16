#!/usr/bin/env nextflow
nextflow.preview.dsl=2

/*
========================================================================================
=                                 h3achipimputation                                    =
========================================================================================
 h3achipimputation imputation functions and processes.
----------------------------------------------------------------------------------------
 @Authors

----------------------------------------------------------------------------------------
 @Homepage / @Documentation
  https://github.com/h3abionet/chipimputation
----------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------
*/

// Show help message
if (params.help){
    helpMessage()
    exit 0
}

process phasing_eagle {
    tag "phase_${target_name}_${chrm}:${chunk_start}-${chunk_end}_${ref_name}_${tagName}"
    label "verylarge"
    input:
        tuple val(chrm), val(ref_name), file(ref_m3vcf), file(ref_vcf), file(ref_vcf_idx), file(ref_sample), file(eagle_genetic_map), val(chunk_start), val(chunk_end), val(target_name), val(tagName), file(target_vcf_chunk)
    output:
        tuple val(chrm), val(chunk_start), val(chunk_end), val(target_name), file("${file_out}.vcf.gz"), val(ref_name), file(ref_vcf), file(ref_m3vcf), val(tagName)
    script:
        file_out = "${file(target_vcf_chunk.baseName).baseName}_${ref_name}_phased"
        base = "${file(target_vcf_chunk.baseName).baseName}"
        """
        tabix ${target_vcf_chunk}
        eagle \
            --numThreads=${task.cpus} \
            --vcfTarget=${target_vcf_chunk} \
            --geneticMapFile=${eagle_genetic_map} \
            --vcfRef=${ref_vcf} \
            --vcfOutFormat=z \
            --noImpMissing \
            --chrom=${chrm} \
            --bpStart=${chunk_start} \
            --bpEnd=${chunk_end} \
            --bpFlanking=${params.buffer_size} \
            --outPrefix=${file_out} 2>&1 | tee ${file_out}.log
        """
}

process phasing_vcf_no_ref_chunk {
    tag "phase_${dataset}_${chrm}_${start}_${end}"
    // publishDir "${params.outdir}/${dataset}/vcfs_phased", overwrite: true, mode:'copy'
    label "bigmem10"

    input:
        tuple val(dataset), val(chrm), val(start), val(end), file(dataset_vcf), file(eagle_genetic_map)

    output:
        tuple val(dataset), val(chrm), val(start), val(end), file("${file_out}.vcf.gz")

    script:
        base = file(dataset_vcf.baseName).baseName
        file_out = "${base}_${chrm}_${start}_${end}_phased"
        """
        eagle \
            --numThreads=${task.cpus} \
            --vcf=${dataset_vcf} \
            --geneticMapFile=${eagle_genetic_map} \
            --vcfOutFormat=z \
            --chrom=${chrm} \
            --bpStart=${start} \
            --bpEnd=${end} \
            --outPrefix=${file_out} 2>&1 | tee ${file_out}.log
        tabix ${file_out}.vcf.gz
        """
}