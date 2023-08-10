import os
import std/parseopt

type Args* = object
    configPath*: string
    args*: seq[string]


proc getArgs*(): Args =
    var args: Args

    var parser = initOptParser()

    while true:
        parser.next()
        case parser.kind
        of cmdEnd:
            break
        of cmdShortOption, cmdLongOption:
            if parser.key == "config" or parser.key == "c":
                if parser.val == "":
                    args.configPath = os.getCurrentDir() / "sandal.json"
                elif os.isAbsolute(parser.val):
                    args.configPath = parser.val
                else:
                    args.configPath = os.getCurrentDir() / parser.val
        of cmdArgument:
            args.args.add(parser.key)
    
    return args