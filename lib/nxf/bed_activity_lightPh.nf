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

correspondence_f_path = "$HOME/git/pergola/test/position2pergola.txt"
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
 
 script:
 println "Input name is $tac.name"
   
 """
 ${path_tac2pos}new_tac2pos -file $tac -action position > ${tac}.pos
 """
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
    set file('phases_light.bed') into light_phases 
    script:
    println ("***********${f_pos}")
    
    """ 
    pergola_rules.py -i $f_pos -o $correspondence_f -fs ";" -n -f bed -nt -e
    """
}

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
def bed_by_track = Channel.create()
def bed_by_track_to_w = Channel.create()
bed_by_track_1.into(bed_by_track, bed_by_track_to_w) 

bed_by_track_to_w.subscribe  {  
        println "Writing: ${it[1]}_pos_filt.bed"
        it[0].copyTo( dump_dir_bed.resolve ( "tr_${it[1]}_pos_filt.bed" ) )
    }

/*
 * Bedtools intersect light phases with bed activity files
 */
process intersect_light_activity {
    input: 
    set file ('bed_tr'), val (tr) from bed_by_track
    set file ('light_phases') from light_phases 
    
    output:
    set val(), file('tr*.bed') into bed
    
    //Example command
    // bedtools intersect -a ${filename}_compl.bed -b ${path2files}exp_phases_hab.bed > ${filename}"_compl_hab.bed"
    """
    cat $bed_tr | sort -k1,1 -k2,2n > ${bed_tr}_sorted.bed
    bedtools intersect -a ${bed_tr}_sorted.bed -b $light_phases > tr_${tr}_light.int
    """
    
} 