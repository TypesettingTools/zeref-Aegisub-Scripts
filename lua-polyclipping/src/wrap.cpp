// Copyright (c) 2017 Laurent Zubiaur && 2022 Ruan Dias
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#include <stdio.h>
#include "clipper.hpp"

using namespace ClipperLib;

#ifdef _WIN32
	#define export extern "C" __declspec(dllexport)
#else
	#define export extern "C" __attribute__((visibility("default")))
#endif

std::string err_msg;

export const char *error_val()
{
	return err_msg.c_str();
}

// Section Path
export Path *path_new()
{
	return new Path();
}

export void path_free(Path *path)
{
	delete path;
}

export IntPoint *path_get(Path *path, int i)
{
	return &((*path)[i]);
}

export bool path_add(Path *path, cInt x, cInt y)
{
    try
    {
        path->push_back(IntPoint(x, y));
        return true;
    }
    catch (...)
    {
        return false;
    }
}

export int path_size(Path *path)
{
	return path->size();
}

export bool path_orientation(const Path *path)
{
	return Orientation(*path);
}

export double path_area(const Path *path)
{
	return Area(*path);
}

export void path_reverse(Path *path)
{
	ReversePath(*path);
}

export int path_point_in_polygon(const Path *path, cInt x, cInt y)
{
	return PointInPolygon(IntPoint(x, y), *path);
}

export Paths *path_simplify(const Path *path, int fillType)
{
	Paths *out = new Paths();
	SimplifyPolygon(*path, *out, PolyFillType(fillType));
	return out;
}

export Path *path_clean_polygon(const Path *path, double distance = 1.415)
{
	Path *out = new Path();
	CleanPolygon(*path, *out, distance);
	return out;
}

// Section Paths
export Paths *paths_new()
{
	return new Paths();
}

export void paths_free(Paths *paths)
{
	delete paths;
}

export Path *paths_get(Paths *paths, int i)
{
	return &((*paths)[i]);
}

export bool paths_add(Paths *paths, Path *path)
{
	try
	{
		paths->push_back(*path);
		return true;
	}
	catch (...)
	{
		return false;
	}
}

export int paths_size(Paths *paths)
{
	return paths->size();
}

export void paths_reverse(Paths *paths)
{
	ReversePaths(*paths);
}

export Paths *paths_simplify(Paths *paths, int fillType)
{
	try
	{
		Paths *out = new Paths();
		SimplifyPolygons(*paths, *out, PolyFillType(fillType));
		return out;
	}
	catch (...)
	{
		return 0;
	}
}

export Paths *paths_clean_polygon(Paths *paths, double distance)
{
	try
	{
		Paths *out = new Paths(paths->size());
		CleanPolygons(*paths, *out, distance);
		return out;
	}
	catch (...)
	{
		return 0;
	}
}

// Section ClipperOffset
export ClipperOffset *offset_new(double miterLimit, double roundPrecision)
{
	return new ClipperOffset(miterLimit, roundPrecision);
}

export void offset_free(ClipperOffset *CPO)
{
	delete CPO;
}

export Paths *offset_path(ClipperOffset *CPO, Path *subj, double delta, int joinType, int endType)
{
	Paths *solution = new Paths();
	try
	{
		CPO->AddPath(*subj, JoinType(joinType), EndType(endType));
		CPO->Execute(*solution, delta);
	}
	catch (clipperException &e)
	{
		err_msg = e.what();
		delete solution;
		return NULL;
	}
	return solution;
}

export Paths *offset_paths(ClipperOffset *CPO, Paths *subj, double delta, JoinType joinType, int endType)
{
	Paths *solution = new Paths();
	try
	{
		CPO->AddPaths(*subj, JoinType(joinType), EndType(endType));
		CPO->Execute(*solution, delta);
	}
	catch (clipperException &e)
	{
		err_msg = e.what();
		delete solution;
		return NULL;
	}
	return solution;
}

export void offset_clear(ClipperOffset *CPO)
{
	CPO->Clear();
}

// Section Clipper
export Clipper *clipper_new(int initOptions)
{
	return new Clipper(initOptions);
}

export void clipper_free(Clipper *CLP)
{
	delete CLP;
}

export void clipper_clear(Clipper *CLP)
{
	CLP->Clear();
}

export void clipper_reverse_solution(Clipper *CLP, bool value)
{
	CLP->ReverseSolution(value);
}

export void clipper_preserve_collinear(Clipper *CLP, bool value)
{
	CLP->PreserveCollinear(value);
}

export void clipper_strictly_simple(Clipper *CLP, bool value)
{
	CLP->StrictlySimple(value);
}

export bool clipper_add_path(Clipper *CLP, Path *path, int polyType, bool closed)
{
	try
	{
		CLP->AddPath(*path, PolyType(polyType), closed);
		return true;
	}
	catch (clipperException &e)
	{
		err_msg = e.what();
		return false;
	}
}

export bool clipper_add_paths(Clipper *CLP, Paths *paths, int polyType, bool closed)
{
	try
	{
		CLP->AddPaths(*paths, PolyType(polyType), closed);
		return true;
	}
	catch (clipperException &e)
	{
		err_msg = e.what();
		return false;
	}
}

export Paths *clipper_execute(Clipper *CLP, int clipType, int subjFillType, int clipFillType)
{
	Paths *solution = new Paths();
	try
	{
		CLP->Execute(ClipType(clipType), *solution, PolyFillType(subjFillType), PolyFillType(clipFillType));
	}
	catch (clipperException &e)
	{
		delete solution;
		err_msg = e.what();
		return NULL;
	}
	return solution;
}