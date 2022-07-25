process PROTEINQUANTIFIER {
    tag "${pro_quant_exp.baseName}"
    label 'process_medium'

    conda (params.enable_conda ? "openms::openms=3.0.0dev" : null)
    container "${ workflow.containerEngine == 'docker' && !task.ext.singularity_pull_docker_container ?
        'ghcr.io/openms/openms-executables:latest' :
        'https://ftp.pride.ebi.ac.uk/pride/resources/tools/ghcr.io-openms-openms-executables-latest.img'
        }"

    input:
    path epi_filt_resolve
    path pro_quant_exp

    output:
    path "*protein_openms.csv", emit: protein_out
    path "*peptide_openms.csv", emit: peptide_out
    path "*.mzTab", emit: out_mztab optional true
    path "*.log"
    path "versions.yml", emit: version

    script:
    def args = task.ext.args ?: ''

    include_all = params.include_all ? "-include_all" : ""
    fix_peptides = params.fix_peptides ? "-fix_peptides" : ""
    normalize = params.normalize ? "-consensus:normalize" : ""
    export_mztab = params.export_mztab ? "-mztab ${pro_quant_exp.baseName}_openms.mzTab" : ""

    """
    ProteinQuantifier \\
        -method 'top' \\
        -in ${epi_filt_resolve} \\
        -design ${pro_quant_exp} \\
        -out ${pro_quant_exp.baseName}_protein_openms.csv \\
        ${export_mztab} \\
        -peptide_out ${pro_quant_exp.baseName}_peptide_openms.csv \\
        -top $params.top \\
        -aggregate $params.average \\
        ${include_all} \\
        ${fix_peptides} \\
        -ratios \\
        -threads $task.cpus \\
        ${normalize} \\
        $args \\
        |& tee pro_quant.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ProteinQuantifier: \$(ProteinQuantifier 2>&1 | grep -E '^Version(.*)' | sed 's/Version: //g')
    END_VERSIONS
    """
}
