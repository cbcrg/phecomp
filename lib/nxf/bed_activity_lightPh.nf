/*
#################################################################################
### Jose Espinosa-Carrasco. CB/CSN-CRG. May 2015                              ### 
#################################################################################
### Code : 05.04.01                                                           ###
### Obtaining bed files from pos files                                        ### 
### ./nextflow tac2activity.nxf --tac_files '*.tac'                           ###
#################################################################################
*/

params.tac_files = "/phecomp/data/CRG/20120502_FDF_CRG/20120502_FDF_CRG/test/*.tac"

tac_files_path = "$HOME/${params.tac_files}"

println "path: $tac_files_path"

tac_files = Channel.fromPath(tac_files_path)

path_tac2pos = "$HOME/git/phecomp/lib/c/"

//correspondence_f_path = "$HOME/git/pergola/test/position2pergola.txt"
correspondence_f_path = "$HOME/git/pergola/test/pos_short2pergola.txt"
correspondence_f = file(correspondence_f_path)

/* 
 * Creating results folder
 */
dump_dir_bed = file("$HOME/phecomp/processedData/201205_FDF_CRG/tac2activity/bed/")

dump_dir_bed.with {
     if( !empty() ) { deleteDir() }
     mkdirs()
     println "Created: $dump_dir_bed"
}

/*
 * Extract postion from tac files
 */
process extractPosition {
 
 input:
 file tac from tac_files
 
 output:
 file '*.pos' into pos_files
 file '*.pos' into pos_files1
 file 'min_max.txt' into min_max
     
 script:
 println "Input name is $tac.name"
   
 """
 ${path_tac2pos}new_tac2pos -file $tac -action position > ${tac}.txt
 cat ${tac}.txt | head -1 | awk -F ";" '{OFS=";"; print \$1,\$3,\$7,"TimeEnd"}'> ${tac}.pos
 tail -n +2 ${tac}.txt | awk -F ";" '{OFS=";"; print \$1,\$3,\$7,\$3+1}' >> tmp.txt
 
 name_file=${tac}.txt
 ini_name="\${name_file:0:8}" 
 
 if [[ "\${ini_name}" = "20120502" ]] ; then
     tail -n +2 tmp.txt | awk -F ";" '{ if (\$3 != 0) print; }' >> tmp_short.txt
     awk -F  ";" '{ if (\$2 > 1335985200) print; }' tmp_short.txt >> ${tac}.pos
 else
     tail -n +2 tmp.txt | awk -F ";" '{ if (\$3 != 0) print; }' >> ${tac}.pos
     echo -e "No changes in this files\\n"
 fi     

tail -n +2 ${tac}.pos | awk -F ";"  'BEGIN{OFS=";";} { if (min=="") { min=max=\$2 }; if(\$2>max){ max=\$2 }; if(\$2< min) { min=\$2 }; total+=\$2; count+=1 } END { print "1",min,"0",max }' >> min_max.txt    
"""
}

/*      
min_max
    .collectFile(name: 'sample.txt')
    .splitCsv(header: ['Cage', 'Time', 'EucDistance', 'TimeEnd'], skip: 0 ) 
    .subscribe { it ->
        println "Entries are saved to file: $it"
        it.copyTo( dump_dir_bed.resolve ( "file.txt" ) )
//        println "File content is: ${it.text}"
    }
*/

process join_min_max {

    input:
    file min_max from min_max
    
    output:
    file 'min_max.bed' into min_max_bed
    
    """
    cat $min_max >> min_max.bed
    """ 
}


mix_max_joined = min_max_bed
    .collectFile(name: 'sample.txt')
    


process get_phases {
    input:
    file min_max from mix_max_joined
 
    output:
    set file('phases_light_inverted.bed') into light_phases
    set file('phases_dark_inverted.bed') into dark_phases
    
    """ 
    pergola_rules.py -i $min_max -o $correspondence_f -fs ";" -f bed -nh -s 'Cage' 'Time' 'EucDistance' 'TimeEnd' -e
    sed 's/dark/light/' phases_dark.bed > phases_light_inverted.bed
    sed 's/light/dark/' phases_light.bed > phases_dark_inverted.bed   
    """ 
    }

/*
 * Writing the files in the stdout to see how it looks like
 */
/*
light_phases
 .subscribe {
        println "Entries are saved to file: $it"
        println "File content is: ${it.text}"
    }

dark_phases
 .subscribe {
        println "Entries are saved to file: $it"
        println "File content is: ${it.text}"
    }
*/

/*
 * Writing position file
 */ 
/*
pos_files1
    .subscribe {
        println "Copying pos file: $it"
        it.copyTo( dump_dir_bed.resolve ( it.name ) )
    }
*/

// I need to now from which pos files the tr files have being generated
// otherwise tr_1 from pos-2 will overwrite tr_1 from pos_1
pos_files_flat = pos_files.flatten().map { single_pos_file ->   
   def name = single_pos_file.name
   def content = single_pos_file
   [ name,  content ]
}

/* Generate a bed from each position file
 * Files were already filtered for activities equal to zero
 */
process pos_to_bed {
    
    input: 
    set val (f_pos_name), file ('f_pos') from pos_files_flat
    
    output:
    // I only collect tracks not phases
    set val(f_pos_name), file('tr*.bed') into bed
    set val(f_pos_name), file('tr*.bed') into bed_write
    
    script:
    println ("***********${f_pos}")
    
    """ 
    pergola_rules.py -i $f_pos -o $correspondence_f -fs ";" -f bed -nt -e
    """
}


//Working correctly until here







//bed.println() //del

/*
 * Writing bed files del
 */

/* 
bed_write 
    .subscribe { pos_file, bed_files ->   
        for ( it in bed_files ) {
            it.copyTo( dump_dir_bed.resolve ( "${pos_file}${it.name}" ) )
            }  
    }
*/
    
// Collects here just get after flatting the correspondece bw
// position and bed files 
// pos1; tr_1.bed
// pos1; tr_2.bed...

bed_tr = bed.map {pos_file, bed_files ->
        bed_files .collect {
            def pattern = it.name =~/^tr_(\d+).*$/
            def track = pattern[0][1]

            [ pos_file, track,  it ]
        }
    }
    .flatMap()
    
/*
 * I collect all files belonging to the same track 
 */ 
bed_by_track_1 = bed_tr    
    .collectFile { pos, track, file -> 
       [ "bed_$track", file ]
    }
   .flatMap() 
   .map { file -> tuple( file, file.baseName.tokenize('_')[1]) }
//   .println()

/*
 * Duplicating the channel, to write the file and to continue with bedtools
 */
def bed_by_track_l = Channel.create()
def bed_by_track_d = Channel.create()
//def bed_by_track_to_w = Channel.create()
bed_by_track_1.into(bed_by_track_l, bed_by_track_d) 

/*
bed_by_track_to_w.subscribe  {  
        println "Writing: ${it[1]}_pos_filt.bed"
        it[0].copyTo( dump_dir_bed.resolve ( "tr_${it[1]}_pos_filt.bed" ) )
    }
*/ // ahora esto no existe el bed_by_track_to_w

/*
 * Bedtools intersect light phases with bed activity files
 */ 

//bed_by_track_l
//    .println()

  
process intersect_light_activity {
    input: 
    set file ('bed_tr'), val (tr) from bed_by_track_l
    file ('light_phases') from light_phases.first()
    file ('dark_phases')  from dark_phases.first()
    
    output:
    set val(tr), file('*_light.int') into bed_light_activity
    set val(tr), file('*_light.int') into bed_light_activity_to_w
    set val(tr), file('*_dark.int') into bed_dark_activity
    set val(tr), file('*_dark.int') into bed_dark_activity_to_w
    
    //Example command
    // bedtools intersect -a ${filename}_compl.bed -b ${path2files}exp_phases_hab.bed > ${filename}"_compl_hab.bed"
    script:
    println( "-------------$tr")
    """
    cat $bed_tr | sort -k1,1 -k2,2n > ${bed_tr}_sorted.bed
    bedtools intersect -a ${bed_tr}_sorted.bed -b ${light_phases} > tr_${tr}_light.int
    bedtools intersect -a ${bed_tr}_sorted.bed -b ${dark_phases} > tr_${tr}_dark.int
    """    
} 

//bed_light_activity_to_w
//    .println()

bed_light_activity.subscribe  {  
        println "Writing: ${it[0]}_light_intersect.bed"
        it[1].copyTo( dump_dir_bed.resolve ( "tr_${it[0]}_light_intersect.bed" ) )
    }

bed_dark_activity.subscribe  {  
        println "Writing: ${it[0]}_dark_intersect.bed"
        it[1].copyTo( dump_dir_bed.resolve ( "tr_${it[0]}_dark_intersect.bed" ) )
    }

/*
bed_by_track_l
    .println()
bed_by_track_d
    .println()
*/

/*    
process intersect_dark_activity {
    input: 
    set file ('bed_tr'), val (tr) from bed_by_track_d
    file ('dark_phases') from dark_phases.first()
    
    output:
    set val(tr), file('*_dark.int') into bed_dark_activity
    set val(tr), file('*_dark.int') into bed_dark_activity_to_w
    
    //Example command
    // bedtools intersect -a ${filename}_compl.bed -b ${path2files}exp_phases_hab.bed > ${filename}"_compl_hab.bed"
    script:
    println( "-------------$tr")
    
    """
    cat $bed_tr | sort -k1,1 -k2,2n > ${bed_tr}_sorted.bed
    bedtools intersect -a ${bed_tr}_sorted.bed -b ${dark_phases} > tr_${tr}_dark.int
    """    
} 

bed_dark_activity.subscribe  {  
        println "Writing: ${it[0]}_dark_intersect.bed"
        it[1].copyTo( dump_dir_bed.resolve ( "tr_${it[0]}_dark_intersect.bed" ) )
    }
*/
