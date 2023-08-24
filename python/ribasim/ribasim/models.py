# generated by datamodel-codegen:
#   filename:  root.schema.json
#   timestamp: 2023-08-18T13:29:35+00:00

from __future__ import annotations

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class DiscreteControlLogic(BaseModel):
    remarks: Optional[str] = Field("", description="a hack for pandera")
    truth_state: str = Field(..., description="truth_state")
    node_id: int = Field(..., description="node_id")
    control_state: str = Field(..., description="control_state")


class Edge(BaseModel):
    remarks: Optional[str] = Field("", description="a hack for pandera")
    edge_type: str = Field(..., description="edge_type")
    fid: int = Field(..., description="fid")
    to_node_id: int = Field(..., description="to_node_id")
    from_node_id: int = Field(..., description="from_node_id")


class FlowBoundaryTime(BaseModel):
    remarks: Optional[str] = Field("", description="a hack for pandera")
    time: datetime = Field(..., description="time")
    flow_rate: float = Field(..., description="flow_rate")
    node_id: int = Field(..., description="node_id")


class PumpStatic(BaseModel):
    max_flow_rate: Optional[float] = Field(None, description="max_flow_rate")
    remarks: Optional[str] = Field("", description="a hack for pandera")
    active: Optional[bool] = Field(None, description="active")
    flow_rate: float = Field(..., description="flow_rate")
    node_id: int = Field(..., description="node_id")
    control_state: Optional[str] = Field(None, description="control_state")
    min_flow_rate: Optional[float] = Field(None, description="min_flow_rate")


class LevelBoundaryStatic(BaseModel):
    remarks: Optional[str] = Field("", description="a hack for pandera")
    active: Optional[bool] = Field(None, description="active")
    node_id: int = Field(..., description="node_id")
    level: float = Field(..., description="level")


class DiscreteControlCondition(BaseModel):
    remarks: Optional[str] = Field("", description="a hack for pandera")
    greater_than: float = Field(..., description="greater_than")
    listen_feature_id: int = Field(..., description="listen_feature_id")
    node_id: int = Field(..., description="node_id")
    variable: str = Field(..., description="variable")
    look_ahead: Optional[float] = Field(None, description="look_ahead")


class BasinForcing(BaseModel):
    remarks: Optional[str] = Field("", description="a hack for pandera")
    time: datetime = Field(..., description="time")
    precipitation: float = Field(..., description="precipitation")
    infiltration: float = Field(..., description="infiltration")
    urban_runoff: float = Field(..., description="urban_runoff")
    node_id: int = Field(..., description="node_id")
    potential_evaporation: float = Field(..., description="potential_evaporation")
    drainage: float = Field(..., description="drainage")


class FractionalFlowStatic(BaseModel):
    remarks: Optional[str] = Field("", description="a hack for pandera")
    node_id: int = Field(..., description="node_id")
    fraction: float = Field(..., description="fraction")
    control_state: Optional[str] = Field(None, description="control_state")


class LinearResistanceStatic(BaseModel):
    remarks: Optional[str] = Field("", description="a hack for pandera")
    active: Optional[bool] = Field(None, description="active")
    node_id: int = Field(..., description="node_id")
    resistance: float = Field(..., description="resistance")
    control_state: Optional[str] = Field(None, description="control_state")


class PidControlStatic(BaseModel):
    integral: float = Field(..., description="integral")
    remarks: Optional[str] = Field("", description="a hack for pandera")
    listen_node_id: int = Field(..., description="listen_node_id")
    active: Optional[bool] = Field(None, description="active")
    proportional: float = Field(..., description="proportional")
    node_id: int = Field(..., description="node_id")
    target: float = Field(..., description="target")
    derivative: float = Field(..., description="derivative")
    control_state: Optional[str] = Field(None, description="control_state")


class PidControlTime(BaseModel):
    integral: float = Field(..., description="integral")
    remarks: Optional[str] = Field("", description="a hack for pandera")
    listen_node_id: int = Field(..., description="listen_node_id")
    time: datetime = Field(..., description="time")
    proportional: float = Field(..., description="proportional")
    node_id: int = Field(..., description="node_id")
    target: float = Field(..., description="target")
    derivative: float = Field(..., description="derivative")
    control_state: Optional[str] = Field(None, description="control_state")


class ManningResistanceStatic(BaseModel):
    length: float = Field(..., description="length")
    manning_n: float = Field(..., description="manning_n")
    remarks: Optional[str] = Field("", description="a hack for pandera")
    active: Optional[bool] = Field(None, description="active")
    profile_width: float = Field(..., description="profile_width")
    node_id: int = Field(..., description="node_id")
    profile_slope: float = Field(..., description="profile_slope")
    control_state: Optional[str] = Field(None, description="control_state")


class FlowBoundaryStatic(BaseModel):
    remarks: Optional[str] = Field("", description="a hack for pandera")
    active: Optional[bool] = Field(None, description="active")
    flow_rate: float = Field(..., description="flow_rate")
    node_id: int = Field(..., description="node_id")


class OutletStatic(BaseModel):
    max_flow_rate: Optional[float] = Field(None, description="max_flow_rate")
    remarks: Optional[str] = Field("", description="a hack for pandera")
    active: Optional[bool] = Field(None, description="active")
    flow_rate: float = Field(..., description="flow_rate")
    node_id: int = Field(..., description="node_id")
    control_state: Optional[str] = Field(None, description="control_state")
    min_flow_rate: Optional[float] = Field(None, description="min_flow_rate")


class Node(BaseModel):
    remarks: Optional[str] = Field("", description="a hack for pandera")
    fid: int = Field(..., description="fid")
    type: str = Field(..., description="type")


class TabulatedRatingCurveTime(BaseModel):
    remarks: Optional[str] = Field("", description="a hack for pandera")
    time: datetime = Field(..., description="time")
    node_id: int = Field(..., description="node_id")
    discharge: float = Field(..., description="discharge")
    level: float = Field(..., description="level")


class TabulatedRatingCurveStatic(BaseModel):
    remarks: Optional[str] = Field("", description="a hack for pandera")
    active: Optional[bool] = Field(None, description="active")
    node_id: int = Field(..., description="node_id")
    discharge: float = Field(..., description="discharge")
    level: float = Field(..., description="level")
    control_state: Optional[str] = Field(None, description="control_state")


class BasinState(BaseModel):
    remarks: Optional[str] = Field("", description="a hack for pandera")
    node_id: int = Field(..., description="node_id")
    level: float = Field(..., description="level")


class BasinProfile(BaseModel):
    remarks: Optional[str] = Field("", description="a hack for pandera")
    area: float = Field(..., description="area")
    node_id: int = Field(..., description="node_id")
    level: float = Field(..., description="level")


class TerminalStatic(BaseModel):
    remarks: Optional[str] = Field("", description="a hack for pandera")
    node_id: int = Field(..., description="node_id")


class BasinStatic(BaseModel):
    remarks: Optional[str] = Field("", description="a hack for pandera")
    precipitation: float = Field(..., description="precipitation")
    infiltration: float = Field(..., description="infiltration")
    urban_runoff: float = Field(..., description="urban_runoff")
    node_id: int = Field(..., description="node_id")
    potential_evaporation: float = Field(..., description="potential_evaporation")
    drainage: float = Field(..., description="drainage")


class Root(BaseModel):
    BasinForcing: Optional[BasinForcing] = None
    BasinProfile: Optional[BasinProfile] = None
    BasinState: Optional[BasinState] = None
    BasinStatic: Optional[BasinStatic] = None
    DiscreteControlCondition: Optional[DiscreteControlCondition] = None
    DiscreteControlLogic: Optional[DiscreteControlLogic] = None
    Edge: Optional[Edge] = None
    FlowBoundaryStatic: Optional[FlowBoundaryStatic] = None
    FlowBoundaryTime: Optional[FlowBoundaryTime] = None
    FractionalFlowStatic: Optional[FractionalFlowStatic] = None
    LevelBoundaryStatic: Optional[LevelBoundaryStatic] = None
    LinearResistanceStatic: Optional[LinearResistanceStatic] = None
    ManningResistanceStatic: Optional[ManningResistanceStatic] = None
    Node: Optional[Node] = None
    OutletStatic: Optional[OutletStatic] = None
    PidControlStatic: Optional[PidControlStatic] = None
    PidControlTime: Optional[PidControlTime] = None
    PumpStatic: Optional[PumpStatic] = None
    TabulatedRatingCurveStatic: Optional[TabulatedRatingCurveStatic] = None
    TabulatedRatingCurveTime: Optional[TabulatedRatingCurveTime] = None
    TerminalStatic: Optional[TerminalStatic] = None