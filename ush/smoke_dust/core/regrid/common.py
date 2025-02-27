"""Common regridding functionality used by the regrid processor."""

import abc
from pathlib import Path
from typing import Tuple, Literal, Union, Dict, Any

import esmpy
import netCDF4 as nc
import numpy as np
from pydantic import BaseModel, ConfigDict, model_validator

from smoke_dust.core.common import open_nc

NameListType = Tuple[str, ...]


class Dimension(BaseModel):
    """A dimension object containing metadata and rank bounds information."""

    name: NameListType
    size: int
    lower: int
    upper: int
    staggerloc: int
    coordinate_type: Literal["y", "x", "time"]


class DimensionCollection(BaseModel):
    """A collection of dimension objects."""

    value: Tuple[Dimension, ...]

    def get(self, name: Union[str, NameListType]) -> Dimension:
        """
        Get a dimension object from the collection.
        """
        if isinstance(name, str):
            name_to_find = (name,)
        else:
            name_to_find = name
        for curr_name in name_to_find:
            for curr_value in self.value:
                if curr_name in curr_value.name:
                    return curr_value
        raise ValueError(f"dimension not found: {name}")


class AbstractWrapper(abc.ABC, BaseModel):
    """
    Superclass for all wrapper objects. Wrapper objects map metadata to an associated ``esmpy``
    object.
    """

    model_config = ConfigDict(arbitrary_types_allowed=True)
    dims: DimensionCollection


class GridSpec(BaseModel):
    """Defines a grid specification that can be read from a netCDF file."""

    model_config = ConfigDict(frozen=True)

    x_center: str
    y_center: str
    x_dim: NameListType
    y_dim: NameListType
    x_corner: Union[str, None] = None
    y_corner: Union[str, None] = None
    x_corner_dim: Union[NameListType, None] = None
    y_corner_dim: Union[NameListType, None] = None
    x_index: int = 0
    y_index: int = 1

    @model_validator(mode="after")
    def _validate_model_(self) -> "GridSpec":
        corner_meta = [
            self.x_corner,
            self.y_corner,
            self.x_corner_dim,
            self.y_corner_dim,
        ]
        is_given_sum = sum(ii is not None for ii in corner_meta)
        if is_given_sum > 0 and is_given_sum != len(corner_meta):
            raise ValueError("if one corner name is supplied, then all must be supplied")
        return self

    @property
    def has_corners(self) -> bool:
        """Returns true if the grid has corners."""
        return self.x_corner is not None

    def get_x_corner(self) -> str:
        """Get the name of the `x` corner."""
        if self.x_corner is None:
            raise ValueError
        return self.x_corner

    def get_y_corner(self) -> str:
        """Get the name of the `y` corner."""
        if self.y_corner is None:
            raise ValueError
        return self.y_corner

    def get_x_data(self, grid: esmpy.Grid, staggerloc: esmpy.StaggerLoc) -> np.ndarray:
        """Get x-coordinate data from a grid."""
        return grid.get_coords(self.x_index, staggerloc=staggerloc)

    def get_y_data(self, grid: esmpy.Grid, staggerloc: esmpy.StaggerLoc) -> np.ndarray:
        """Get y-coordinate data from a grid."""
        return grid.get_coords(self.y_index, staggerloc=staggerloc)

    def create_grid_dims(
        self, nc_ds: nc.Dataset, grid: esmpy.Grid, staggerloc: esmpy.StaggerLoc
    ) -> DimensionCollection:
        """Create a dimension collection from a netCDF dataset and ``esmpy`` grid."""
        if staggerloc == esmpy.StaggerLoc.CENTER:
            x_dim, y_dim = self.x_dim, self.y_dim
        elif staggerloc == esmpy.StaggerLoc.CORNER:
            x_dim, y_dim = self.x_corner_dim, self.y_corner_dim
        else:
            raise NotImplementedError(staggerloc)
        x_dimobj = Dimension(
            name=x_dim,
            size=_get_nc_dimension_(nc_ds, x_dim).size,
            lower=grid.lower_bounds[staggerloc][self.x_index],
            upper=grid.upper_bounds[staggerloc][self.x_index],
            staggerloc=staggerloc,
            coordinate_type="x",
        )
        y_dimobj = Dimension(
            name=y_dim,
            size=_get_nc_dimension_(nc_ds, y_dim).size,
            lower=grid.lower_bounds[staggerloc][self.y_index],
            upper=grid.upper_bounds[staggerloc][self.y_index],
            staggerloc=staggerloc,
            coordinate_type="y",
        )
        if self.x_index == 0:
            value = [x_dimobj, y_dimobj]
        elif self.x_index == 1:
            value = [y_dimobj, x_dimobj]
        else:
            raise NotImplementedError(self.x_index, self.y_index)
        return DimensionCollection(value=value)


class GridWrapper(AbstractWrapper):
    """Wraps an ``esmpy`` grid with dimension metadata."""

    value: esmpy.Grid
    spec: GridSpec
    corner_dims: Union[DimensionCollection, None] = None

    def fill_nc_variables(self, path: Path):
        """Fill netCDF variables using coordinate data from an ``esmpy`` grid."""
        if self.corner_dims is not None:
            raise NotImplementedError
        with open_nc(path, "a") as nc_ds:
            staggerloc = esmpy.StaggerLoc.CENTER
            x_center_data = self.spec.get_x_data(self.value, staggerloc)
            _set_variable_data_(nc_ds.variables[self.spec.x_center], self.dims, x_center_data)
            y_center_data = self.spec.get_y_data(self.value, staggerloc)
            _set_variable_data_(nc_ds.variables[self.spec.y_center], self.dims, y_center_data)


class FieldWrapper(AbstractWrapper):
    """Wraps an ``esmpy`` field with dimension metadata."""

    value: esmpy.Field
    gwrap: GridWrapper

    def fill_nc_variable(self, path: Path):
        """Fill the netCDF variable associated with the ``esmpy`` field."""
        with open_nc(path, "a") as nc_ds:
            var = nc_ds.variables[self.value.name]
            _set_variable_data_(var, self.dims, self.value.data)


HasNcAttrsType = Union[nc.Dataset, nc.Variable]


def _get_aliased_key_(source: Dict, keys: Union[NameListType, str]) -> Any:
    if isinstance(keys, str):
        keys_to_find = (keys,)
    else:
        keys_to_find = keys
    for key in keys_to_find:
        try:
            return source[key]
        except KeyError:
            continue
    raise ValueError(f"key not found: {keys}")


def _get_nc_dimension_(nc_ds: nc.Dataset, names: NameListType) -> nc.Dimension:
    return _get_aliased_key_(nc_ds.dimensions, names)


def _create_dimension_map_(dims: DimensionCollection) -> Dict[str, int]:
    ret = {}
    for idx, dim in enumerate(dims.value):
        for name in dim.name:
            ret[name] = idx
    return ret


def load_variable_data(var: nc.Variable, target_dims: DimensionCollection) -> np.ndarray:
    """
    Load variable data using bounds defined in the dimension collection.

    Args:
        var: netCDF variable to load data from.
        target_dims: Dimensions for the variable containing ``esmpy`` bounds.

    Returns:
        The loaded data array.
    """
    slices = [slice(target_dims.get(ii).lower, target_dims.get(ii).upper) for ii in var.dimensions]
    raw_data = var[*slices]
    dim_map = {dim: ii for ii, dim in enumerate(var.dimensions)}
    axes = [_get_aliased_key_(dim_map, ii.name) for ii in target_dims.value]
    transposed_data = raw_data.transpose(axes)
    return transposed_data


def _set_variable_data_(
    var: nc.Variable, target_dims: DimensionCollection, target_data: np.ndarray
) -> np.ndarray:
    dim_map = _create_dimension_map_(target_dims)
    axes = [_get_aliased_key_(dim_map, ii) for ii in var.dimensions]
    transposed_data = target_data.transpose(axes)
    slices = [slice(target_dims.get(ii).lower, target_dims.get(ii).upper) for ii in var.dimensions]
    var[*slices] = transposed_data
    return transposed_data


class NcToGrid(BaseModel):
    """Converts a netCDF file to an ``esmpy`` grid."""

    path: Path
    spec: GridSpec

    def create_grid_wrapper(self) -> GridWrapper:
        """Create a grid wrapper."""
        with open_nc(self.path, "r") as nc_ds:
            grid_shape = self._create_grid_shape_(nc_ds)
            staggerloc = esmpy.StaggerLoc.CENTER
            grid = esmpy.Grid(
                grid_shape,
                staggerloc=staggerloc,
                coord_sys=esmpy.CoordSys.SPH_DEG,
            )
            dims = self.spec.create_grid_dims(nc_ds, grid, staggerloc)
            grid_x_center_coords = self.spec.get_x_data(grid, staggerloc)
            grid_x_center_coords[:] = load_variable_data(
                nc_ds.variables[self.spec.x_center], dims  # pylint: disable=unsubscriptable-object
            )
            grid_y_center_coords = self.spec.get_y_data(grid, staggerloc)
            grid_y_center_coords[:] = load_variable_data(
                nc_ds.variables[self.spec.y_center], dims  # pylint: disable=unsubscriptable-object
            )

            if self.spec.has_corners:
                corner_dims = self._add_corner_coords_(nc_ds, grid)
            else:
                corner_dims = None

            gwrap = GridWrapper(value=grid, dims=dims, spec=self.spec, corner_dims=corner_dims)
            return gwrap

    def _create_grid_shape_(self, nc_ds: nc.Dataset) -> np.ndarray:
        x_size = _get_nc_dimension_(nc_ds, self.spec.x_dim).size
        y_size = _get_nc_dimension_(nc_ds, self.spec.y_dim).size
        if self.spec.x_index == 0:
            grid_shape = (x_size, y_size)
        elif self.spec.x_index == 1:
            grid_shape = (y_size, x_size)
        else:
            raise NotImplementedError(self.spec.x_index, self.spec.y_index)
        return np.array(grid_shape)

    def _add_corner_coords_(self, nc_ds: nc.Dataset, grid: esmpy.Grid) -> DimensionCollection:
        staggerloc = esmpy.StaggerLoc.CORNER
        grid.add_coords(staggerloc)
        dims = self.spec.create_grid_dims(nc_ds, grid, staggerloc)
        grid_x_corner_coords = self.spec.get_x_data(grid, staggerloc)
        grid_x_corner_coords[:] = load_variable_data(nc_ds.variables[self.spec.x_corner], dims)
        grid_y_corner_coords = self.spec.get_y_data(grid, staggerloc)
        grid_y_corner_coords[:] = load_variable_data(nc_ds.variables[self.spec.y_corner], dims)
        return dims


class NcToField(BaseModel):
    """Converts a netCDF file to an ``esmpy`` field."""

    path: Path
    name: str
    gwrap: GridWrapper
    dim_time: Union[NameListType, None] = None
    staggerloc: int = esmpy.StaggerLoc.CENTER

    def create_field_wrapper(self) -> FieldWrapper:
        """Create a field wrapper."""
        with open_nc(self.path, "r") as nc_ds:
            if self.dim_time is None:
                ndbounds = None
                target_dims = self.gwrap.dims
            else:
                ndbounds = (len(_get_nc_dimension_(nc_ds, self.dim_time)),)
                time_dim = Dimension(
                    name=self.dim_time,
                    size=ndbounds[0],
                    lower=0,
                    upper=ndbounds[0],
                    staggerloc=self.staggerloc,
                    coordinate_type="time",
                )
                target_dims = DimensionCollection(value=list(self.gwrap.dims.value) + [time_dim])
            field = esmpy.Field(
                self.gwrap.value,
                name=self.name,
                ndbounds=ndbounds,
                staggerloc=self.staggerloc,
            )
            field.data[:] = load_variable_data(
                nc_ds.variables[self.name], target_dims  # pylint: disable=unsubscriptable-object
            )
            fwrap = FieldWrapper(value=field, dims=target_dims, gwrap=self.gwrap)
            return fwrap


def mask_edges(data: np.ma.MaskedArray, mask_width: int = 1) -> None:
    """
    Mask edges of domain for interpolation.

    Args:
        data: The masked array to alter
        mask_width: The width of the mask at each edge

    Returns:
        A numpy array of the masked edges
    """
    if data.ndim != 2:
        raise ValueError(f"{data.ndim=}")

    original_shape = data.shape
    if mask_width < 1:
        return  # No masking if mask_width is less than 1

    target = data.mask
    if isinstance(target, np.bool_):
        data.mask = np.zeros_like(data, dtype=bool)
        target = data.mask
    # Mask top and bottom rows
    target[:mask_width, :] = True
    target[-mask_width:, :] = True

    # Mask left and right columns
    target[:, :mask_width] = True
    target[:, -mask_width:] = True

    if data.shape != original_shape:
        raise ValueError("Data shape altered during masking.")
