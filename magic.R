cmds <- commandArgs()

cmdLen <- length(cmds)

if (cmds[cmdLen] == "small"){
    small <- TRUE
} else {
    small <- FALSE
}
