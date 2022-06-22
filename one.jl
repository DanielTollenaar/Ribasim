# Trying to get to feature completion using Mozart schematisation for only the Hupsel LSW
# lsw.jl focuses on preparing the data, one.jl on running the model

using Dates
using Revise: includet
using CairoMakie
using DiffEqCallbacks: PeriodicCallback
import DifferentialEquations as DE
using QuadGK

includet("components.jl")
includet("lib.jl")
includet("plot.jl")
includet("mozart-data.jl")
includet("lsw.jl")

@named sys = FreeFlowLSW(S = mz_lswval.volume[1])

sim = structural_simplify(sys)

# for debugging bad systems (parts of structural_simplify)
sys_check = expand_connections(sys)
sys_check = alias_elimination(sys_check)
state = TearingState(sys_check);
state = MTK.inputs_to_parameters!(state)
sys_check = state.sys
check_consistency(state)
if sys_check isa ODESystem
    sys_check = dae_order_lowering(dummy_derivative(sys_check, state))
end
equations(sys_check)
states(sys_check)
observed(sys_check)
parameters(sys_check)

sim
equations(sim)
states(sim)
observed(sim)
parameters(sim)


sysnames = Names(sim)
param_hist = ForwardFill(Float64[], Vector{Float64}[])
n = 10
tspan = (times[1], times[n])
prob = ODAEProblem(sim, [], tspan)

function param!(integrator, s, x::Real)::Real
    (; p) = integrator
    @debug "param!" integrator.t
    sym = Symbolics.getname(s)::Symbol
    i = findfirst(==(sym), sysnames.p_symbol)
    return p[i] = x
end

function periodic_update!(integrator)
    # exchange with Modflow and Metaswap here
    # update precipitation
    (; t, p) = integrator
    param!(integrator, :P, prec_series(t))
    param!(integrator, :E_pot, evap_series(t))
    save!(param_hist, t, p)
    return nothing
end

cb = PeriodicCallback(periodic_update!, Δt; initial_affect = true)

integrator = init(prob, DE.Rodas5(), callback = cb, save_on = true)
reg = Register(integrator, param_hist, sysnames)

solve!(integrator)  # solve it until the end


begin
    timespan = tspan[1] .. tspan[2]
    fig = Figure()
    ax1 = Axis(fig[1, 1])
    ax2 = Axis(fig[2, 1])
    lines!(ax1, timespan, interpolator(reg, :Q_prec), label = "Q_prec")
    lines!(ax1, timespan, interpolator(reg, :Q_eact), label = "Q_eact")
    lines!(ax1, timespan, interpolator(reg, :Q_out), label = "Q_out")
    axislegend(ax1)
    lines!(ax2, timespan, interpolator(reg, :S), label = "S")
    axislegend(ax2)
    fig
end

##
# plotting the water balance

"""
    sum_fluxes(f::Function, times::Vector{Float64})::Vector{Float64}

Integrate a function `f(t)` between every successive two times in `times`.
For a `f` that gives a flux in m³ s⁻¹, and a daily `times` vector, this will
give the daily total in m³, which can be used in a water balance.
"""
function sum_fluxes(f::Function, times::Vector{Float64})::Vector{Float64}
    n = length(times)
    integrals = Array{Float64}(undef, n - 1)
    for i = 1:n-1
        integral, err = quadgk(f, times[i], times[i+1])
        integrals[i] = integral
    end
    return integrals
end

Q_eact_itp = interpolator(reg, :Q_eact)
Q_prec_itp = interpolator(reg, :Q_prec)
Q_out_itp = interpolator(reg, :Q_out)
S_itp = interpolator(reg, :S)


Q_eact_sum = sum_fluxes(Q_eact_itp, times[1:n])
Q_prec_sum = sum_fluxes(Q_prec_itp, times[1:n])
Q_out_sum = sum_fluxes(Q_out_itp, times[1:n])
# for storage we take the diff. 1e-6 is needed to avoid NaN at the start
S_diff = diff(S_itp.(times[1:n] .+ 1e-6))

# create a dataframe with the same names and sign conventions as lswwaterbalans.out
bachwb = DataFrame(
    model = "bach",
    lsw = lsw_hupsel,
    districtwatercode = 24,
    type = "V",
    time_start = DateTime.(dates[1:n-1]),
    time_end = DateTime.(dates[2:n]),
    precip = Q_prec_sum,
    evaporation = -Q_eact_sum,
    todownstream = -Q_out_sum,
    storage_diff = -S_diff,
)

function plot_waterbalance(mzwb, bachwb)
    # plot only dates we have for both
    time_start = intersect(mzwb.time_start, bachwb.time_start)
    mzwb = @subset(mzwb, :time_start in time_start)
    bachwb = @subset(bachwb, :time_start in time_start)
    n = nrow(mzwb)

    # long format daily waterbalance dataframe for comparing mozart and bach
    wb = vcat(stack(bachwb), stack(mzwb))

    # Find all the water balance components that we have we need to use the same names for
    # the same components in the two input dataframes. If there are more, cycle the
    # color palette.
    metacols = ["model", "lsw", "districtwatercode", "type", "time_start", "time_end"]
    vars = setdiff(union(names(mzwb), names(bachwb)), metacols)

    # use days since start as x
    x = Dates.value.(Day.(wb.time_start .- minimum(wb.time_start)))
    # map each variable to an integer
    stacks = [findfirst(==(v), vars) for v in wb.variable]

    if any(isnothing, stacks)
        error("nothing found")
    end
    dodge = [x == "mozart" ? 1 : 2 for x in wb.model]

    fig = Figure()
    ax = Axis(
        fig[1, 1],
        # label the first and last day
        xticks = (collect(extrema(x)), string.(dates[[1, n - 1]])),
        xlabel = "time / s",
        ylabel = "volume / m³",
        title = "Mozart and Bach daily water balance",
    )

    barplot!(ax, x, wb.value; dodge, stack = stacks, color = stacks, colormap = wong_colors)

    elements = vcat(
        [MarkerElement(marker = 'L'), MarkerElement(marker = 'R')],
        [PolyElement(polycolor = wong_colors[i]) for i = 1:length(vars)],
    )
    Legend(fig[1, 2], elements, vcat("mozart", "bach", vars))

    return fig
end

plot_waterbalance(mzwb, bachwb)


##
# compare individual component timeseries
begin
    fig = Figure()
    ax = time!(Axis(fig[1, 1]), dates[1:n])

    # stairs!(ax, times[1:n-1], Q_eact_sum; step=:post, label="evap bach")
    # stairs!(ax, times[1:n-1], -mz_wb.evaporation[1:n-1]; step=:post, label="evap mozart")

    # stairs!(ax, times[1:n-1], Q_prec_sum; step=:post, label="prec bach")
    # stairs!(ax, times[1:n-1], mz_wb.precip[1:n-1]; step=:post, label="prec mozart")

    # stairs!(ax, times[1:n-1], S_diff; step=:post, label="ΔS bach")
    # stairs!(ax, times[1:n-1], -mz_wb.storage_diff[1:n-1]; step=:post, label="ΔS mozart")

    stairs!(ax, timespan, S_itp; step = :post, label = "S bach")
    stairs!(ax, times[1:n-1], mz_lswval.volume[1:n-1]; step = :post, label = "S mozart")

    axislegend(ax)
    fig
end


##
# plot water balance histogram over time



Q_eact_sum


##

lines(0 .. 20, S -> (0.5 * tanh((S - 10.0) / 2.0) + 0.5))
lines(0 .. 100, S -> (0.5 * tanh((S - 50.0) / 10.0) + 0.5))
lines(1400 .. 1500, S -> max(0.0004 * (S - 1463.5), 0))
k = 10

# min approximation from
# https://discourse.julialang.org/t/handling-instability-when-solving-ode-problems/9019/5
begin
    f(x) = min(1.0, 1.0 + x)
    function g(x, k)
        ex = exp(-k)
        ey = exp(-k * (1.0 + x))
        (ex + (1.0 + x) * ey) / (ex + ey)
    end
    pts = -2.0 .. 2.0
    lines(pts, f, label = "min")
    lines!(pts, x -> g(x, 10), label = "k=10")
    axislegend()
    current_figure()
end

# try max https://en.wikipedia.org/wiki/Smooth_maximum
# https://juliastats.org/LogExpFunctions.jl/stable/#LogExpFunctions.log1pexp
using LogExpFunctions
begin
    f(S) = max(0, 0.0004 * (S - 1463.5))
    # g(S) = 0.0004 * log(1 + exp(S - 1463.5))
    g(S) = 0.0004 * log1pexp(S - 1463.5)

    # pts = 1460 .. 1470
    pts = 0 .. 3000
    lines(pts, f, label = "min")
    lines!(pts, g, label = "k=10")
    axislegend()
    current_figure()
end

(; sol) = integrator

first.(sol.u)[1:10]
interpolator(reg, :Q_out).(sol.t[1:10])

# lswdik
# vadvalue
# weirarea
# waattr
# vlvalue
# mftolsw

# fit the StorageCurve with equations
let
    f(x) = 0.0004 * (x - 1463.5)
    lines(curve.s, curve.q)
    lines!(curve.s, f)
    lines!(curve.s, g)
    current_figure()
end
