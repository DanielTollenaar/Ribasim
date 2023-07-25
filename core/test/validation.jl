using Ribasim
using Graphs: DiGraph, add_edge!
using Dictionaries: Indices
using DataInterpolations: LinearInterpolation
import SQLite
using Logging

@testset "Basin profile validation" begin
    node_id = Indices([1])
    level = [[0.0, 0.0]]
    area = [[100.0, 100.0]]
    errors = Ribasim.valid_profiles(node_id, level, area)
    @test "Basin #1 has repeated levels, this cannot be interpolated." in errors
    @test "Basin profiles must start with area 0 at the bottom (got area 100.0 for node #1)." in
          errors
    @test length(errors) == 2

    itp, valid = Ribasim.qh_interpolation([0.0, 0.0], [1.0, 2.0])
    @test !valid
    @test itp isa LinearInterpolation
    itp, valid = Ribasim.qh_interpolation([0.0, 0.1], [1.0, 2.0])
    @test valid
    @test itp isa LinearInterpolation
end

@testset "Q(h) validation" begin
    toml_path = normpath(@__DIR__, "../../data/invalid_qh/invalid_qh.toml")
    @test ispath(toml_path)

    config = Ribasim.parsefile(toml_path)
    gpkg_path = Ribasim.input_path(config, config.geopackage)
    db = SQLite.DB(gpkg_path)

    logger = TestLogger()
    with_logger(logger) do
        @test_throws "Errors occurred when parsing TabulatedRatingCurve data." Ribasim.TabulatedRatingCurve(
            db,
            config,
        )
    end
    @test length(logger.logs) == 2
    @test logger.logs[1].level == Error
    @test logger.logs[1].message ==
          "A Q(h) relationship for TabulatedRatingCurve #1 from the static table has repeated levels, this can not be interpolated."
    @test logger.logs[2].level == Error
    @test logger.logs[2].message ==
          "A Q(h) relationship for TabulatedRatingCurve #2 from the time table has repeated levels, this can not be interpolated."
end

@testset "Neighbor count validation" begin
    graph_flow = DiGraph(6)
    add_edge!(graph_flow, 2, 1)
    add_edge!(graph_flow, 3, 1)
    add_edge!(graph_flow, 6, 2)

    pump = Ribasim.Pump(
        [1, 6],
        [true, true],
        [0.0, 0.0],
        [0.0, 0.0],
        [1.0, 1.0],
        Dict{Tuple{Int, String}, NamedTuple}(),
    )

    errors = Ribasim.valid_n_neighbors(graph_flow, pump)

    @test "Nodes of type Ribasim.Pump can have at most 1 inneighbor(s) (got 2 for node #1)." in
          errors
    @test "Nodes of type Ribasim.Pump must have at least 1 outneighbor(s) (got 0 for node #1)." in
          errors
    @test "Nodes of type Ribasim.Pump must have at least 1 inneighbor(s) (got 0 for node #6)." in
          errors
    @test length(errors) == 3

    add_edge!(graph_flow, 2, 5)
    add_edge!(graph_flow, 5, 3)
    add_edge!(graph_flow, 5, 4)

    fractional_flow =
        Ribasim.FractionalFlow([5], [true], [1.0], Dict{Tuple{Int, String}, NamedTuple}())

    errors = Ribasim.valid_n_neighbors(graph_flow, fractional_flow)
    @test only(errors) ==
          "Nodes of type Ribasim.FractionalFlow can have at most 1 outneighbor(s) (got 2 for node #5)."
end

@testset "PidControl connectivity validation" begin
    pid_control_node_id = [1, 6]
    pid_control_listen_node_id = [3, 5]

    graph_flow = DiGraph(7)
    graph_control = DiGraph(7)

    add_edge!(graph_flow, 3, 4)
    add_edge!(graph_flow, 7, 2)

    add_edge!(graph_control, 1, 4)
    add_edge!(graph_control, 6, 2)

    basin_node_id = Indices([5, 7])

    logger = TestLogger()
    with_logger(logger) do
        @test !Ribasim.valid_pid_connectivity(
            pid_control_node_id,
            pid_control_listen_node_id,
            graph_flow,
            graph_control,
            basin_node_id,
        )
    end

    @test length(logger.logs) == 2
    @test logger.logs[1].level == Error
    @test logger.logs[1].message == "Listen node #3 of PidControl node #1 is not a Basin"
    @test logger.logs[2].level == Error
    @test logger.logs[2].message ==
          "Listen node #5 of PidControl node #6 is not upstream of controlled node #2"
end