const dependencyTree = require("dependency-tree"); 
const path = require("path"); 

function generate_dt (filename) {
    const tree = dependencyTree({ 
        filename: filename, 
        directory: path.dirname(filename) 
    })

    console.log(JSON.stringify(tree))
}

let filename = process.argv[2]
generate_dt (filename)
module.exports = {generate_dt}
