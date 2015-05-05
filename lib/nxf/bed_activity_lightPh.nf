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
 file '*.pos' into pos_files1
     
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
     
 """
}



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

