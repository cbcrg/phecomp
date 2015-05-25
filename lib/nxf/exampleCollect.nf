println ([1,2,3] .collect { it * it })


Channel
    .from('alpha', 'beta', 'gamma')
    .collectFile(name: 'sample.txt', newLine: true)
    .subscribe {
        println "Entries are saved to file: $it"
        println "File content is: ${it.text}"
    }