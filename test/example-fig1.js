function exec (cmd) {}
// function params
let config = {}
let op = {}
let branch_name = {}
let url = {}

const options = config[op]
options[branch_name] = url
options.cmd = "git reset"

exec(`${options.cmd} HEAD~${options.commit}`)