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
params.in_file_pattern = "*.mtb"
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
    file f_mtb from mtb_files
 
    output:
//    set file('*.int'), stdout into int_files
//    set file('*.int'), stdout into int_files2
    set file('*.int'), stdout, file('ini_name8.txt') into int_files
    set file('*.int'), stdout, file('ini_name8.txt') into int_files2
//    set stdout into name 

    script:
    println "Input name is $f_mtb.name"
    //Command example: mtb2int.pl $mtbFiles -startTime file tac -out > ${intFile} 2> ${intFile}.err
    
    """ 
    mtb2int.pl ${f_mtb} -startTime file tac -rename cages Y -out > ${f_mtb}.int 2> ${f_mtb}.err
    name_file=${f_mtb}
    ini_name="\${name_file:0:19}"
    printf "\$ini_name" > /dev/stdout 
    ini_name8="\${name_file:0:8}" 
    printf \$ini_name8 > ini_name8.txt
    """
}    

//printf "\$ini_name" > /dev/stdout
//printf "\$ini_name_8" > ini_name_8
    
process filter_int {
    input:
    set file('f_int'), val(ini_n), file(ini_name_8) from int_files
    
    output: 
    set file('*.csv') into int_files_filt   
    set file('*.csv') into int_files_filt2
    
    //Command example: 
    // int2combo.pl 20120509to0831_FCSC_UPF_HabDev.int -tag field Value max 0.02 -filter action rm -bin -out > 20120509to0831_FCSC_UPF_HabDevFilt.csv 
    // -tag field Value max 0.02 -filter action rm -out output R
    // adding output R to have a file readable for pergola NO, is better to separate by ; this way there is no problem with things like food 1
    // options will be: -tag field Value max 0.02 -filter action rm -bin -out output R
    
    // awk -F ";" '{OFS="\t"; print $1,$10,$13,$6,$15}' /Users/jespinosa/phecomp/data/CRG/20120502_FDF_CRG/results/f_int.csv > f_int.txt
    
    """
    int2combo.pl ${f_int} -tag field Value max 0.02 -filter action rm -bin -out > ${f_int}.txt
    cat ${f_int}.txt | grep "#d" | awk -F ";" '{OFS="\t"; print \$3,\$27,\$13,\$21,\$31}' >> ${f_int}.tmp
    
    if grep -q ""20120502"" "$ini_name_8"; then     
        awk '{ if (\$2 > 1335985200) print; }' ${f_int}.tmp >> ${ini_n}"_"${f_int}.csv 
    else    
        cat ${f_int}.tmp > ${ini_n}"_"${f_int}.csv
    fi
    """    
}

int_files_filt2
    .subscribe {
        println "Int file is: $it"
        it.copyTo( dump_dir.resolve ( it.name ) )
        
        }
/*      
process int_to_pergola {

    input:
    set file ('f_int_filt') from int_files_filt
    
    output:
    set file('*.int') into int_files
    
    """
    cat ${f_int} | grep "#d" > ${tac}.pos 
    """    
} 
*/
