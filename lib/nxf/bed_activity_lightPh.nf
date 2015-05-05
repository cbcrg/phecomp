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

   