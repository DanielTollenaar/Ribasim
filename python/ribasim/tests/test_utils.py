import geopandas as gpd
import numpy as np
import pandas as pd
from numpy.testing import assert_array_equal
from ribasim import utils
from ribasim.geometry.node import Node
from shapely import LineString


def test_utils():
    node_type = ("Basin", "LinearResistance", "Basin")

    xy = np.array([(0.0, 0.0), (1.0, 0.0), (2.0, 0.0)])

    node_xy = gpd.points_from_xy(x=xy[:, 0], y=xy[:, 1])

    node = Node(
        static=gpd.GeoDataFrame(
            data={"type": node_type},
            index=pd.Index(np.arange(len(xy)) + 1, name="fid"),
            geometry=node_xy,
            crs="EPSG:28992",
        )
    )

    from_id = np.array([1, 2], dtype=np.int64)
    to_id = np.array([2, 3], dtype=np.int64)

    lines = utils.geometry_from_connectivity(node, from_id, to_id)
    assert lines[0].equals(LineString([xy[from_id[0] - 1], xy[to_id[0] - 1]]))
    assert lines[1].equals(LineString([xy[from_id[1] - 1], xy[to_id[1] - 1]]))

    from_id_, to_id_ = utils.connectivity_from_geometry(node, lines)

    assert_array_equal(from_id, from_id_)
    assert_array_equal(to_id, to_id_)