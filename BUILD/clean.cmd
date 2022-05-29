::#! 2> /dev/null                                   #
@ 2>/dev/null # 2>nul & echo off & goto BOF         #
if [ -z ${SIREUM_HOME} ]; then                      #
  echo "Please set SIREUM_HOME env var"             #
  exit -1                                           #
fi                                                  #
exec ${SIREUM_HOME}/bin/sireum slang run "$0" "$@"  #
:BOF
setlocal
if not defined SIREUM_HOME (
  echo Please set SIREUM_HOME env var
  exit /B -1
)
%SIREUM_HOME%\bin\sireum.bat slang run "%0" %*
exit /B %errorlevel%
::!#
// #Sireum

import org.sireum._
import org.sireum.ops._
import org.sireum.project.{Module, Project, Target}

val home = Os.slashDir.up.canon
val shellshock = home / "BUILD" / "SHELLSHOCK"
assert(shellshock.exists)

// relaxed rules, fluent
def mkdirRelaxed(path: Os.Path): Os.Path = {
  if (!path.isFile && !path.exists) {
    path.mkdirAll()
  }
  assert(path.exists && path.isDir)
  return path
}

@pure def splitOrFallback(string: String, splitter: C => B @pure, fallback: String): String = {
  val split = StringOps(string).split(splitter)
  val lastIndex = split.size - z"1"
  return if (lastIndex < z"0") fallback else split(lastIndex)
}

val max: Z => (Z => Z @pure) @pure = (a: Z) => (b: Z) => if (a > b) a else b
val nonNegative: Z => Z = max(z"0")

// "mods" list is all non-library projects to depend on lib. Mods are currently inferred by file structure.
@pure def projectCmdST(mods: ISZ[String]): ST = {

  @pure def lift(name: String): ST = {
    return st"""
               |val $name = Module(
               |  id = "$name",
               |  basePath = (home / "$name").string,
               |  subPathOpt = None(),
               |  deps = ISZ("lib"),
               |  targets = ISZ(Target.Jvm),
               |  ivyDeps = ISZ(),
               |  sources = ISZ((Os.path("src") / "main" / "scala").string),
               |  resources = ISZ(),
               |  testSources = ISZ((Os.path("src") / "test" / "scala").string),
               |  testResources = ISZ(),
               |  publishInfoOpt = None()
               |)"""
  }

  @pure def project(): ST = {
    val args: ISZ[String] = ISZ(string"Project.empty", string"lib") ++ mods
    val join: String = "+"
    return st"println(project.JSON.fromProject(${(args, join)}, T))"
  }

  // todo needs global unix2dos equivalent?
  return st"""
             |${shellshock.read}${"// #Sireum"}
             |${""}
             |${"import org.sireum._"}
             |${"import org.sireum.project.{Module, Project, Target}"}
             |${""}
             |${"val home = Os.slashDir.up.canon"}
             |${""}
             |${"val lib = Module("}
             |${"  id = \"lib\","}
             |${"  basePath = (home / \"lib\").string,"}
             |${"  subPathOpt = None(),"}
             |${"  deps = ISZ(),"}
             |${"  targets = ISZ(Target.Jvm),"}
             |${"  ivyDeps = ISZ(\"org.sireum.kekinian::library:\"),"}
             |${"  sources = ISZ((Os.path(\"src\") / \"main\" / \"scala\").string),"}
             |${"  resources = ISZ(),"}
             |${"  testSources = ISZ((Os.path(\"src\") / \"test\" / \"scala\").string),"}
             |${"  testResources = ISZ(),"}
             |${"  publishInfoOpt = None()"}
             |${")"}
             |${""}
             |${(mods.map(lift _), "\n")}
             |${project()}
             |"""
}

def initModule(mod: Os.Path): Os.Path = {
  mkdirRelaxed(mod / "src" / "main" / "scala")
  mkdirRelaxed(mod / "src" / "test" / "scala")
  return mod
}

val idea: Os.Path = home / ".idea"
val out: Os.Path = home / "out"
val lib: Os.Path = initModule(home / "lib") // init module files (even though we treat as lib)
val bin: Os.Path = home / "bin"
val build: Os.Path = home / "BUILD"
val excludedMatches: ISZ[Os.Path] = ISZ(lib, bin, out, build) // hidden dirs are also ignored

val isModule: (Os.Path => B @pure) = (p: Os.Path) => p.exists && p.isDir && excludedMatches.filter((q: Os.Path) => p == q).isEmpty

// canon and abs are system dependent, but file layout is not, so use as basis for shortName
val pathShortName: (Os.Path => String @pure) = (path: Os.Path) => {
  val splitter: (C => B @pure) = (c: C) => c == c"/" // todo handle case of windows double BS? or auto-converted?
  val fallback = string""
  splitOrFallback(path.string, splitter, fallback)
}

val modules = home.list
  .filter(isModule)
  .map(pathShortName)
  .filter((name: String) => StringOps(name).indexOf(c".") != z"0")

modules.foreach((shortName: String) => {
  initModule(home / shortName)
})

val projectDotCmd = bin / "project.cmd"
val content = projectCmdST(modules).render

idea.removeAll()
out.removeAll()
bin.removeAll()

projectDotCmd.writeOver(content)
projectDotCmd.chmodAll(string"+x") // must occur AFTER writeOver for perms to stick