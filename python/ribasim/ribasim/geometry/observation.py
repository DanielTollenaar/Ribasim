from typing import Any

import pandera as pa
from pandera.dtypes import Int32
from pandera.typing import Series, Timestamp
from pandera.typing.geopandas import GeoSeries

from ribasim.schemas import _BaseSchema


class ObservationSchema(_BaseSchema):
    node_id: Series[Int32] = pa.Field(nullable=False, default=0)
    name: Series[str] = pa.Field(default="")
    node_type: Series[str] = pa.Field(default="")
    variable: Series[str] = pa.Field(nullable=False)
    geometry: GeoSeries[Any] = pa.Field(default=None, nullable=True)
