ffi = require "ffi"

import C, cdef, gc, metatype from ffi
has_loaded, pc = pcall require("requireffi.requireffi"), "zpclipper.clipper.clipper"

cdef [[
    const char *version();
    const char *err_val();

    typedef struct {double x, y;} PointD;
    typedef struct PathD PathD;
    typedef struct PathsD PathsD;
    typedef struct ClipperD ClipperD;
    typedef struct ClipperOffset ClipperOffset;

    // Path
    PathD *NewPath();
    void PathFree(PathD *path);
    bool PathAdd(PathD *path, double x, double y);
    size_t PathLen(PathD *path);
    PointD *PathGet(PathD *path, int i);

    // Paths
    PathsD *NewPaths();
    void PathsFree(PathsD *paths);
    bool PathsAdd(PathsD *paths, PathD *path);
    size_t PathsLen(PathsD *paths);
    PathD *PathsGet(PathsD *paths, int i);

    // Clipper
    ClipperD *NewClipper();
    void ClipperFree(ClipperD *clip);
    bool ClipperAddPaths(ClipperD *clip, PathsD *sbj, PathsD *clp);
    PathsD *ClipperExecute(ClipperD *clip, int clip_type, int fill_rule);

    // Clipper Offset
    ClipperOffset *NewClipperOffset(double miter_limit, double arc_tolerance, bool preserve_collinear, bool reverse_solution);
    void ClipperOffsetFree(ClipperOffset *clip_offset);
    bool ClipperOffsetAddPaths(ClipperOffset *clip_offset, PathsD *paths, int jt, int et);
    PathsD *ClipperOffsetExecute(ClipperOffset *clip_offset, double delta);
]]

view_version = -> ffi.string pc.version!
view_error = -> ffi.string pc.err_val!

-- enums
ClipType = {none: 0, intersection: 1, union: 2, difference: 3, xor: 4}
FillRule = {even_odd: 0, non_zero: 1, positive: 2, negative: 3}
JoinType = {square: 0, round: 1, miter: 2}
EndType  = {polygon: 0, joined: 1, butt: 2, square: 3, round: 4}

-- lib
CPP = {path: {}, paths: {}, offset: {}, clipper: {}}

-- Path
CPP.path.new = -> gc pc.NewPath!, pc.PathFree
CPP.path.add = (@, x, y) -> assert pc.PathAdd(@, x, y), view_error!
CPP.path.len = (@) -> tonumber pc.PathLen @
CPP.path.get = (@, i = 1) -> pc.PathGet @, i < 1 and 0 or i - 1

-- Paths
CPP.paths.new = -> gc pc.NewPaths!, pc.PathsFree
CPP.paths.add = (@, path) -> assert pc.PathsAdd(@, path), view_error!
CPP.paths.len = (@) -> tonumber pc.PathsLen @
CPP.paths.get = (@, i = 1) -> pc.PathsGet @, i < 1 and 0 or i - 1

-- Clipper
CPP.clipper.new = -> gc pc.NewClipper!, pc.ClipperFree
CPP.clipper.add_paths = (@, sbj, clp) -> assert pc.ClipperAddPaths(@, sbj, clp), view_error!
CPP.clipper.execute = (@, clip_type = 0, fill_rule = 1) ->
    -- defines ClipType
    if type(clip_type) == "string"
        clip_type = ClipType[clip_type]
        assert(clip_type, "ClipType undefined")
    -- defines FillRule
    if type(fill_rule) == "string"
        fill_rule = FillRule[fill_rule]
        assert(fill_rule, "FillRule undefined")
    solution = pc.ClipperExecute @, clip_type, fill_rule
    assert solution != nil, view_error!
    return gc solution, pc.PathsFree

-- Clipper Offset
CPP.offset.new = (miter_limit = 2, arc_tolerance = 0, preserve_collinear = false, reverse_solution = false) -> gc pc.NewClipperOffset(miter_limit, arc_tolerance, preserve_collinear, reverse_solution), pc.ClipperOffsetFree
CPP.offset.add_paths = (@, paths, join_type = 0, end_type = 0) ->
    -- defines JoinType
    if type(join_type) == "string"
        join_type = JoinType[join_type]
        assert(join_type, "JoinType undefined")
    -- defines EndType
    if type(end_type) == "string"
        end_type = EndType[end_type]
        assert(end_type, "EndType undefined")
    assert pc.ClipperOffsetAddPaths(@, paths, join_type, end_type), view_error!
CPP.offset.execute = (@, delta) ->
    solution = pc.ClipperOffsetExecute @, delta
    assert solution != nil, view_error!
    return gc solution, pc.PathsFree

metatype "PathD",          {__index: CPP.path}
metatype "PathsD",         {__index: CPP.paths}
metatype "ClipperD",       {__index: CPP.clipper}
metatype "ClipperOffset",  {__index: CPP.offset}

{:CPP, :has_loaded, version: view_version!}