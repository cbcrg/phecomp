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
mtb_path = mtb_path = "${params.base_dir}${params.mtb_dir}${params.in_file_pattern}"

println "path: $mtb_path"

//mtb_files = Channel.fromPath(mtb_path)

//aryMtbFilesDev=( $( ls ${mtbFilesDir}20120*.mtb | grep -v "LAHFD" | grep -v "LASC" | grep -v "LA_to_food" | grep -v "adulteration" | grep -v "quinine" | grep -v "LA" | grep -v "/20120502_FDF_CRG/20120502_FDF_CRG/2012071" ) )
Channel.fromPath (mtb_path)
//    .grep ( ~/.*(?v)c12.*/ )
//    .filter ( ~/.*c12.*/ ) 
    .filter { def matcher = it =~/.*LAHFD.*/; !matcher.matches() }
    .filter { def matcher = it =~/.*LASC.*/; !matcher.matches() }
    .filter { def matcher = it =~/.*LA_to_food.*/; !matcher.matches() }
    .filter { def matcher = it =~/.*adulteration.*/; !matcher.matches() }
    .filter { def matcher = it =~/.*LA.*/; !matcher.matches() }
    .filter { def matcher = it =~/.*quinine.*/; !matcher.matches() }
    .filter { def matcher = it =~/.*2012071.*/; !matcher.matches() }
    .subscribe { println it }
