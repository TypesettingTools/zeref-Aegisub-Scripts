-- loads karaskel
require "karaskel"

-- loads and globalizes Yutils
export Yutils = require "Yutils"

-- loads a library error that was not found
export libError = (name) ->
    error table.concat {
        "\n--> #{name} was not found <--\n\n"
        "⬇ To fix this error, download the file via the link below ⬇\n"
        "https://github.com/zerefxx/Aegisub-macros/releases/"
    }

-- checks if the version gives class matches the current one
checkVersion = (version, cls, module_name) ->
    assert version == cls.version, "\n\nVersion incompatible in: \"#{module_name\gsub "%.", "\\"}\"\n\nExpected version: \"#{version}\"\nCurrent version: \"#{cls.version}\""

-- returns module not found error
moduleError = (module_name) ->
    error "\n\nThe module \"#{module_name}\" was not found, please check your files and try again"

-- returns the class error not found in the module
classError = (module_name, export_name) ->
    error "\n\nThe class \"#{export_name}\" was not found in module \"#{module_name\gsub "%.", "\\"}\", please check your files and try again"

-- defines the files that will be exported
files = {
    -- 2D
    clipper: {export_name: "CLIPPER", module_name: "ZF.2D.clipper",     version: "1.0.3"}
    path:    {export_name: "PATH",    module_name: "ZF.2D.path",        version: "1.1.0"}
    paths:   {export_name: "PATHS",   module_name: "ZF.2D.paths",       version: "1.1.2"}
    point:   {export_name: "POINT",   module_name: "ZF.2D.point",       version: "1.0.0"}
    segment: {export_name: "SEGMENT", module_name: "ZF.2D.segment",     version: "1.0.1"}
    shape:   {export_name: "SHAPE",   module_name: "ZF.2D.shape",       version: "1.1.3"}
    -- ass tags
    layer:   {export_name: "LAYER",   module_name: "ZF.ass.tags.layer", version: "1.0.0"}
    tags:    {export_name: "TAGS",    module_name: "ZF.ass.tags.tags",  version: "1.0.0"}
    -- ass
    dialog:  {export_name: "DIALOG",  module_name: "ZF.ass.dialog",     version: "1.0.0"}
    fbf:     {export_name: "FBF",     module_name: "ZF.ass.fbf",        version: "1.1.4"}
    font:    {export_name: "FONT",    module_name: "ZF.ass.font",       version: "1.0.0"}
    line:    {export_name: "LINE",    module_name: "ZF.ass.line",       version: "1.4.0"}
    -- img
    img:     {export_name: "IMAGE",   module_name: "ZF.img.img",        version: "1.0.0"}
    potrace: {export_name: "POTRACE", module_name: "ZF.img.potrace",    version: "1.0.0"}
    -- util
    config:  {export_name: "CONFIG",  module_name: "ZF.util.config",    version: "1.0.2"}
    math:    {export_name: "MATH",    module_name: "ZF.util.math",      version: "1.1.1"}
    util:    {export_name: "UTIL",    module_name: "ZF.util.util",      version: "1.3.0"}
    table:   {export_name: "TABLE",   module_name: "ZF.util.table",     version: "1.0.0"}
}

exports = {}
for expt_name, expt_value in pairs files
    {:export_name, :module_name, :version} = expt_value
    -- gets the module
    has_module, module = pcall require, module_name
    -- if the module was not loaded, returns an error
    unless has_module
        moduleError module_name
    module = require(module_name)[export_name]
    -- if the class was not loaded, returns an error
    unless module
        classError module_name, export_name
    -- does the check
    checkVersion version, module, module_name
    -- adds the module for export
    exports[expt_name] = module

return exports