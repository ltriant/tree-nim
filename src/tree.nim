# A tree command that's just how I like it
#
#              \ /
#            -->*<--
#              /o\
#             /_\_\
#            /_/_0_\
#           /_o_\_\_\
#          /_/_/_/_/o\
#         /@\_\_\@\_\_\
#        /_/_/O/_/_/_/_\
#       /_\_\_\_\_\o\_\_\
#      /_/0/_/_/_0_/_/@/_\
#     /_\_\_\_\_\_\_\_\_\_\
#    /_/o/_/_/@/_/_/o/_/0/_\
#             [___]

import std/[options, os, strutils, terminal]
from std/algorithm import sort, reverse
from std/sequtils import toSeq, keepIf

import docopt

const LineHorizontal: string = "\u2500"# ─
const LineVertical: string = "\u2502"  # │
const LineMiddle: string = "\u251c"    # ├
const LineLast: string = "\u2514"      # └

const IndentMiddleItem: string = LineMiddle & LineHorizontal & LineHorizontal
const IndentLastItem: string = LineLast & LineHorizontal & LineHorizontal

const Doc: string = """
tree

Usage:
  tree [-drsfh] [-L level] [<path>]

Options:
  -d        Show directories only
  -L level  Descend only `level' directories deep
  -r        Sort in reverse alphabetic order
  -s        Print a summary of directories and files at the end
  -f        Print the full path of each file
  -h        This help message
"""

type
  CrawlResult = object
    numFiles: int
    numFolders: int

proc crawlAndPrint(
    path: string,
    maxDepth: Option[int] = none(int),
    level: int = 0,
    fullPath: bool = false,
    directoriesOnly: bool = false,
    reverseSort: bool = false,
    prefix: string = ""
  ): CrawlResult =

  var rv = CrawlResult(numFiles: 0, numFolders: 0)

  if maxDepth.isSome and level == maxDepth.get:
    return rv

  var entities = os.walkDir(path, relative = not fullPath).toSeq

  if directoriesOnly:
    entities.keepIf do (x: tuple[kind: PathComponent, path: string]) -> bool:
      x.kind == PathComponent.pcDir

  entities.sort do (x, y: tuple[kind: PathComponent, path: string]) -> int:
    # Always sort directories to the top
    if x.kind == PathComponent.pcDir and y.kind != PathComponent.pcDir:
      return -1
    if x.kind != PathComponent.pcDir and y.kind == PathComponent.pcDir:
      return 1
    else:
      return cmp(x.path, y.path)

  if reverseSort:
    entities.reverse()

  for i, (kind, fsPath) in entities:
    let indent = if i == high(entities):
      prefix & IndentLastItem
    else:
      prefix & IndentMiddleItem

    let absolutePath = if fullPath:
      fsPath
    else:
      path & "/" & fsPath

    case kind

    of PathComponent.pcFile:
      if not directoriesOnly:
        rv.numFiles += 1

        let fileInfo = os.getFileInfo(absolutePath)
        if FilePermission.fpUserExec in fileInfo.permissions or
          FilePermission.fpGroupExec in fileInfo.permissions or
          FilePermission.fpOthersExec in fileInfo.permissions:

          styledEcho indent, " ", styleBright, fgGreen, fsPath
        else:
          echo indent, " ", fsPath

    of PathComponent.pcDir, PathComponent.pcLinkToDir:
      rv.numFolders += 1

      styledEcho indent, " ", styleBright, fgBlue, fsPath

      let newPrefix = if i == high(entities):
        prefix & "    "
      else:
        prefix & LineVertical & "   "

      let dirResult = crawlAndPrint(
        absolutePath,
        maxDepth,
        level + 1,
        fullPath,
        directoriesOnly,
        reverseSort,
        newPrefix
      )
      rv.numFiles += dirResult.numFiles
      rv.numFolders += dirResult.numFolders

    of PathComponent.pcLinkToFile:
      if not directoriesOnly:
        let linkPath = os.expandSymlink(absolutePath)
        rv.numFiles += 1
        styledEcho indent, " ", styleBright, fgRed, fsPath, resetStyle, fgCyan, " -> ", linkPath

  return rv

proc printSummary(summary: CrawlResult) =
  echo "\n$1 $2, $3 $4" % [
    $summary.numFolders,
    if summary.numFolders == 1: "directory" else: "directories",
    $summary.numFiles,
    if summary.numFiles == 1: "file" else: "files"
  ]

when isMainModule:
  let args = docopt(Doc)

  let maxDepth = if args["-L"]:
    some(parseInt($args["-L"]))
  else:
    none(int)

  let path = if args["<path>"]:
    $args["<path>"]
  else:
    os.getCurrentDir()

  echo path
  let summary = crawlAndPrint(
    path,
    maxDepth,
    fullPath = args["-f"],
    directoriesOnly = args["-d"],
    reverseSort = args["-r"]
  )

  if args["-s"]:
    printSummary(summary)
