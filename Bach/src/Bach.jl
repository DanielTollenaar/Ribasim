module Bach

# turn off precompilation during development
__precompile__(false)

using DiffEqCallbacks
using DifferentialEquations
import DifferentialEquations as DE
using ModelingToolkit
using QuadGK
using SciMLBase
using Symbolics: getname
using DataFrames
using DataFrameMacros
using Dates
import BasicModelInterface as BMI
using TOML
using Graphs
using Arrow
using PlyIO

export interpolator, Register, ForwardFill

include("lib.jl")
include("system.jl")
include("construction.jl")
include("bmi.jl")
include("io.jl")

end # module Bach
