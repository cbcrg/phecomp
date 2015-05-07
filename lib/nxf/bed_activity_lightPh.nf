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

correspondence_f_path_bed = "$HOME/git/pergola/test/bed2pergola.txt"
correspondence_f_bed = file(correspondence_f_path_bed)

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
 file 'min_max.txt' into min_max1
      
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

def mix_max_joined = min_max
                        .reduce([]) { all, line -> all<<line.text }
                        .map { it.join('') }
                    
process get_phases {
    input:
    file min_max from mix_max_joined
 
    output:
    set file('phases_light_inverted.bed') into light_phases
    set file('phases_dark_inverted.bed') into dark_phases
    set file('phases_inverted.bed') into all_phases
    set file('phases_light_inverted.bed') into light_phases_p
    set file('phases_dark_inverted.bed') into dark_phases_p
    
    """ 
    pergola_rules.py -i $min_max -o $correspondence_f -fs ";" -f bed -nh -s 'Cage' 'Time' 'EucDistance' 'TimeEnd' -e
    sed 's/dark/light/g' phases_dark.bed > phases_light_inverted.bed
    sed 's/light/dark/g' phases_light.bed > phases_dark_inverted.bed
    sed 's/light/da1rk/g' phases.bed | sed 's/dark/light/g' | sed 's/da1rk/dark/g' > phases_inverted.bed
    
    """ 
    }

light_phases_p
    .subscribe {
        println "${it.text}"
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

pos_files1
    .subscribe {
        println "Copying pos file: $it"
        it.copyTo( dump_dir_bed.resolve ( it.name ) )
    }


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
    
    // Very important not to relative coordinates!!!!
    """ 
    pergola_rules.py -i $f_pos -o $correspondence_f -fs ";" -f bed -nt
    """
}

    
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
bed_by_track = bed_tr    
    .collectFile { pos, track, file ->
//       println ( "it------ $track") 
       [ "bed_$track", file ]
    }
   .flatMap() 
   .map { file -> tuple( file, file.baseName.tokenize('_')[1]) }


process bed_to_rel_coord {       

    input:
    set file ('bed_f'), val(tr) from bed_by_track
    
    output:
    set file ('tr*.bed'), val(tr) into bed_rel_coord
    
    """
    sed 's/chr1/${tr}/g' ${bed_f} > bed_tr
    pergola_rules.py -i bed_tr -o $correspondence_f_bed -f bed -nh -s 'chrm' 'start' 'end' 'nature' 'value' 'strain' 'start_rep' 'end_rep' 'color' -e 
    """ 
    
}

/*
 * Duplicating the channel, to write the file and to continue with bedtools
 */
def bed_by_track_l = Channel.create()
def bed_by_track_d = Channel.create()
def bed_by_track_a = Channel.create()
def bed_by_track_to_w = Channel.create()

bed_rel_coord.into (bed_by_track_l, bed_by_track_d, bed_by_track_a, bed_by_track_to_w) 

/*
 * Writing bed files for its display
 */
bed_by_track_to_w.subscribe  {  
        println "Writing: ${it[1]}_pos_filt.bed"
        it[0].copyTo( dump_dir_bed.resolve ( "tr_${it[1]}_pos_filt.bed" ) )
    }
    
/*
 * Bedtools intersect light phases with bed activity files
 */ 
process intersect_light_activity {
    input: 
    set file ('bed_tr'), val (tr) from bed_by_track_l
    file ('light_phases') from light_phases.first()
    
    output:
    set val(tr), file('*_light.bed') into bed_light_activity
    set val(tr), file('*_light.bed') into bed_light_activity_to_w
    set val(tr), file('*_light_sum.bed') into bed_light_activity_sum
    
    //Example command
    // bedtools intersect -a ${filename}_compl.bed -b ${path2files}exp_phases_hab.bed > ${filename}"_compl_hab.bed"
    script:
    println( "-------------$tr")
    
    """
    cat $bed_tr | sort -k1,1 -k2,2n > ${bed_tr}_sorted.tmp
    bedtools intersect -a ${bed_tr}_sorted.tmp -b ${light_phases} > tr_${tr}_light.bed
    # Get the summatory of activity during light phases
    mapBed -a ${light_phases} -b ${bed_tr}_sorted.tmp -c 5 -o sum -null 0 > tr_${tr}_light_sum.bed
    """    
} 

bed_light_activity.subscribe  {  
        println "Writing: ${it[0]}_light_intersect.bed"
        it[1].copyTo( dump_dir_bed.resolve ( "tr_${it[0]}_light_intersect.bed" ) )
    }

bed_light_activity_sum.subscribe  {  
        println "Writing: ${it[0]}_light_sum.bed"
        it[1].copyTo( dump_dir_bed.resolve ( "tr_${it[0]}_light_sum.bed" ) )
    }
    
/*
 * Bedtools intersect dark phases with bed activity files
 */    
process intersect_dark_activity {
    input: 
    set file ('bed_tr'), val (tr) from bed_by_track_d
    file ('dark_phases') from dark_phases.first()
    
    output:
    set val(tr), file('*_dark.bed') into bed_dark_activity
    set val(tr), file('*_dark.bed') into bed_dark_activity_to_w
    set val(tr), file('*_dark_sum.bed') into bed_dark_activity_sum
    
    //Example command
    // bedtools intersect -a ${filename}_compl.bed -b ${path2files}exp_phases_hab.bed > ${filename}"_compl_hab.bed"
    script:
//    println( "-------------$tr")
    
    """
    cat $bed_tr | sort -k1,1 -k2,2n > ${bed_tr}_sorted.tmp
    bedtools intersect -a ${bed_tr}_sorted.tmp -b ${dark_phases} > tr_${tr}_dark.bed
    # Get the summatory of activity during dark phases
    mapBed -a ${dark_phases} -b ${bed_tr}_sorted.tmp -c 5 -o sum -null 0 > tr_${tr}_dark_sum.bed
    """    
} 

bed_dark_activity.subscribe  {  
        println "Writing: ${it[0]}_dark_intersect.bed"
        it[1].copyTo( dump_dir_bed.resolve ( "tr_${it[0]}_dark_intersect.bed" ) )
    }

bed_dark_activity_sum.subscribe  {  
        println "Writing: ${it[0]}_dark_sum.bed"
        it[1].copyTo( dump_dir_bed.resolve ( "tr_${it[0]}_dark_sum.bed" ) )
    }

/*
 * Bedtools intersect dark AND light phases with bed activity files
 */    
process intersect_activity {
    input: 
    set file ('bed_tr'), val (tr) from bed_by_track_a
    file ('all_phases') from all_phases.first()
    
    output:
//    set val(tr), file('*_all.bed') into bed_activity
//    set val(tr), file('*_all.bed') into bed_activity_to_w
    set val(tr), file('*_all_sum.bed') into bed_activity_sum
    
    //Example command
    // bedtools intersect -a ${filename}_compl.bed -b ${path2files}exp_phases_hab.bed > ${filename}"_compl_hab.bed"
//    script:
//    println( "-------------$tr")
    
    """
    cat $bed_tr | sort -k1,1 -k2,2n > ${bed_tr}_sorted.tmp
    
    # Get the summatory of activity during dark phases
    mapBed -a ${all_phases} -b ${bed_tr}_sorted.tmp -c 5 -o sum -null 0 > tr_${tr}_all_sum.bed
    """    
} 

bed_activity_sum.subscribe  {  
        println "Writing: ${it[0]}_all_phases_sum.bed"
        it[1].copyTo( dump_dir_bed.resolve ( "tr_${it[0]}_all_phases_sum.bed" ) )
    }


    