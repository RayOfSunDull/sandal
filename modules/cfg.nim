import std/json

type Config* = object
    exclude*: seq[string]


proc getConfig*(path: string): Config =
    if path == "":
        return Config(
            exclude: @[]
        )
        
    let data = json.parseJson(readFile(path))

    return data.to(Config)