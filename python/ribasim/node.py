from typing import Any

import matplotlib.pyplot as plt
import pandas as pd
import pandera as pa
from pandera.typing import DataFrame, Series
from pandera.typing.geopandas import GeoSeries
from pydantic import BaseModel

from ribasim.input_base import InputMixin

__all__ = ("Node",)


_MARKERS = {
    "Basin": "o",
    "FractionalFlow": "^",
    "LevelControl": "*",
    "LinearLevelConnection": "^",
    "TabulatedRatingCurve": "D",
    "": "o",
}


class StaticSchema(pa.SchemaModel):
    type: Series[str]
    geometry: GeoSeries


class Node(InputMixin, BaseModel):
    """
    The Ribasim nodes as Point geometries.

    Parameters
    ----------
    static: geopandas.GeoDataFrame

        With columns:

        * type
        * geometry

    """

    _input_type = "Node"
    static: DataFrame[StaticSchema]

    class Config:
        validate_assignment = True

    def __init__(self, static: pd.DataFrame):
        super().__init__(**locals())

    def plot(self, **kwargs) -> Any:
        """
        Plot the nodes. Each node type is given a separate marker.

        Parameters
        ----------
        **kwargs: optional
            Keyword arguments forwarded to GeoDataFrame.plot.

        Returns
        -------
        None
        """
        kwargs = kwargs.copy()
        ax = kwargs.get("ax", None)
        if ax is None:
            _, ax = plt.subplots()
            kwargs["ax"] = ax

        for nodetype, df in self.static.groupby("type"):
            marker = _MARKERS[nodetype]
            kwargs["marker"] = marker
            df.plot(**kwargs)

        return ax