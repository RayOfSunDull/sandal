import std/os
import std/strformat
import std/sets
import ./match

type
    FSObjectKind* = enum Dir, File

    FSObject* = ref object
        name*: string
        size: BiggestInt
        case kind*: FSObjectKind
        of Dir:
            contents*: seq[FSObject]
        of File:
            discard
    
    FSOperator* = object
        isFileNewer*:   proc(f1, f2: string): bool  {.closure.}
        makeDir*:       proc(dirPath: string)       {.closure.}
        copyFile*:      proc(src, dst: string)      {.closure.}

    FSImage* = object
        operator*: FSOperator
        content*: FSObject


func newFile*(name: string): FSObject =
    FSObject(name: name, kind: File)


func newDir*(name: string, contents: seq[FSObject]): FSObject =
    FSObject(name: name, kind: Dir, contents: contents)


proc print*(fso: FSObject, depth: string = "", printSize: bool = false) = 
    echo depth & fso.name & (
        if printSize: fmt" (size: {fso.size})"
        else: ""
    )

    case fso.kind:
    of File:
        discard
    of Dir:
        let deeper = depth & "  "

        for c in fso.contents:
            c.print(deeper, printSize)


proc newFSObject(
    localPath: string, 
    exclude: seq[match.Matcher],
    invalidPaths: var seq[string] = @[]
): (FSObject, MatchResult) =
    var matchResult = match.MatchResult(kind: NoMatch)

    for matcher in exclude:
        matchResult = matcher(localPath)

        case matchResult.kind
        of NoMatch:
            discard
        else:
            return (
                FSObject(name: "", size: 0, kind: File),
                matchResult
            )
    
    let info = getFileInfo(localPath)
    case info.kind
    of pcFile:
        return (
            FSObject(name: localPath, size: info.size, kind: File),
            matchResult
        )
    of pcDir:
        var contents: seq[FSObject] = @[]

        for kind, path in os.walkDir(localPath):
            # echo "owo", path
            let (fso, mr) = newFSObject(path, exclude, invalidPaths)

            case mr.kind
            of SimpleMatch:
                continue
            of ContentMatch:
                invalidPaths.add(mr.path)
                break
            of NoMatch:
                contents.add(fso)

        return (
            FSObject(
                name: localPath,
                size: info.size,
                kind: Dir,
                contents: contents    
            ),
            matchResult
        )
    else:
        echo "warning: links are not supported yet, skipping " & localPath


proc clearFSObject*(fso: var FSObject, invalidPaths: HashSet[string]) =
    case fso.kind:
    of File:
        discard
    of Dir:
        var newContents: seq[FSObject]
        for subFso in fso.contents:
            if subFso.name in invalidPaths:
                continue
            
            var subFso = subFso
            subFso.clearFSObject(invalidPaths)

            newContents.add(subFso)
        
        fso.contents = newContents


proc newFSImage*(
    operator: FSOperator, 
    base: string, 
    exclude: seq[match.Matcher]
): FSImage =
    var 
        invalidPaths: seq[string] = @[]
        (content, _) = newFSObject(base, exclude, invalidPaths)

    content.clearFSObject(sets.toHashSet(invalidPaths))

    return FSImage(
        operator: operator,
        content: content
    )

let localFSOperator* = FSOperator(
    isFileNewer: proc(f1, f2: string): bool =
        if not f2.fileExists():
            return true
        return f1.fileNewer(f2),
    makeDir: os.createDir,
    copyFile: proc(src,dst: string) = 
        os.copyFileWithPermissions(src,dst)
)


proc copyFSObject(
    fsop: FSOperator, fso: FSObject, 
    targetBase: string,
    verbose: bool = true,
    depth: string = ""
) =
    let targetPath = targetBase / fso.name.lastPathPart()

    case fso.kind
    of File:
        if fsop.isFileNewer(fso.name, targetPath):
            if verbose:
                echo fmt"{depth}{fso.name.lastPathPart()} ({float(fso.size) / 1000000.0} M)"

            fsop.copyFile(fso.name, targetPath)
    of Dir:
        fsop.makeDir(targetPath)

        if verbose:
            echo fmt"{depth}{fso.name.lastPathPart()}"

        for subFso in fso.contents:
            fsop.copyFSObject(subFso, targetPath, depth = depth & "  ")


proc syncWith*(fsi: FSImage, targetBase: string) =
    echo fmt"copying {fsi.content.name}" & "\n" & fmt"to {targetBase}"
    fsi.operator.copyFSObject(fsi.content, targetBase)