#include <stdio.h>
#include "clipper.engine.h"
#include "clipper.offset.h"

#ifdef _WIN32
	#define EXPORT extern "C" __declspec(dllexport)
#else
	#define EXPORT extern "C" __attribute__((visibility("default")))
#endif

const double PRECISION = 3.0;
const double SCALE_LEN = pow(10, PRECISION);

using namespace Clipper2Lib;

std::string err_msg;

EXPORT const char *version() {
    return "1.0.0";
}

EXPORT const char *err_val() {
    return err_msg.c_str();
}

// PATH
EXPORT PathD *NewPath() {
    return new PathD();
}

EXPORT void PathFree(PathD *path) {
    delete path;
}

EXPORT bool PathAdd(PathD *path, double x, double y) {
    try {
        path->push_back(PointD(x, y));
    } catch (Clipper2Exception &e) {
        err_msg = e.what();
        return false;
    }
    return true;
}

EXPORT size_t PathLen(PathD *path) {
    return path->size();
}

EXPORT PointD *PathGet(PathD *path, int i) {
    return &((*path)[i]);
}

// PATHS
EXPORT PathsD *NewPaths() {
    return new PathsD();
}

EXPORT void PathsFree(PathsD *paths) {
    delete paths;
}

EXPORT bool PathsAdd(PathsD *paths, PathD *path) {
    try {
        paths->push_back(*path);
    } catch (Clipper2Exception &e) {
        err_msg = e.what();
        return false;
    }
    return true;
}

EXPORT size_t PathsLen(PathsD *paths) {
    return paths->size();
}

EXPORT PathD *PathsGet(PathsD *paths, int i) {
    return &((*paths)[i]);
}

// CLIPPER
EXPORT ClipperD *NewClipper() {
    return new ClipperD(PRECISION);
}

EXPORT void ClipperFree(ClipperD *clip) {
    delete clip;
}

EXPORT bool ClipperAddPaths(ClipperD *clip, PathsD *sbj, PathsD *clp) {
    try {
        clip->AddSubject(*sbj);
        clip->AddClip(*clp);
    } catch (Clipper2Exception &e) {
		err_msg = e.what();
		return false;
    };
    return true;
}

EXPORT PathsD *ClipperExecute(ClipperD *clip, ClipType clip_type, FillRule fill_rule) {
    PathsD *solution = new PathsD();
    try {
        clip->Execute(clip_type, fill_rule, *solution);
    } catch (Clipper2Exception &e) {
        delete solution;
		err_msg = e.what();
        return NULL;
    };
    return solution;
}

// CLIPPER OFFSET
EXPORT ClipperOffset *NewClipperOffset(double miter_limit, double arc_tolerance, bool preserve_collinear, bool reverse_solution) {
    return new ClipperOffset(miter_limit, arc_tolerance, preserve_collinear, reverse_solution);
}

EXPORT void ClipperOffsetFree(ClipperOffset *clip_offset) {
    delete clip_offset;
}

EXPORT bool ClipperOffsetAddPaths(ClipperOffset *clip_offset, PathsD *paths, JoinType jt, EndType et) {
    try {
        clip_offset->AddPaths(ScalePaths<int64_t, double>(*paths, SCALE_LEN), jt, et);
    } catch (Clipper2Exception &e) {
        err_msg = e.what();
        return false;
    }
    return true;
}

EXPORT PathsD *ClipperOffsetExecute(ClipperOffset *clip_offset, double delta) {
    Paths64 solution;
    try {
        solution = clip_offset->Execute(delta * SCALE_LEN);
    } catch (Clipper2Exception &e) {
        err_msg = e.what();
        return NULL;
    }
    return new PathsD(ScalePaths<double, int64_t>(solution, 1 / SCALE_LEN));
}