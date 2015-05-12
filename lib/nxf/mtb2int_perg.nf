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
    cat ${f_int}.txt | grep "#d" | grep "food" | awk -F ";" '{OFS="\t"; print \$3,\$27,\$13,\$21,\$31}' >> ${f_int}.tmp
    
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
    set file('tr*.bed') into bed_by_tr
    set file('tr*.bed') into bed_by_tr2
    set file('tr*.bed') into bed_by_tr3
//    set file('all_mice.chromsizes') into chromsizes
    
    """
    pergola_rules.py -i $f_csv -o $correspondence_f -f bed -nh -s 'cage' 'start_time' 'end_time' 'nature' 'value' -e -d all
    # tail -1 $f_csv | awk '{OFS="\t"; print "chr1", \$3-1335985200}' > all_mice.chromsizes
    """    
} 

//bed_by_tr3.subscribe { println it }
/*
 * Join all bed files to get last interval for chromsize file
 */
 
def file_bed_to_chrom = bed_by_tr2
                            .reduce ([]) { all, content -> all << content.text }
                            .map { it.join('') }                        

process get_chrom_sizes {
    input:
    set file ('bed_join') from file_bed_to_chrom
    
    output:
    set file ('all_mice.chromsizes') into chromsizes
    
    """
    tail -n+2 ${bed_join} | sort -k1,1 -k2,2g > bed_join_sort
    tail -1 bed_join_sort | awk '{OFS="\t"; print "chr1", \$3}' > all_mice.chromsizes
    """
}
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
 * Join all date files into a single one - Generate recordings bed file
 */

def file_date_joined = file_date
                        .reduce ([]) { all, content -> all << content.text }
                        .map { it.join('') }

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

bed_by_tr3_flat =  bed_by_tr3.flatten()
bed_by_tr_flat =  bed_by_tr.flatten()

bed_by_tr3_flat.subscribe {
        println "Contains bed file for tr: $it"
        
    }

/* //del
process test {
    input:
    file 'bed_by_tr_f' from bed_by_tr4
   
    output:
    set file('foo') into bed_recordings
    
    script:
    
    println ( "++++++++++++++++++$bed_by_tr_f" )
    
    """
    cat ${bed_by_tr_f} > foo
    """
    }
*/   
process bedtools_down_stream {
    input:
    set file ('bed_by_tr_f') from bed_by_tr_flat
    file ('chromsizes_f') from chromsizes.first()
    file ('bed_record') from bed_recordings.first()
//    file ('light_phases') from light_phases.first()
    
    output:
    set file('*24h*') into bed_recordings
//    set file ('24h_less_mean.bed'
    script:
    println ( "Contains bed file for tr: $bed_by_tr_f" )
    
    // Command example
    //bedtools complement -i ${path2files}files_data.bed -g ${path2files}all_mice.chromsizes > ${path2files}files_data_comp.bed
    
    //awk '{OFS="\t"; print $1,$2,$3,"\"\"",1000,"+",$2,$3}' ${path2files}files_data_comp.bed > ${path2files}files_data_comp_all_fields.bed

    """    
    complementBed -i ${bed_record} -g ${chromsizes_f} > file.comp
    awk '{OFS="\t"; print \$1,\$2,\$3,"\"\"",1000,"+",\$2,\$3}' file.comp > file_comp.bed
    
    time_after_clean=1800
    t_day_s=86400
    t_24h_and_30min=\$(( t_day_s + time_after_clean ))
    
    flankBed -i file_comp.bed -g ${chromsizes_f} -l 0 -r \$time_after_clean  -s > 30_min_after_clean
    flankBed -i 30_min_after_clean -g ${chromsizes_f} -l 0 -r \$t_24h_and_30min > 24h_30_min_after_clean.tmp
    
    # Last period does not exists because is out of the recording
    sed '\$d' 24h_30_min_after_clean.tmp > 24h_30_min_after_clean
        
    t_l_23h_30min=\$(( t_day_s - time_after_clean ))   
    
    flankBed -i 30_min_after_clean -g ${chromsizes_f} -l \${t_l_23h_30min} -r 0 > 23h30min_before_clean
    flankBed -i 23h30min_before_clean -g ${chromsizes_f} -l \$time_after_clean -r 0 > 24h_30_min_before_clean
    
    
    createBedFilesAnalyze () {
        track=\$1
        track2map=\$2
        tag=\$3
        
        
        
        # Get raw bed files with overlaping regions of target files
        intersectBed -a \${track} -b \${track2map} > \${tag}raw.bed
        
        # Get the coverage of the overlaping regions
        coverageBed -a \${track} -b \${track2map} | sort -k1,1 -k2,2n > \${tag}cov.bed
        
        # Get the mean of the overlaping regions
        mapBed -a \${track2map} -b \${track} -c 5 -o mean -null 0 > \${tag}mean.bed
        
        # Get the summatory of the overlaping regions
        mapBed -a \${track2map} -b \${track} -c 5 -o sum -null 0 > \${tag}sum.bed
        
        # Get the counts of the overlaping regions
        mapBed -a \${track2map} -b \${track} -c 5 -o count -null 0 > \${tag}count.bed
        
        # Get the maximum of the overlaping regions
        mapBed -a \${track2map} -b \${track} -c 5 -o max -null 0 > \${tag}max.bed
    }
    
    half="30min_"
    day="24h_"
    day_before="24h_less_"
    
    createBedFilesAnalyze ${bed_by_tr_f} 30_min_after_clean \$half
    createBedFilesAnalyze ${bed_by_tr_f} 24h_30_min_after_clean \$day
    createBedFilesAnalyze ${bed_by_tr_f} 23h30min_before_clean \$day_before
    
    touch foo
    """
}

bed_recordings
    .subscribe { println "it---------------$it"}




/*


    
    
    
    
    
    
    
    
    
 
    
    half="_30min"
    day="_24h"
    day_before="_24h_less"
    
    

createBedFilesAnalyze ${bed_by_tr} 30_min_after_clean \$half
createBedFilesAnalyze ${bed_by_tr} 24h_30_min_after_clean \$day
createBedFilesAnalyze ${bed_by_tr} createBedFilesAnalyze \$day_before









# out_name=`echo \$track | cut -d . -f1`
        #filename=\$(basename "$track")
        #filename="\${filename%.*}"
        #echo -e "Generated file is \${filename}\${tag}.bed"







## UPSTREAM, BEFORE THE CLEAN

flankBed -i file_comp.bed -g ${chromsizes_f} -l 0 -r \$time_after_clean  -s > 30_min_after_clean
    flankBed -i 30_min_after_clean -g ${chromsizes_f} -l 0 -r \$t_24h_and_30min > 24h_30_min_after_clean
        t_l_23h_30min=\$(( t_day_s - time_after_clean ))
complementBed -i 30_min_after_clean -g ${chromsizes_f} -l \$t_l_23h_30min -r 0 > 23h30min_before_clean
    flankBed -i 23h30min_before_clean -g ${chromsizes_f} -l \$time_after_clean -r 0 > 24h_before_clean


awk '{OFS="\t"; print $1,$2,$3,"\"\"",1000,"+",$2,$3}' ${bed_record}.comp > file_comp.bed
    
time_after_clean=1800
time_after_clean_lab="30min"

t_day_s=86400
t_day_s_lab="24h"
t_24h_and_30min=$(( t_day_s + time_after_clean ))
    
bedFlank -i file_comp.bed -g ${chromsizes_f} -l 0 -r \$time_after_clean  -s > 30_min_after_clean

bedFlank -i 30_min_after_clean -g ${chromsizes_f} -l 0 -r \$t_24h_and_30min > 24h_30_min_after_clean
    
## UPSTREAM, BEFORE THE CLEAN
t_l_23h_30min=$(( t_day_s - time_after_clean ))
    
bedtools flank -i 30_min_after_clean -g ${chromsizes_f} -l \$t_l_23h_30min -r 0 > 23h30min_before_clean
bedtools flank -i 23h30min_before_clean -g ${chromsizes_f} -l \$time_after_clean -r 0 > 24h_before_clean
*/