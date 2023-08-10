import re
# import ./fs

# if path matches against the matcher, a new path is provided
# it's implied that the path will then be removed 
type 
    MatchResultKind* = enum SimpleMatch, ContentMatch, NoMatch

    MatchResult* = object
        case kind*: MatchResultKind
        of SimpleMatch:
            discard
        of ContentMatch:
            path*: string
        of NoMatch:
            discard

    Matcher* = proc(path: string): MatchResult {.closure.}


# if a file or dir matches against the pattern, it's returned
proc newSimpleMatcher(pattern: string): Matcher = 
    let patternRegex = re.re(
        pattern.replace(re"\.", "\\.").replace(re"\*", ".*")
    )

    proc matcher(filePath: string): MatchResult =
        if re.match(filePath, patternRegex):
            return MatchResult(kind: SimpleMatch)
        else:
            return MatchResult(kind: NoMatch)
    
    return matcher
        
# if a file inside the dir matches the pattern, the dir itself is returned
proc newContentMatcher(pattern: string, trailingLen: int): Matcher =
    let patternRegex = re.re(
        pattern.replace(re"\.", "\\.").replace(re"\*", ".*")
    )

    proc matcher(filePath: string): MatchResult =
        if re.match(filePath, patternRegex):
            return MatchResult(
                kind: ContentMatch,
                path: filePath[0 ..< (filePath.len - trailingLen)]
            )
        else:
            return MatchResult(kind: NoMatch)
    
    return matcher


proc newMatcher*(pattern: string): Matcher =
    let subPatterns = pattern.split(re"\@")

    case subPatterns.len
    of 1:
        return newSimpleMatcher(subPatterns[0])
    else:
        return newContentMatcher(
            pattern.replace(re"\@", "*"),
            subPatterns[1].len
        )