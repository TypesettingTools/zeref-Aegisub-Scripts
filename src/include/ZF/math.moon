class MATH

    -- returns the distance between two points
    distance: (x1 = 0, y1 = 0, x2 = 0, y2 = 0) => @round sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2), 3

    -- rounds numerical values
    round: (x, dec = 2) => dec >= 1 and floor(x * 10 ^ floor(dec) + 0.5) / 10 ^ floor(dec) or floor(x + 0.5)

{:MATH}