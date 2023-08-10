import ../modules/args
import ../modules/cfg
import ../modules/fs
import ../modules/match


let 
    arguments = args.getArgs()
    config = cfg.getConfig(arguments.configPath)

var exclude: seq[match.Matcher]

for excludePattern in config.exclude:
    exclude.add(match.newMatcher(excludePattern))

if arguments.args.len < 2:
    raise newException(
        ValueError, 
        "you need to provide an input and an output directory"
    )

let
    input = arguments.args[0]
    output = arguments.args[1]

    fsi = fs.newFSImage(
        fs.localFSOperator,
        input,
        exclude
    )


fsi.syncWith(output)