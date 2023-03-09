using PkgEval
using FMI

config = Configuration(; julia="1.8");

package = Package(; name="FMI.jl");

@info "PkgEval"
println(evaluate([config], [package]))