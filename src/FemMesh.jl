# This file is part of FemMesh package. See copyright license in https://github.com/NumSoftware/FemMesh

__precompile__()

"""
**FemMesh.jl**

FemMesh module implements functions and types related to mesh generation for
finite element analyses. 

**Important data types**

Block2D, Block3D, BlockTruss, BlockInset, Point, Cell, Face, Edge, Mesh.

**Important functions** 

copy, move!, array, rotate!, polar, extrude.

"""
module FemMesh
using Printf, StatsBase, Statistics, LinearAlgebra, SparseArrays, DelimitedFiles
using JSON, DataStructures

# Mesh module
include("tools/linalg.jl")
include("tools/expr.jl")
include("tools/show.jl")
include("tools/iteration.jl")
include("tools/table.jl")
include("tools/stopwatch.jl")
export unfold

# Generic exports
export getindex

include("vtk.jl")
include("quadrature.jl")

include("shape.jl")
export ShapeType, TagType, ALL_SHAPES, ShapeFamily
export get_ip_coords, get_shape_from_vtk
export inverse_map, extrapolator

include("point.jl")
export Point, Cell, hash, get_x, get_y, get_z
include("cell.jl")
export getcoords, get_point, get_points, get_faces, cell_extent, cell_quality
export tag!, iptag!, update!
include("partition.jl")

include("ugrid.jl")
export UnstructuredGrid, save_vtk, read_ugrid_vtk

include("mesh.jl")
export Mesh, update!, quality!, reorder!, save, get_surface, get_neighbors

include("block.jl")
export Block2D, Block3D, BlockTruss, BlockCoords, BlockCylinder

include("operators.jl")
export move!, array, copy, mirror, rotate!, polar, rollaxes!

include("extrude.jl") 
export extrude

include("smooth.jl") 
include("split.jl") 

include("embedded.jl") 
export generate_embedded_cells!

include("mplot.jl") 
export mplot

include("cplot.jl") 
export cplot

# show function for FemMesh types
for datatype in (:ShapeType, :Point, :Cell, :Block, :Mesh, :UnstructuredGrid )
    eval( quote
        function Base.show(io::IO, obj::$datatype)
            print_field_values(io, obj)
        end

        function Base.show(io::IO, array::Array{<:($datatype),1})
            print_array_values(io, array)
        end
    end )
end

end#module
