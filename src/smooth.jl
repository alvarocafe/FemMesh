# This file is part of FemMesh package. See copyright license in https://github.com/NumSoftware/FemMesh

# This file contains the code for smoothing meshes

export smooth!, laplacian_smooth!

# Returns a matrix with the cell coordinates
function cellcoords(c::Cell)
    ndim = c.shape.ndim
    C = Array{Float64}(undef, length(c.points), ndim)
    for (i,point) in enumerate(c.points)
        C[i,1] = point.x
        C[i,2] = point.y
        if ndim>2
            C[i,3] = point.z
        end
    end
    return C
end

# Basic coordinates are defined considering an area/volume equal to 1.0
# TODO: change to reference_coords
function basic_coords(shape::ShapeType) #check
    if shape == TRI3
        #return √2*[0.0 0; 1 0 ; 0 1]
        a = 2.0/3.0^0.25
        return [ 0.0 0.0; a 0.0; a/2.0 a/2*√3 ]
    end
    if shape == TRI6
        #return √2*[0.0 0; 1 0 ; 0 1; 0.5 0; 0.5 0.5; 0 0.5]
        a = 2.0/3.0^0.25
        h = a/2*√3
        return [ 0.0 0; a 0; a/2.0 a/2*√3; a/2.0 0; 0.75*a h/2.0; 0.25*a h/2.0 ]
    end
    if shape == QUAD4
        return [ 0.0 0.0; 1.0 0.0; 1.0 1.0 ; 0.0 1.0 ]
    end
    if shape == TET4
        a = (6.0*√2.0)^(1.0/3.0)
        return [   0.0        0.0          0.0 ; 
                   a         0.0          0.0 ;
                 a/2.0  √3.0/2.0*a          0.0 ;
                 a/2.0  √3.0/6.0*a  1.0/3.0*√6*a ]
    end
    if shape == QUAD8
        return [ 0.0 0; 1 0; 1 1 ; 0 1; 0.5 0; 1 0.5; 0.5 1; 0 0.5 ]
    end
    if shape == QUAD9
        return [ 0.0 0; 1 0; 1 1 ; 0 1; 0.5 0; 1 0.5; 0.5 1; 0 0.5; 0.5 0.5 ]
    end
    if shape == QUAD12
        return [ 0.0 0; 1 0; 1 1 ; 0 1; 
        1/3 0.0; 1.0 1/3; 2/3 1.0; 0.0 2/3;
        2/3 0.0; 1.0 2/3; 1/3 1.0; 0.0 1/3 ]
    end
    if shape == HEX8  
        return [ 0.0 0.0 0.0; 1.0 0.0 0.0; 1.0 1.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0; 1.0 0.0 1.0; 1.0 1.0 1.0; 0.0 1.0 1.0 ]
    end
    if shape == HEX20
        return [ 0.0 0.0 0.0; 
                 1.0 0.0 0.0;
                 1.0 1.0 0.0;
                 0.0 1.0 0.0;
                 0.0 0.0 1.0;
                 1.0 0.0 1.0;
                 1.0 1.0 1.0;
                 0.0 1.0 1.0;
                 0.5 0.0 0.0;
                 1.0 0.5 0.0;
                 0.5 1.0 0.0;
                 0.0 0.5 0.0;
                 0.5 0.0 1.0;
                 1.0 0.5 1.0;
                 0.5 1.0 1.0;
                 0.0 0.5 1.0;
                 0.0 0.0 0.5;
                 1.0 0.0 0.5;
                 1.0 1.0 0.5;
                 0.0 1.0 0.5 ]
    end
    if shape == WED6
        a = (4.0/√3.0)^(1.0/3.0)
        return [ 0.0  0.0  0.0; a  0.0  0.0; a/2.0  a/2*√3  0.0 ;
                 0.0  0.0   a; a  0.0   a; a/2.0  a/2*√3   a ]
    end
    if shape == WED15
        a = (4.0/√3.0)^(1.0/3.0)
        b = a/2*√3
        return [   0  0    0; a        0     0; a/2    b    0;
                   0  0    a; a        0     a; a/2    b    a;
                 a/2  0    0; a*3/4  b/2     0; a/4  b/2    0;
                 a/2  0    a; a*3/4  b/2     a; a/4  b/2    a;
                   0  0  a/2; a        0   a/2; a/2    b  a/2 ]
    end

    error("No basic coordinates for shape $(shape.name)")
end

# Returns a rotation matrix for a cell based in their first points
function cell_orientation(cell::Cell)
    shape   = cell.shape
    geo_dim = shape.ndim

    if geo_dim == 2
        p1 = cell.points[1]
        p2 = cell.points[2]

        l1 = p2.x - p1.x
        m1 = p2.y - p1.y
        T1 = [l1, m1]
        l1, m1 = T1/norm(T1)
        return [ l1  -m1; m1  l1 ]
    end

    if geo_dim == 3
        p1 = cell.points[1]
        p2 = cell.points[2]
        if shape == HEX8 || shape == HEX20
            p3 = cell.points[4]
        else
            p3 = cell.points[3]
        end

        T1 = [ p2.x - p1.x, p2.y - p1.y, p2.z - p1.z ]
        T2 = [ p3.x - p1.x, p3.y - p1.y, p3.z - p1.z ]
        T3 = cross(T1, T2)
        T2 = cross(T3, T1) # redefine T2

        T1 = T1/norm(T1)
        T2 = T2/norm(T2)
        T3 = T3/norm(T3)

        return [T1 T2 T3]

    end
    error("cell_orientation: Not implemented for shape ", cell.shape)
end


# Matrix D for the simplified FEM analysis
function matrixD(E::Float64, nu::Float64)
    c = E/((1.0+nu)*(1.0-2.0*nu))
    [ c*(1.0-nu)      c*nu        c*nu             0.0             0.0             0.0
          c*nu   c*(1.0-nu)       c*nu             0.0             0.0             0.0
          c*nu       c*nu    c*(1.0-nu)            0.0             0.0             0.0
           0.0        0.0         0.0   c*(1.0-2.0*nu)            0.0             0.0
           0.0        0.0         0.0             0.0   c*(1.0-2.0*nu)            0.0
           0.0        0.0         0.0             0.0             0.0   c*(1.0-2.0*nu) ]
end


#include("../tools/linalg.jl")

# Matrix B for the simplified FEM analysis
function matrixB(ndim::Int, dNdX::Matx, detJ::Float64, B::Matx)
    nnodes = size(dNdX,2)
    sqr2 = √2.0
    B .= 0.0
    if ndim==2
        for i in 1:nnodes
            j = i-1
            B[1,1+j*ndim] = dNdX[1,i]
            B[2,2+j*ndim] = dNdX[2,i]
            B[4,1+j*ndim] = dNdX[2,i]/sqr2; B[4,2+j*ndim] = dNdX[1,i]/sqr2
        end
    else
        for i in 1:nnodes
            dNdx = dNdX[1,i]
            dNdy = dNdX[2,i]
            dNdz = dNdX[3,i]
            j    = i-1
            B[1,1+j*ndim] = dNdx
            B[2,2+j*ndim] = dNdy
            B[3,3+j*ndim] = dNdz
            B[4,1+j*ndim] = dNdy/sqr2;   B[4,2+j*ndim] = dNdx/sqr2
            B[5,2+j*ndim] = dNdz/sqr2;   B[5,3+j*ndim] = dNdy/sqr2
            B[6,1+j*ndim] = dNdz/sqr2;   B[6,3+j*ndim] = dNdx/sqr2
        end
    end

    return detJ
end

function matrixK(cell::Cell, ndim::Int64, E::Float64, nu::Float64)
    nnodes = length(cell.points)

    C = cellcoords(cell)
    K = zeros(nnodes*ndim, nnodes*ndim)
    B = zeros(6, nnodes*ndim)

    DB = Array{Float64}(undef, 6, nnodes*ndim)
    J  = Array{Float64}(undef, ndim, ndim)
    dNdX = Array{Float64}(undef, ndim, nnodes)

    IP = get_ip_coords(cell.shape)
    D = matrixD(E, nu)

    for i=1:size(IP,1)
        R    = vec(IP[i,1:3])
        w    = IP[i,4]

        # compute B matrix
        dNdR = cell.shape.deriv(R)
        @gemm J = dNdR*C
        @gemm dNdX = inv(J)*dNdR
        detJ = det(J)
        if detJ < 0.0 
            @error "Negative jacobian determinant in cell" cell=cell.id ip=i coords=C
            error()
        end
        matrixB(ndim, dNdX, detJ, B)

        # compute K
        coef = detJ*w
        @gemm DB = D*B
        @gemm K += coef*B'*DB
    end
    return K
end

function matrixK2(cell::Cell, ndim::Int64, E::Float64, nu::Float64)
    nnodes = length(cell.points)

    C = cellcoords(cell)
    K = zeros(nnodes*ndim, nnodes*ndim)
    B = zeros(6, nnodes*ndim)
    DB = Array{Float64}(undef, 6, nnodes*ndim)

    IP = get_ip_coords(cell.shape)

    D = matrixD(E, nu)
    for i=1:size(IP,1)
        R    = vec(IP[i,1:3])
        w    = IP[i,4]
        detJ = matrixB(cell, ndim, R, C, B)

        @gemm DB = D*B
        coef = detJ*w
        @gemm K += coef*B'*DB
        #K   += B'*D*B*detJ*w
    end
    return K
end

function get_map(c::Cell)
    ndim = c.shape.ndim
    
    map = Int[]
    for p in c.points
        for i=1:ndim
            push!(map, (p.id-1)*ndim + i)
        end
    end

    return map
end

# Mount global stiffness matrix
function mountKg(mesh::Mesh, E::Float64, nu::Float64, A::Array{Float64,2})
    ndim = mesh.ndim
    ndof = ndim*length(mesh.points)
    R, C, V = Int64[], Int64[], Float64[]

    for c in mesh.cells
        Ke  = matrixK(c, ndim, E, nu)
        map = get_map(c)
        nr, nc = size(Ke)
        for i=1:nr
            for j=1:nc
                push!(R, map[i])
                push!(C, map[j])
                push!(V, Ke[i,j])
            end
        end
    end

    # mount A and A'
    nbc = size(A,1)
    for i = 1:nbc
        for j = 1:ndof
            val = A[i,j]
            if val==0.0
                continue
            end
            push!(R, ndof+i)
            push!(C, j)
            push!(V, val)
            push!(R, j)
            push!(C, ndof+i)
            push!(V, val)
        end
    end
    
    return sparse(R, C, V, ndof+nbc, ndof+nbc)
end

# Check if an array of faces are coplanar
# Returns the normal unitary vector of a face
# If the face is not flat returns [0,0,0]
function normal_to_faces(faces::Array{Cell, 1})
    ndim = 1 + faces[1].shape.ndim
    points = Point[]

    for f in faces
        for p in f.points
            push!(points, p)
        end
    end

    # mount coordinates matrix
    C = Array{Float64}(undef, length(points), ndim)
    for (i,p) in enumerate(points)
        C[i,1] = p.x
        C[i,2] = p.y
        if ndim>2
            C[i,3] = p.z
        end
    end

    C += 1.e-5
    I = ones(size(C,1))
    N = pinv(C)*I # best fit normal

    if norm(C*N - I)<1e-5
        return N/norm(N)
    end

    return zeros(ndim)
end


function faces_normal(faces::Array{Cell,1}, facetol)
    ndim = 1 + faces[1].shape.ndim
    
    #normals = Set{Array{Float64,1}}()
    normals = Array{Float64,1}[]

    for f in faces

        C = getcoords(f, ndim)

        # move the coordinates to avoid singular case
        # when the regression line/planes crosses the origin
        if ndim==2
            C .+= [pi pi^1.1]
        else
            C .+= [pi pi^1.1 pi^1.2]
        end

        I = ones(size(C,1))
        N = pinv(C)*I # best fit normal

        #if norm(C*N - I) < facetol
            #N = N/norm(N)
            normalize!(N)
            #check if the normal already exists
            if all( [ norm(N-NN)>facetol for NN in normals ]) 
                push!(normals, N)
            end
        #else
            #return Array{Float64,1}[]
        #end
    end

    return normals 
end

# Auxiliary structure
mutable struct sNode
    point::Point
    faces::Array{Cell}
    normals
end

# Mount global matrix A
function mountA(mesh::Mesh, fixed::Bool, conds, facetol)
    # get border faces
    ndim = mesh.ndim
    border_fcs = get_surface(mesh.cells)

    # get all points from surface including a list of faces per point
    nodesd = Dict{UInt64, sNode}()
    for cell in border_fcs
        for point in cell.points
            hk = hash(point)
            if !haskey(nodesd, hk)
                nodesd[hk] = sNode(point, Cell[cell], nothing)
            else
                push!(nodesd[hk].faces, cell)
            end
        end
    end
    border_nodes = [ values(nodesd)... ]


    local fconds=Function[]
    if conds!= nothing
        for c in conds
            ff = quote
                (x,y,z) -> ($c)
            end
            push!(fconds, eval(ff))
        end
    end

    # find the number of bcs
    n = 0  # number of bcs 
    for node in border_nodes
        if conds!= nothing
            p = node.point
            if any( Bool[ ff(p.x, p.y, p.z) for ff in fconds ] )
                node.normals = Array{Float64,1}[]
                n += ndim
                continue
            end
        end

        node.normals = faces_normal(node.faces, facetol)
        nnorm        = length(node.normals)
        if nnorm==1 || nnorm==2
            n += nnorm
        else
            n += ndim
        end
    end


    #  for fixed boundary
    if fixed
        n = length(border_nodes)
        A = zeros(n*ndim, length(mesh.points)*ndim)

        for i=1:n
            for j=1:ndim 
                A[ (i-1)*ndim+j, (border_nodes[i].point.id-1)*ndim+j ] = 1.0
            end
        end
    else
        # mount matrix A (Lagrange multipliers) according to bcs
        A = zeros(n, length(mesh.points)*ndim)

        baserow = 0
        for node in border_nodes
            basecol = (node.point.id-1)*ndim
            normals = node.normals
            nnorm   = length(normals)

            if nnorm==1 || nnorm==2  # all faces in up to 2 planes
                for i=1:nnorm
                    for j=1:ndim 
                        A[ baserow+1, basecol+j ] = normals[i][j]
                    end
                    baserow += 1
                end
            else # zero or more than two non coplanar faces
                for j=1:ndim 
                    A[ baserow+j, basecol+j ] = 1.0
                end
                baserow += ndim
            end

        end

    end

    return A
end



function rigid_transform(source::Array{Float64,2}, target::Array{Float64,2})
    A, B = copy(source), copy(target)
    #@test size(A) == size(B)

    n = size(A,1)
    ndim = size(A,2)

    # Centralizing both sets of points
    cA = mean(A, dims=1)
    cB = mean(B, dims=1)
    for i = 1:n
        for j = 1:ndim
            A[i,j] -= cA[1,j]
            B[i,j] -= cB[1,j]
        end
    end

    # Singular value decomposition
    U, S, V = svd(A'*B)

    # Rotation matrix
    R = V*U'

    # special reflection case
    if det(R) < 0.0
       #println("Reflection detected")
       R[:2] *= -1
    end

    T = cB - cA*R'

    return R, T

end


# Mount a vector with nodal forces
function force_bc(mesh::Mesh, E::Float64, nu::Float64, α::Float64, extended::Bool)
    n    = length(mesh.points)
    ndim = mesh.ndim
    Fbc  = zeros(n*ndim)

    for c in mesh.cells
        # get coordinates matrix
        np = length(c.points)
        C0 = cellcoords(c)
        V  = cell_extent(c) # area or volume

        #extended || (V = α*V)

        R0 = cell_orientation(c)
        s = V^(1.0/ndim) # scale factor

        extended && (s *= α)

        BC = basic_coords(c.shape)*s

        # initial alignment
        #C = BC*R0'
        C = BC

        # align C with cell orientation
        R, d = rigid_transform(C, C0)
        D = repeat( d , np, 1)
        C1 = C*R' + D
        U  = C1 - C0  # displacements matrix

        U  = vec(U')  # displacements vector

        K = matrixK(c, ndim, E, nu)

        if extended
            if mesh.qmin<1.0
                F = K*U*((1-c.quality)/(1-mesh.qmin))
            else
                F = zeros(length(U))
            end
        else
            F = K*U
        end

        # add forces to Fbc
        for (i,point) in enumerate(c.points)
            pid = point.id
            for j = 1:ndim
                Fbc[(pid-1)*ndim+j] += F[(i-1)*ndim+j]
            end
        end
    end

    return Fbc
end

function smooth!(mesh::Mesh; verbose=true, alpha::Float64=1.0, target::Float64=0.97, 
                 fixed::Bool=false, maxit::Int64=30, mintol::Float64=1e-3, tol::Float64=1e-4, 
                 facetol=1e-4, savesteps::Bool=false, savedata::Bool=false, filekey::String="smooth",
                 conds=nothing, extended=false)

    # tol   : tolerance in change of mesh quality for succesive iterations
    # mintol: tolerance in change of worst cell quality in a mesh for succesive iterations

    verbose && printstyled("Mesh smoothing:\n", bold=true, color=:cyan)

    # check for not allowed cells
    for c in mesh.cells
        if c.shape.family != SOLID_SHAPE
            error("smooth!: cells of family $(c.shape.family) are not allowed for smoothing: $(c.shape.name)")
        end
    end

    # Elastic constants
    E  = 1.0
    nu = 0.0

    ndim = mesh.ndim
    npoints = length(mesh.points)
    #quality!(mesh)


    # Stats
    Q = Float64[ c.quality for c in mesh.cells]
    q    = mesh.quality
    qmin = minimum(Q)
    qmax = maximum(Q)
    dev  = stdm(Q, q) 
    q1, q2, q3 = quantile(Q, [0.25, 0.5, 0.75])

    stats = DTable()
    hists = DTable()
    push!(stats, OrderedDict(:qavg=>q, :qmin=>qmin, :qmax=>qmax, :dev=>dev))

    hist  = fit(Histogram, Q, 0.0:0.05:1.0, closed=:right).weights
    push!(hists, OrderedDict(Symbol(r) => v for (r,v) in zip(0.0:0.05:0.95,hist)))

    verbose && @printf("%4s  %5s  %5s  %5s  %5s  %5s  %5s  %7s  %9s  %10s\n", "it", "qmin", "q1", "q2", "q3", "qmax", "qavg", "sdev", "time", "histogram (0.3, 1.0]")
    verbose && @printf("%4d  %5.3f  %5.3f  %5.3f  %5.3f  %5.3f  %5.3f  %7.5f  %9s", 0, qmin, q1, q2, q3, qmax, q, dev, "-")
    verbose && println("  ", fit(Histogram, Q, 0.3:0.05:1.0, closed=:right).weights)

    # Lagrange multipliers matrix
    A   = mountA(mesh, fixed, conds, facetol) 
    nbc = size(A,1)

    nits = 0
    t0 = time()

    for i=1:maxit

        #if i>2; extended=true end
        sw = StopWatch()

        # Forces vector needed for smoothing
        F   = force_bc(mesh, E, nu, alpha, extended)

        if ndim==2
            mesh.point_vector_data["forces"] = [ reshape(F, ndim, npoints)' zeros(npoints)]
        else
            mesh.point_vector_data["forces"] = reshape(F, ndim, npoints)'
        end

        # Save last step file with current forces
        savesteps && save(mesh, "$filekey-$(i-1).vtk", verbose=false)

        # Augmented forces vector
        F   = vcat( F, zeros(nbc) )

        # global stiffness plus LM
        K = mountKg(mesh, E, nu, A)

        # Solve system
        LUf = lu(K)
        U = LUf\F

        # Update mesh
        for p in mesh.points
            p.x += U[(p.id-1)*ndim+1]
            p.y += U[(p.id-1)*ndim+2]
            if ndim>2
                p.z += U[(p.id-1)*ndim+3]
            end
        end

        for c in mesh.cells
            update!(c)
        end

        Q = Float64[ c.quality for c in mesh.cells]
        mesh.quality = mean(Q)
        mesh.qmin    = minimum(Q)
        savesteps && save(mesh, "$filekey-$i.vtk", verbose=false)

        if any(Q .== 0.0)
            error("smooth!: Smooth procedure got invalid element(s). Try using alpha<1.")
        end

        Δq    = abs(q - mesh.quality)
        Δqmin = mesh.qmin - qmin

        q    = mesh.quality
        qmin = mesh.qmin
        qmax = maximum(Q)
        dev  = stdm(Q, q)
        q1, q2, q3 = quantile(Q, [0.25, 0.5, 0.75])

        push!(stats, OrderedDict(:qavg=>q, :qmin=>qmin, :qmax=>qmax, :dev=>dev))

        hist = fit(Histogram, Q, 0.0:0.05:1.0, closed=:right).weights
        push!(hists, OrderedDict(Symbol(r) => v for (r,v) in zip(0.0:0.05:0.95,hist)))

        verbose && @printf("%4d  %5.3f  %5.3f  %5.3f  %5.3f  %5.3f  %5.3f  %7.5f  %9s", 0, qmin, q1, q2, q3, qmax, q, dev, hms(sw, format=:ms))
        #verbose && @printf("%4d  %5.3f  %5.3f  %5.3f  %7.5f  %9s", i, qmin, qmax, q, dev, hms(sw, format=:ms))
        verbose && println("  ", fit(Histogram, Q, 0.3:0.05:1.0, closed=:right).weights)
        #verbose && @printf("  it: %2d  q-range: %5.3f…%5.3f  qavg: %5.3f  dev: %7.5f", i, qmin, qmax, q, dev)
        #verbose && println("  hist: ", fit(Histogram, Q, 0.5:0.05:1.0, closed=:right).weights)

        #Δqmin<0.0 && break

        if Δq<tol && Δqmin<mintol && i>1
            break
        end

        nits = i
    end
    # Set forces to zero for the last step
    mesh.point_vector_data["forces"] = zeros(length(mesh.points), 3)
    savesteps && save(mesh, "$filekey-$nits.vtk", verbose=false)

    savedata && save(stats, "$filekey-stats.dat")
    savedata && save(hists, "$filekey-hists.dat")
    verbose && println("  done.")

    return nothing
end

precompile(smooth!, (Mesh,) )

function laplacian_smooth!(mesh::Mesh; alpha::Float64=1.0, maxit::Int64=20, verbose::Bool=true, mintol::Float64=1e-3,
    tol::Float64=1e-4, facetol::Float64=1e-5, savesteps::Bool=false, savedata::Bool=false, filekey::String="smooth", extended=true)

    verbose && printstyled("Mesh Laplacian smoothing:\n", bold=true, color=:cyan)

    #!extended && (alpha=1.0)

    ndim = mesh.ndim

    # find element shares
    C = get_patches(mesh)
    P = Array{Point,1}[]

    # remove key nodes from list
    for point in mesh.points
        cells  = C[point.id]
        points = get_points(cells)
        idx = findfirst( p -> hash(p) == hash(point), points)
        splice!(points, idx)
        push!(P, points)
    end

    # get all points from surface including a list of faces per point
    border_fcs = get_surface(mesh.cells)
    nodesd     = Dict{UInt64, sNode}()
    for cell in border_fcs
        for point in cell.points
            hk = hash(point)
            if !haskey(nodesd, hk)
                nodesd[hk] = sNode(point, Cell[cell], nothing)
            else
                push!(nodesd[hk].faces, cell)
            end
        end
    end

    border_nodes = [ values(nodesd)... ]


    # find normals for nodes
    for node in border_nodes
        node.normals = faces_normal(node.faces, facetol)
    end

    # arrays of flags
    in_border = falses(length(mesh.points))
    border_idxs = [ n.point.id for n in border_nodes ]
    in_border[border_idxs] .= true

    map_pn = zeros(Int, length(mesh.points)) # map point-node
    for (i,node) in enumerate(border_nodes)
        map_pn[ node.point.id ] = i
    end

    #quality!(mesh)
    savesteps && save(mesh, "$filekey-0.vtk", verbose=false)

    # stats
    Q    = Float64[ c.quality for c in mesh.cells]
    q    = mesh.quality
    qmin = minimum(Q)
    qmax = maximum(Q)
    dev  = stdm(Q, q)

    stats = DTable()
    hists = DTable()
    push!(stats, OrderedDict(:qavg=>q, :qmin=>qmin, :qmax=>qmax, :dev=>dev))

    hist  = fit(Histogram, Q, 0.0:0.05:1.0, closed=:right).weights
    push!(hists, OrderedDict(Symbol(r) => v for (r,v) in zip(0.0:0.05:0.95,hist)))

    #verbose && @printf("  it: %2d  qmin: %7.5f  qavg: %7.5f  dev: %7.5f", 0, qmin, q, dev)
    verbose && @printf("  it: %2d  q-range: %5.3f…%5.3f  qavg: %5.3f  dev: %7.5f", 0, qmin, qmax, q, dev)
    verbose && println("  hist: ", fit(Histogram, Q, 0.5:0.05:1.0, closed=:right).weights)

    # find center point and update point position
    for i=1:maxit
        for point in mesh.points
            id = point.id
            X0 = [point.x, point.y, point.z][1:ndim]
            if in_border[id] 
                node = border_nodes[ map_pn[id] ]
                normals = node.normals
                nnorm   = length(normals)
                (nnorm == 1 && ndim==2) || (nnorm in (1,2) && ndim==3) || continue
                X  = vec(mean(getcoords(P[id],ndim),dims=1))
                ΔX = alpha*(X - X0)
                X = X0 + ΔX
                if nnorm==1
                    n1 = normals[1]
                    X = X - dot(ΔX,n1)*n1 # projection to surface plane
                else
                    n3 = cross(normals[1], normals[2])
                    X = X0 + dot(ΔX,n3)*n3 # projection to surface edge
                end

            else
                X  = mean(getcoords(P[id]),dims=1)[1:ndim]
                ΔX = (X - X0)*alpha
            end

            if ndim==2
                point.x, point.y = X
            else
                point.x, point.y, point.z = X
            end
        end

        for c in mesh.cells
            update!(c)
        end

        Q = Float64[ c.quality for c in mesh.cells]
        mesh.quality = sum(Q)/length(mesh.cells)
        mesh.qmin    = minimum(Q)
        savesteps && save(mesh, "$filekey-$i.vtk", verbose=false)

        if any(Q .== 0.0)
            error("smooth!: Smooth procedure got invalid element(s). Try using alpha<1.")
        end

        temp  = minimum(Q)
        Δq    = abs(q - mesh.quality)
        Δqmin = qmin - temp

        q    = mesh.quality
        qmin = temp
        qmax = maximum(Q)
        dev  = stdm(Q, q)

        push!(stats, OrderedDict(:qavg=>q, :qmin=>qmin, :qmax=>qmax, :dev=>dev))

        hist = fit(Histogram, Q, 0.0:0.05:1.0, closed=:right).weights
        push!(hists, OrderedDict(Symbol(r) => v for (r,v) in zip(0.0:0.05:0.95,hist)))

        #verbose && @printf("  it: %2d  qmin: %7.5f  qavg: %7.5f  dev: %7.5f", i, qmin, q, dev)
        verbose && @printf("  it: %2d  q-range: %5.3f…%5.3f  qavg: %5.3f  dev: %7.5f", i, qmin, qmax, q, dev)
        verbose && println("  hist: ", fit(Histogram, Q, 0.5:0.05:1.0, closed=:right).weights)

        #Δqmin<0.0 && break

        if Δq<tol && Δqmin<mintol && i>2
            break
        end
    end

    savedata && save(stats, "$filekey-stats.dat")
    savedata && save(hists, "$filekey-hists.dat")
    verbose && println("  done.")

    return nothing
    
end
