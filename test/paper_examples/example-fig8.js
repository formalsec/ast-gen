function setValue (obj, dotPath, value) {
    const path = dotPath.path + {}
    for (let i = 0; i < path.length; i++) {
        const key = path[i]
        if (i == path.length - 1) {
            obj[key] = value
        }
        obj = obj[key]
    }
}