/*
#################################################################################
### Jose Espinosa-Carrasco. CB/CSN-CRG. May 2015                              ### 
#################################################################################
### Code : 11.05                                                              ###
### Processing mtb files one  by one using nextflow                           ### 
### ./nextflow foo.nxf --foo '*.tac'                           ###
#################################################################################
*/

params.base_dir = "/Users/jespinosa/"
params.mtb_dir = "phecomp/data/CRG/20120502_FDF_CRG/"
params.in_file_pattern = "*c6.mtb"
mtb_path = "${params.base_dir}${params.mtb_dir}${params.in_file_pattern}"

println "path: $mtb_path"
mtb_files = Channel.fromPath(mtb_path)

/* 
 * Creating results folder
 */
println "path: ${params.base_dir}${params.mtb_dir}results/"
dump_dir = file("${params.base_dir}${params.mtb_dir}results/")

dump_dir.with {
     if( !empty() ) { deleteDir() }
     mkdirs()
     println "Created: $dump_dir"
}

//## Ary with habituation and development files for paper
//aryMtbFilesDev=( $( ls ${mtbFilesDir}20120*.mtb | grep -v "LAHFD" | grep -v "LASC" | grep -v "LA_to_food" | grep -v "adulteration" | grep -v "quinine" | grep -v "LA" | grep -v "/20120502_FDF_CRG/20120502_FDF_CRG/2012071" ) )

process mtb_to_int {

    input:
    set file ('f_mtb') from mtb_files
    
    output:
    set file('*.int') into int_files
    
    //Command example: mtb2int.pl $mtbFiles -startTime file tac -out > ${intFile} 2> ${intFile}.err
    
    """ 
    mtb2int.pl ${f_mtb} -startTime file tac -out > ${f_mtb}.int 2> ${f_mtb}.err
    """

}

int_files
    .subscribe {
        println "Int file is: $it"
        
        } 
