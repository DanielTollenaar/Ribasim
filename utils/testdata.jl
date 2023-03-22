using Downloads
# ensure test data is present
datadir = normpath(@__DIR__, "../data")
const teamcity_presence_env_var = "TEAMCITY_VERSION"

"Download a test data file if it does not already exist"
function testdata(
    source_filename::String,
    target_filename::String = source_filename;
    version::VersionNumber = v"0.5.0",
)
    target_path = joinpath(datadir, target_filename)
    parent_path = dirname(target_path)
    isdir(parent_path) || mkpath(parent_path)
    base_url = "https://github.com/visr/ribasim-artifacts/releases/download/v$version/"
    url = string(base_url, source_filename)
    isfile(target_path) || Downloads.download(url, target_path)
    return target_path
end

is_running_under_teamcity() = haskey(ENV, teamcity_presence_env_var)

function teamcity_message(name, value)
    println("##teamcity['$name' '$value']")
end

function teamcity_message(name, d::Dict)
    println(
        "##teamcity[$name " *
        string(collect(("'$(key)'='$value' " for (key, value) in pairs(d)))...) *
        "]",
    )
end

nothing