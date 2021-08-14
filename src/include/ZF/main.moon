-- globalize lib math
with math
    export pi, ln, sin, cos, tan, max, min      = .pi, .log, .sin, .cos, .tan, .max, .min
    export abs, deg, rad, log, asin, sqrt       = .abs, .deg, .rad, .log10, .asin, .sqrt
    export acos, atan, sinh, cosh, tanh, random = .acos, .atan, .asin, .cosh, .tanh, .random
    export ceil, floor, atan2, format, unpack   = .ceil, .floor, .atan2, string.format, table.unpack or unpack

-- globalize Yutils
export Yutils = require "Yutils"

require "karaskel"
require "ZF.headers"

-- load external libs
import BEZIER from require "ZF.bezier"
import CONFIG from require "ZF.config"
import IMAGE  from require "ZF.image"
import MATH   from require "ZF.math"
import POLY   from require "ZF.poly"
import SHAPE  from require "ZF.shape"
import TABLE  from require "ZF.table"
import TAGS   from require "ZF.tags"
import TEXT   from require "ZF.text"
import UTIL   from require "ZF.util"

{
    bezier: BEZIER
    config: CONFIG
    image:  IMAGE
    math:   MATH
    poly:   POLY
    shape:  SHAPE
    table:  TABLE
    tags:   TAGS
    text:   TEXT
    util:   UTIL
}