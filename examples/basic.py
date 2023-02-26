# %%
import os

os.environ["USE_PYGEOS"] = "0"

import geopandas as gpd
import numpy as np
import pandas as pd

import ribasim

# %%
# Set up the nodes:

xy = np.array(
    [
        (0.0, 0.0),  # Basin,
        (1.0, 0.0),  # LinearLevelConnection
        (2.0, 0.0),  # Basin
        (3.0, 0.0),  # TabulatedRatingCurve
        (3.0, 1.0),  # FractionalFlow
        (3.0, 2.0),  # Basin
        (4.0, 0.0),  # FractionalFlow
        (5.0, 0.0),  # Basin
        (6.0, 0.0),  # LevelControl
    ]
)
node_xy = gpd.points_from_xy(x=xy[:, 0], y=xy[:, 1])

node_type = [
    "Basin",
    "LinearLevelConnection",
    "Basin",
    "TabulatedRatingCurve",
    "FractionalFlow",
    "Basin",
    "FractionalFlow",
    "Basin",
    "LevelControl",
]
node = ribasim.Node(static=gpd.GeoDataFrame(data={"type": node_type}, geometry=node_xy))

# %%
# Setup the edges:

from_id = np.array([0, 1, 2, 3, 3, 4, 6, 7], dtype=np.int64)
to_id = np.array([1, 2, 3, 4, 6, 5, 7, 8], dtype=np.int64)
lines = ribasim.utils.geometry_from_connectivity(node, from_id, to_id)
edge = ribasim.Edge(
    static=gpd.GeoDataFrame(
        data={"from_node_id": from_id, "to_node_id": to_id, "geometry": lines}
    )
)

# %%
# Setup the basins:

profile = pd.DataFrame(
    data={
        "node_id": [0, 0],
        "storage": [0.0, 1000.0],
        "area": [0.0, 1000.0],
        "level": [0.0, 1.0],
    }
)
repeat = np.tile([0, 1], 4)
profile = profile.iloc[repeat]
profile["node_id"] = [0, 0, 2, 2, 5, 5, 7, 7]

static = pd.DataFrame(
    data={
        "node_id": [0],
        "drainage": [0.006],
        "potential_evaporation": [0.0115],
        "infiltration": [0.0],
        "precipitation": [0.0],
        "urban_runoff": [0.0],
    }
)
static = static.iloc[[0, 0, 0, 0]]
static["node_id"] = [0, 2, 5, 7]

basin = ribasim.Basin(profile=profile, static=static)

# %%
# Setup linear level connection:

linear_connection = ribasim.LinearLevelConnection(
    static=pd.DataFrame(data={"node_id": [1], "conductance": [1.5e-4]})
)


# %%
# Set up a rating curve node:

rating_curve = ribasim.TabulatedRatingCurve(
    static=pd.DataFrame(
        data={
            "node_id": [3, 3],
            "storage": [0.0, 1000.0],
            "discharge": [0.0, 1.5e-4],
        }
    )
)

# %%
# Setup fractional flows:

fractional_flow = ribasim.FractionalFlow(
    static=pd.DataFrame(
        data={
            "node_id": [4, 6],
            "fraction": [0.3, 0.7],
        }
    )
)

# %%
# Setup level control:

level_control = ribasim.LevelControl(
    static=pd.DataFrame(
        data={
            "node_id": [8],
            "target_level": [1.5],
        }
    )
)

# %%
# Setup a model:

model = ribasim.Model(
    modelname="basic",
    node=node,
    edge=edge,
    basin=basin,
    level_control=level_control,
    linear_level_connection=linear_connection,
    tabulated_rating_curve=rating_curve,
    starttime="2020-01-01 00:00:00",
    endtime="2021-01-01 00:00:00",
)

# %%
# Write the model to a TOML and GeoPackage:

model.write("basic")
# %%
