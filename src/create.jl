
function create_basin_nodemap(db::DB)::Dictionary{Int, Int}
    # Enumerate the nodes that have state: the reservoirs.
    basin_id = get_ids(db, "Basin")
    return Dictionary(basin_id, 1:length(basin_id))
end

"""
Creation of a sparse matrix sorts the indices.

Create a map of every (from, to) => connection to the nonzero values in the
sparse matrix.
"""
function create_connection_map(flow)
    I, J, _ = findnz(flow)
    return Dictionary([(i, j) for (i, j) in zip(I, J)], 1:length(I))
end

function create_connectivity(db::DB)::Connectivity
    # nodemap: external ID to flow graph index
    # inverse_nodemap: flow graph index to external ID
    # basin_nodemap: external ID to state index
    # inverse_basin_nodemap: state index to external ID
    # connection_map: (flow graph index1, flow graph index2) to non-zero index in sparse matrix.
    # node_to_basin: flow graph index to state index
    g, nodemap = graph(db)
    inverse_nodemap = Dictionary(values(nodemap), keys(nodemap))
    basin_nodemap = create_basin_nodemap(db)
    inverse_basin_nodemap = Dictionary(values(basin_nodemap), keys(basin_nodemap))
    # Skip toposort for now, only a single set of bifurcations.
    # toposort = topological_sort_by_dfs(g)
    # nodemap = Dictionary(keys(vxdict), toposort)

    I = Int[]
    J = Int[]
    for e in edges(g)
        push!(I, e.src)
        push!(J, e.dst)
    end

    basin_ids = keys(basin_nodemap)
    # for each connection
    from_basin = in.([inverse_nodemap[i] for i in I], [basin_ids])
    to_basin = in.([inverse_nodemap[j] for j in J], [basin_ids])

    flow = sparse(I, J, zeros(length(I)))
    connection_map = create_connection_map(flow)
    node_to_basin = Dictionary([nodemap[k] for k in basin_ids], values(basin_nodemap))

    return Connectivity(
        flow,
        from_basin,
        to_basin,
        nodemap,
        basin_nodemap,
        inverse_basin_nodemap,
        connection_map,
        node_to_basin,
    )
end

function create_connection_index(
    db::DB,
    edge::DataFrame,
    nodemap,
    basin_nodemap,
    connection_map,
    linktype::String,
)
    link_ids = get_ids(db, linktype)
    ab = sort(
        filter(
            [:to_node_id, :to_connector] => (x, y) -> x in (link_ids) && y == "storage",
            edge;
            view = true,
        ),
        :to_node_id,
    )
    bc = sort(filter(:from_node_id => in(link_ids), edge; view = true), :from_node_id)
    a = [nodemap[i] for i in ab.from_node_id]
    b = [nodemap[i] for i in ab.to_node_id]
    c = [nodemap[i] for i in bc.to_node_id]
    index_ab = [connection_map[(i, j)] for (i, j) in zip(a, b)]
    # TODO fix edge direction
    index_bc = Int[]
    for (i, j) in zip(b, c)
        idx = get(connection_map, (i, j), 0)
        if idx == 0
            idx = connection_map[(j, i)]
        end
        push!(index_bc, idx)
    end
    index = transpose(hcat(index_ab, index_bc))

    source = [basin_nodemap[i] for i in ab.from_node_id]
    target = [get(basin_nodemap, i, -1) for i in bc.to_node_id]
    return ab.to_node_id, source, target, index
end

function create_level_links(db::DB, edge::DataFrame, nodemap, basin_nodemap, connection_map)
    _, source, target, index = create_connection_index(
        db,
        edge,
        nodemap,
        basin_nodemap,
        connection_map,
        "LevelLink",
    )
    _, n = size(index)
    conductance = fill(100.0 / (3600.0 * 24), n)
    return LevelLinks(source, target, index, conductance)
end

function create_outflow_links(
    db::DB,
    config::Config,
    edge::DataFrame,
    nodemap,
    basin_nodemap,
    connection_map,
)
    link_ids, source, _, index = create_connection_index(
        db,
        edge,
        nodemap,
        basin_nodemap,
        connection_map,
        "OutflowTable",
    )
    tables = OutflowTable[]
    df = DataFrame(load_data(db, config, ("lookup", "OutflowTable")))
    grouped = groupby(df, :node_id)
    for id in link_ids
        # Index with a tuple to get a group.
        group = grouped[(id,)]
        order = sortperm(group.level)
        level = group.level[order]
        discharge = group.discharge[order]
        interp = LinearInterpolation(discharge, level)
        push!(tables, OutflowTable(level, discharge, interp))
    end

    return OutflowLinks(source, index, tables)
end

function create_storage_tables(
    db::DB,
    config::Config,
    basin_nodemap::Dictionary{Int64, Int64},
)
    table = load_required_data(db, config, ("lookup", "Basin"))
    df = DataFrame(table)
    tables = StorageTable[]
    grouped = groupby(df, :node_id)
    index = Int[]
    for (key, group) in zip(keys(grouped), grouped)
        order = sortperm(group.volume)

        volume = group.volume[order]
        area = group.area[order]
        level = group.level[order]
        area_interp = LinearInterpolation(area, volume)
        level_interp = LinearInterpolation(level, volume)

        table = StorageTable(volume, area, level, area_interp, level_interp)
        push!(tables, table)
        push!(index, basin_nodemap[key.node_id])
    end
    order = sortperm(index)
    return StorageTables(index[order], tables[order])
end

function create_furcations(db::DB, edge::DataFrame, nodemap, connection_map)
    furcation_ids = get_ids(db, "Bifurcation")
    # target is larger than source if a flow splits.
    source = filter(:to_node_id => in(furcation_ids), edge; view = true)
    target = filter(:from_node_id => in(furcation_ids), edge; view = true)
    grouped = groupby(target, :from_node_id)

    source_connection = Int[]
    target_connection = Int[]
    fraction = Float64[]
    # a = basin node
    # b = furcation node
    # c = downstreams of furcation
    for (a, b) in zip(source.from_node_id, source.to_node_id)
        src = connection_map[(nodemap[a], nodemap[b])]
        for c in grouped[(b,)].to_node_id
            push!(source_connection, src)
            # TODO fix edge direction
            target = get(connection_map, (nodemap[b], nodemap[c]), 0)
            if target == 0
                target = connection_map[(nodemap[c], nodemap[b])]
            end
            push!(target_connection, target)
            push!(fraction, 0.5)
        end
    end

    return Furcations(source_connection, target_connection, fraction)
end

function create_level_control(
    db::DB,
    config::Config,
    edge::DataFrame,
    basin_nodemap::Dictionary{Int64, Int64},
)
    static = load_data(db, config, ("static", "LevelControl"))
    if static === nothing
        return LevelControl([], [], [])
    else
        control_nodes = unique(DataFrame(static))
    end
    control_edges = filter(:to_node_type => ==("LevelControl"), edge)
    volume_lookup = Dictionary(control_nodes.node_id, control_nodes.target_volume)
    index = [basin_nodemap[i] for i in control_edges.from_node_id]
    volume = [volume_lookup[i] for i in control_edges.to_node_id]
    conductance = fill(1.0 / (3600.0 * 24), length(index))
    return LevelControl(index, volume, conductance)
end

function create_parameters(db::DB, config::Config)

    # Setup node/edges graph, so validate in `create_connectivity`?
    connectivity = create_connectivity(db)
    nodemap = connectivity.nodemap
    basin_nodemap = connectivity.basin_nodemap
    connection_map = connectivity.connection_map

    # Setup output(?)
    n = length(basin_nodemap)
    area = zeros(n)
    level = zeros(n)
    storage_diff = zeros(n)
    precipitation = Precipitation(1:n, zeros(n), zeros(n))
    evaporation = Evaporation(1:n, zeros(n), zeros(n))
    infiltration = Infiltration(1:n, zeros(n), zeros(n))
    drainage = Drainage(1:n, zeros(n), zeros(n))

    storage_tables = create_storage_tables(db, config, basin_nodemap)
    # Not in `connectivity`?
    edge = DataFrame(execute(db, "select * from ribasim_edge"))

    level_links = create_level_links(db, edge, nodemap, basin_nodemap, connection_map)
    outflow_links =
        create_outflow_links(db, config, edge, nodemap, basin_nodemap, connection_map)
    furcations = create_furcations(db, edge, nodemap, connection_map)
    level_control = create_level_control(db, config, edge, basin_nodemap)

    # TODO support forcing for other nodetypes, make optional
    forcing = DataFrame(load_required_data(db, config, ("forcing", "Basin")))
    grouped = groupby(forcing, :time)
    timed_forcing = Dict([k[1] for k in keys(grouped)] .=> collect(grouped))
    # this is how often we need to callback
    used_time_uniq = keys(timed_forcing)

    return Parameters(
        connectivity,
        storage_tables,
        area,
        level,
        storage_diff,
        precipitation,
        evaporation,
        level_links,
        outflow_links,
        furcations,
        level_control,
        infiltration,
        drainage,
        timed_forcing,
    ),
    used_time_uniq
end
