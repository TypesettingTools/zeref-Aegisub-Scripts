import POINT from require "ZF.2D.point"
import TABLE from require "ZF.util.table"

-- https://github.com/ynakajima/polyline2bezier
-- https://github.com/mourner/simplify-js
class SIMPLIFY

    new: (points, tolerance = 1, highestQuality = true) =>
        @pts = points
        @tol = tolerance / 10
        @hqy = highestQuality
        @bld = {}

    drawBezierCurve: (curve) => TABLE(@bld)\push curve

    computeLeftTangent: (d, _end) =>
        tHat1 = d[_end + 1] - d[_end]
        return tHat1\vecNormalize!

    computeRightTangent: (d, _end) =>
        tHat2 = d[_end - 1] - d[_end]
        return tHat2\vecNormalize!

    computeCenterTangent: (d, center) =>
        V1 = d[center - 1] - d[center]
        V2 = d[center] - d[center + 1]
        tHatCenter = POINT!
        tHatCenter.x = (V1.x + V2.x) / 2
        tHatCenter.y = (V1.y + V2.y) / 2
        return tHatCenter\vecNormalize!

    chordLengthParameterize: (d, first, last) =>
        u = {0}
        for i = first + 1, last
            u[i - first + 1] = u[i - first] + d[i]\distance d[i - 1]
        for i = first + 1, last
            u[i - first + 1] /= u[last - first + 1]
        return u

    bezierII: (degree, V, t) =>
        Vtemp = {}

        for i = 0, degree
            Vtemp[i] = POINT V[i + 1].x, V[i + 1].y

        for i = 1, degree
            for j = 0, degree - i
                Vtemp[j].x = (1 - t) * Vtemp[j].x + t * Vtemp[j + 1].x
                Vtemp[j].y = (1 - t) * Vtemp[j].y + t * Vtemp[j + 1].y

        return POINT Vtemp[0].x, Vtemp[0].y

    computeMaxError: (d, first, last, bezCurve, u, splitPoint) =>
        splitPoint = (last - first + 1) / 2

        maxError = 0
        for i = first + 1, last - 1
            P = @bezierII 3, bezCurve, u[i - first + 1]
            v = P - d[i]
            dist = v\vecDistance!
            if dist >= maxError
                maxError = dist
                splitPoint = i
    
        return {:maxError, :splitPoint}

    newtonRaphsonRootFind: (_Q, _P, u) =>
        Q1, Q2 = {}, {}

        Q = {
            POINT _Q[1].x, _Q[1].y
            POINT _Q[2].x, _Q[2].y
            POINT _Q[3].x, _Q[3].y
            POINT _Q[4].x, _Q[4].y
        }
    
        P = POINT _P.x, _P.y

        Q_u = @bezierII 3, Q, u
        for i = 1, 3
            Q1[i] = POINT!
            Q1[i].x = (Q[i + 1].x - Q[i].x) * 3
            Q1[i].y = (Q[i + 1].y - Q[i].y) * 3

        for i = 1, 2
            Q2[i] = POINT!
            Q2[i].x = (Q1[i + 1].x - Q1[i].x) * 2
            Q2[i].y = (Q1[i + 1].y - Q1[i].y) * 2
    
        Q1_u = @bezierII 2, Q1, u
        Q2_u = @bezierII 1, Q2, u

        numerator = (Q_u.x - P.x) * (Q1_u.x) + (Q_u.y - P.y) * (Q1_u.y)
        denominator = (Q1_u.x) * (Q1_u.x) + (Q1_u.y) * (Q1_u.y) + (Q_u.x - P.x) * (Q2_u.x) + (Q_u.y - P.y) * (Q2_u.y)

        if denominator == 0
            return u

        return u - (numerator / denominator)

    reparameterize: (d, first, last, u, bezCurve) =>
        _bezCurve = {
            POINT bezCurve[1].x, bezCurve[1].y
            POINT bezCurve[2].x, bezCurve[2].y
            POINT bezCurve[3].x, bezCurve[3].y
            POINT bezCurve[4].x, bezCurve[4].y
        }
        uPrime = {}
        for i = first, last
            uPrime[i - first + 1] = @newtonRaphsonRootFind _bezCurve, d[i], u[i - first + 1]
        return uPrime

    BM: (u, tp) =>
        switch tp
            when 1 then 3 * u * ((1 - u) ^ 2)
            when 2 then 3 * (u ^ 2) * (1 - u)
            when 3 then u ^ 3
            else        (1 - u) ^ 3

    generateBezier: (d, first, last, uPrime, tHat1, tHat2) =>
        C, A, bezCurve = {{0, 0}, {0, 0}, {0, 0}}, {}, {}
        nPts = last - first + 1

        for i = 1, nPts
            v1 = POINT tHat1.x, tHat1.y
            v2 = POINT tHat2.x, tHat2.y
            v1 = v1\vecScale @BM uPrime[i], 1
            v2 = v2\vecScale @BM uPrime[i], 2
            A[i] = {v1, v2}

        for i = 1, nPts
            C[1][1] += A[i][1]\dot A[i][1]
            C[1][2] += A[i][1]\dot A[i][2]

            C[2][1] = C[1][2]
            C[2][2] += A[i][2]\dot A[i][2]

            b0 = d[first] * @BM(uPrime[i])
            b1 = d[first] * @BM(uPrime[i], 1)
            b2 = d[last] * @BM(uPrime[i], 2)
            b3 = d[last] * @BM(uPrime[i], 3)

            tm0 = b2 + b3
            tm1 = b1 + tm0
            tm2 = b0 + tm1
            tmp = d[first + i - 1] - tm2

            C[3][1] += A[i][1]\dot tmp
            C[3][2] += A[i][2]\dot tmp

        det_C0_C1 = C[1][1] * C[2][2] - C[2][1] * C[1][2]
        det_C0_X = C[1][1] * C[3][2] - C[2][1] * C[3][1]
        det_X_C1 = C[3][1] * C[2][2] - C[3][2] * C[1][2]

        alpha_l = det_C0_C1 == 0 and 0 or det_X_C1 / det_C0_C1
        alpha_r = det_C0_C1 == 0 and 0 or det_C0_X / det_C0_C1

        segLength = d[last]\distance d[first]
        epsilon = 1e-6 * segLength

        if alpha_l < epsilon or alpha_r < epsilon then
            dist = segLength / 3
            bezCurve[1] = d[first]
            bezCurve[4] = d[last]
            bezCurve[2] = bezCurve[1] + tHat1\vecScale(dist)
            bezCurve[3] = bezCurve[4] + tHat2\vecScale(dist)
            return bezCurve

        bezCurve[1] = d[first]
        bezCurve[4] = d[last]
        bezCurve[2] = bezCurve[1] + tHat1\vecScale(alpha_l)
        bezCurve[3] = bezCurve[4] + tHat2\vecScale(alpha_r)
        return bezCurve

    fitCubic: (d, first, last, tHat1, tHat2, _error) =>
        u, uPrime, maxIterations, tHatCenter = {}, {}, 4, POINT!
        iterationError = _error ^ 2
        nPts = last - first + 1

        if nPts == 2
            dist = d[last]\distance(d[first]) / 3

            bezCurve = {}
            bezCurve[1] = d[first]
            bezCurve[4] = d[last]
            tHat1 = tHat1\vecScale dist
            tHat2 = tHat2\vecScale dist
            bezCurve[2] = bezCurve[1] + tHat1
            bezCurve[3] = bezCurve[4] + tHat2
            @drawBezierCurve bezCurve
            return

        u = @chordLengthParameterize d, first, last
        bezCurve = @generateBezier d, first, last, u, tHat1, tHat2

        resultMaxError = @computeMaxError d, first, last, bezCurve, u, nil
        maxError = resultMaxError.maxError
        splitPoint = resultMaxError.splitPoint

        if maxError < _error
            @drawBezierCurve bezCurve
            return

        if maxError < iterationError
            for i = 1, maxIterations
                uPrime = @reparameterize d, first, last, u, bezCurve
                bezCurve = @generateBezier d, first, last, uPrime, tHat1, tHat2
                resultMaxError = @computeMaxError d, first, last, bezCurve, uPrime, splitPoint
                maxError = resultMaxError.maxError
                splitPoint = resultMaxError.splitPoint
                if maxError < _error
                    @drawBezierCurve bezCurve
                    return
                u = uPrime

        tHatCenter = @computeCenterTangent d, splitPoint
        @fitCubic d, first, splitPoint, tHat1, tHatCenter, _error
        tHatCenter = tHatCenter\vecNegative!
        @fitCubic d, splitPoint, last, tHatCenter, tHat2, _error
        return

    fitCurve: (d, nPts, _error = 1) =>
        tHat1 = @computeLeftTangent d, 1
        tHat2 = @computeRightTangent d, nPts
        @fitCubic d, 1, nPts, tHat1, tHat2, _error
        return

    simplifyRadialDist: =>
        prevPoint = @pts[1]
        newPoints, point = {prevPoint}, nil
        for i = 2, #@pts
            point = @pts[i]
            if point\sqDistance(prevPoint) > @tol
                TABLE(newPoints)\push point
                prevPoint = point
        if prevPoint != point
            TABLE(newPoints)\push point
        return newPoints

    simplifyDPStep: (first, last, simplified) =>
        maxSqDist, index = @tol, nil
        for i = first + 1, last
            sqDist = @pts[i]\sqSegDistance @pts[first], @pts[last]
            if sqDist > maxSqDist
                index = i
                maxSqDist = sqDist
        if maxSqDist > @tol
            if index - first > 1
                @simplifyDPStep first, index, simplified
            TABLE(simplified)\push @pts[index]
            if last - index > 1
                @simplifyDPStep index, last, simplified

    simplifyDouglasPeucker: =>
        simplified = {@pts[1]}
        @simplifyDPStep 1, #@pts, simplified
        TABLE(simplified)\push @pts[#@pts]
        return simplified

    spLines: =>
        if #@pts <= 2
            return @pts

        @tol = @tol ^ 2
        @pts = @hqy and @pts or @simplifyRadialDist!
        @bld = @simplifyDouglasPeucker!
        return @bld

    spLines2Bezier: =>
        @fitCurve @pts, #@pts, @tol
        return @bld

{:SIMPLIFY}