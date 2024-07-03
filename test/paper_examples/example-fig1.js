function git_reset (config, op, branch_name, url) {
    const options = config[op]
    options[branch_name] = url
    options.cmd = "git reset"
    
    exec(`${options.cmd} HEAD~${options.commit}`)
}