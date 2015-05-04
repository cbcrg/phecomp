/*
#################################################################################
### Jose Espinosa-Carrasco. CB/CSN-CRG. May 2015                              ### 
#################################################################################
### Code : 05.04.01                                                           ###
### Obtaining bed files from pos files                                        ### 
### ./nextflow tac2activity.nxf --tac_files '*.tac'                           ###
#################################################################################
*/

params.pos_f_path = "$HOME/phecomp/processedData/201205_FDF_CRG/tac2activity/"

pos_files_path = "${params.pos_f_path}*.pos"


println "path: $pos_files_path"

pos_files = Channel.fromPath(pos_files_path)


correspondence_f_path = "$HOME/git/pergola/test/position2pergola.txt"
correspondence_f = file(correspondence_f_path)

// Correspondence file for bedGraph files
correspondence_f_bG_path = "$HOME/git/pergola/test/bedGraph2pergola.txt"
correspondence_f_bG = file(correspondence_f_bG_path)

correspondence_f_bG_tr_path = "$HOME/git/pergola/test/bedGraphWithTr2pergola.txt"
correspondence_f_bG_tr = file(correspondence_f_bG_tr_path)

/* 
 * Creating results folder
 */
dump_dir_bed = file("$HOME/phecomp/processedData/201205_FDF_CRG/tac2activity/bed/")

dump_dir_bed.with {
     if( !empty() ) { deleteDir() }
     mkdirs()
     println "Created: $dump_dir_bed"
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
    
    script:
    println ("***********${f_pos}")
    
    """ 
    pergola_rules.py -i $f_pos -o $correspondence_f -fs ";" -n -f bed -nt
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
