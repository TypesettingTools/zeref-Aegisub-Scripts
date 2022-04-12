-- loads and globalizes Yutils
export Yutils = require "Yutils"

-- loads karaskel
require "karaskel"

-- checks if the version gives class matches the current one
checkVersion = (version, cls, str) ->
    assert version == cls.version, "\n\nVersion incompatible in: \"#{str\gsub "%.", "\\"}\"\n\nExpected version: \"#{version}\"\nCurrent version: \"#{cls.version}\""

-- defines the files that will be exported
files = {
    -- 2D
    clipper: {export_name: "CLIPPER", module_name: "ZF.2D.clipper",  version: "6.4.2"}
    path:    {export_name: "PATH",    module_name: "ZF.2D.path",     version: "1.0.0"}
    paths:   {export_name: "PATHS",   module_name: "ZF.2D.paths",    version: "1.0.0"}
    point:   {export_name: "POINT",   module_name: "ZF.2D.point",    version: "1.0.0"}
    segment: {export_name: "SEGMENT", module_name: "ZF.2D.segment",  version: "1.0.0"}
    shape:   {export_name: "SHAPE",   module_name: "ZF.2D.shape",    version: "1.0.0"}
    -- img
    img:     {export_name: "IMAGE",   module_name: "ZF.img.img",     version: "1.0.0"}
    potrace: {export_name: "POTRACE", module_name: "ZF.img.potrace", version: "1.0.0"}
    -- text
    tags:    {export_name: "TAGS",    module_name: "ZF.text.tags",   version: "1.0.0"}
    text:    {export_name: "TEXT",    module_name: "ZF.text.text",   version: "1.0.0"}
    -- util
    config:  {export_name: "CONFIG",  module_name: "ZF.util.config", version: "1.0.0"}
    math:    {export_name: "MATH",    module_name: "ZF.util.math",   version: "1.0.0"}
    util:    {export_name: "UTIL",    module_name: "ZF.util.util",   version: "1.0.0"}
    table:   {export_name: "TABLE",   module_name: "ZF.util.table",  version: "1.0.0"}
}

exports = {}
for expt_name, expt_value in pairs files
    {:export_name, :module_name, :version} = expt_value
    -- gets the module
    module = require(module_name)[export_name]
    -- does the check
    checkVersion version, module, module_name
    -- adds the module for export
    exports[expt_name] = module

return exports