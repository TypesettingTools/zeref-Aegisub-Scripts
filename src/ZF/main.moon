-- loads and globalizes Yutils
export Yutils = require "Yutils"

-- loads karaskel
require "karaskel"

import CONFIG from require "ZF.defs.config"
import MATH   from require "ZF.util.math"
import UTIL   from require "ZF.util.util"
import TABLE  from require "ZF.util.table"
import TAGS   from require "ZF.text.tags"
import TEXT   from require "ZF.text.text"
import SHAPE  from require "ZF.2D.shape"

{
    config: CONFIG
    math:   MATH
    util:   UTIL
    table:  TABLE
    tags:   TAGS
    text:   TEXT
    shape:  SHAPE
}