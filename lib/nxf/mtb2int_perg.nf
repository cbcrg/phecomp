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
correspondence_f_path = "${params.base_dir}git/pergola/test/int_short2pergola.txt"
correspondence_f = file(correspondence_f_path)

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
    set file('file.date') into file_date
    
    //Command example: 
    // int2combo.pl 20120509to0831_FCSC_UPF_HabDev.int -tag field Value max 0.02 -filter action rm -bin -out > 20120509to0831_FCSC_UPF_HabDevFilt.csv 
    // -tag field Value max 0.02 -filter action rm -out output R
    // adding output R to have a file readable for pergola NO, is better to separate by ; this way there is no problem with things like food 1
    // options will be: -tag field Value max 0.02 -filter action rm -bin -out output R
    
    // awk -F ";" '{OFS="\t"; print $1,$10,$13,$6,$15}' /Users/jespinosa/phecomp/data/CRG/20120502_FDF_CRG/results/f_int.csv > f_int.txt
    
    """
    int2combo.pl ${f_int} -tag field Value max 0.02 -filter action rm -bin -out > ${f_int}.txt
    cat ${f_int}.txt | grep "#d" | awk -F ";" '{OFS="\t"; print \$3,\$27,\$13,\$21,\$31}' >> ${f_int}.tmp
    
    if grep -q "20120502" "$ini_name_8"; then     
        awk '{ if (\$2 > 1335985200) print; }' ${f_int}.tmp >> ${ini_n}"_"${f_int}.csv 
    else    
        cat ${f_int}.tmp > ${ini_n}"_"${f_int}.csv
    fi
    
    if [[ "${ini_n}" == *"c1"* ]]; then
        awk '{ if (min=="") { min=\$2; max=\$3 }; if(\$3>max){ max=\$3 }; if(\$2< min) { min=\$2 } } END {OFS="\t"; print 1, min, max, "record", 1000 }' ${ini_n}"_"${f_int}.csv >> file.date
    else
        printf "" >> file.date
    fi    
     
    """   
    //awk '{ if (min=="") { min=\$2; max=\$3 }; if(\$3>max){ max=\$3 }; if(\$2< min) { min=\$2 } } END {OFS="\t"; print "${ini_n}", min, max, "record", 1000 }' ${ini_n}"_"${f_int}.csv >> file.date 
}
//awk ?{if(min==?"){min=max=$1}; if($1>max) {max=$1}; if($1< min) {min=$1}; total+=$1; count+=1} END {print total/count, min, max}?
//head -1 ${ini_n}"_"${f_int}.csv >> file.date
//tail -1 ${ini_n}"_"${f_int}.csv >> file.date

/*
int_files_filt2
    .subscribe {
        println "Int file is: $it"
        it.copyTo( dump_dir.resolve ( it.name ) )
        
        }
        
file_date
    .subscribe {
        println "Int file is: $it"
        it.copyTo( dump_dir.resolve ( it.name ) )
        
        }
*/

/*
 * Join all csv files into a single one
 */

def int_files_joined = int_files_filt2
                        .reduce([]) { all, content -> all << content.text }
                        .map { it.join('') }

process int_to_pergola {

    input:
    set file ('f_csv') from int_files_joined
    
    output:
    set file('tr*.bed') into int_files
    
    """
    pergola_rules.py -i $f_csv -o $correspondence_f -f bed -nh -s 'cage' 'start_time' 'end_time' 'nature' 'value' -e
    """    
} 

/*
 * Join all date files into a single one
 */

def file_date_joined = file_date
                        .reduce ([]) { all, content -> all << content.text }
                        .map { it.join('') }
                        
/* 
file_date_joined                      
    .subscribe { println "----------- ${it}" }
*/

/*
file_date_joined                      
    .subscribe { //println "----------- ${it}" 
    it.copyTo( dump_dir.resolve ( "name.txt") )
    }
    
//                        it.copyTo( dump_dir.resolve () ) }
*/

                                                   


/*
 * 
 */

process recording_files_to_bed {
    input:
    set file ('file_date') from file_date_joined 
    
    output:
    set file('tr*.bed') into bed_recordings
    
    """
    pergola_rules.py -i $file_date -o $correspondence_f -f bed -nh -s 'cage' 'start_time' 'end_time' 'nature' 'value' -e -a join_all
    """    
}

/*
bed_recordings
    .subscribe { it.copyTo( dump_dir.resolve ( "file_recordings.bed") ) }
*/

