module StippleCodeMirror

using Stipple, Stipple.ReactiveTools
using StippleUI
using Colors
using Crayons

import Stipple.opts
import Genie: Assets.add_fileroute, Assets.asset_path, Router.Route, Router._routes

export codemirror, highlight, codemirror_deps, mode_deps, external_codemirror_deps, external_mode_deps, EditorMixin

Stipple.render(c::Colorant) = "#$(hex(c, :auto))"

const assets_config = Genie.Assets.AssetsConfig(package = "StippleCodeMirror.jl")

include("codemirror.vue.jl")


const COLOR_16_MAPPING = Dict(
    0 => colorant"#000000",
    1 => colorant"#ff0000",
    2 => colorant"#00ff00",
    3 => colorant"#ffff00",
    4 => colorant"#0000ff",
    5 => colorant"#ff00ff",
    6 => colorant"#00ffff",
    7 => colorant"#c0c0c0",
    60 => colorant"#808080",
    61 => colorant"#ff8080",
    62 => colorant"#80ff80",
    63 => colorant"#ffff80",
    64 => colorant"#8080ff",
    65 => colorant"#ff80ff",
    66 => colorant"#80ffff",
    67 => colorant"#ffffff",
)

function index_to_rgb(index::Integer)
    0 < index < 255 || throw(ArgumentError("Index must be between 0 and 255"))

    if index < 16
        # Standard colors
        return RGB((index % 8) / 7, (index >> 3) / 7, 0)
    elseif index < 232
        # 6x6x6 color cube
        index -= 16
        r = (index ÷ 36) * 255 ÷ 5
        g = ((index ÷ 6) % 6) * 255 ÷ 5
        b = (index % 6) * 255 ÷ 5
        return RGB(r/255, g/255, b/255)
    else
        # Grayscale colors
        gray = ((index - 232) * 255 ÷ 23) / 255
        return RGB(gray, gray, gray)
    end
end

function cm_index(i, inds)
    line = findlast(i .>= inds)
    c = i - inds[line]
    opts(line = line - 1, ch = c - 1)
end

function ansicolor_to_rgb(c::Crayons.ANSIColor; default = RGB(1, 1, 1))
    c.active || return RGB(0, 0, 0)
    if c.style == Crayons.COLORS_256
        index_to_rgb(c.r)
    elseif c.style == Crayons.COLORS_16
        c.r == 9 ? default : COLOR_16_MAPPING[c.r]
    elseif c.style == Crayons.COLORS_24BIT
        RGB(c.r / 255, c.g / 255, c.b / 255)
    else
        default
    end
end

ansicolor_to_rgb(c::Crayon; default = RGB(1, 1, 1)) = ansicolor_to_rgb(c.fg; default)

function highlight(x)
    @warn "You have to load 'OhMyREPL' before using this function."
    opts(css = "", tokens = opts(lineNumber = true))
end

# definition of local routes and deps
basedir = dirname(dirname(Base.find_package("StippleCodeMirror")))

deps_routes::Vector{Route} = [
    add_fileroute(assets_config, "codemirror.min.js"; basedir),
    add_fileroute(assets_config, "codemirror.min.css"; basedir),
    add_fileroute(assets_config, "javascript/javascript.min.js"; basedir),
    add_fileroute(assets_config, "julia/julia.min.js"; basedir),
    add_fileroute(assets_config, "python/python.min.js"; basedir),
]

codemirror_deps() = [
    script(src = asset_path(assets_config, :js, file = "codemirror.min")),
    stylesheet(asset_path(assets_config, :css, file = "codemirror.min")),
    script(vue_codemirror)
]

mode_deps() = [
    script(src = asset_path(assets_config, :js, file = "javascript/javascript.min")),
    script(src = asset_path(assets_config, :js, file = "julia/julia.min")),
    script(src = asset_path(assets_config, :js, file = "python/python.min"))
]

external_codemirror_deps() = [
    script(src = "https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.2/codemirror.min.js"),
    stylesheet("https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.2/codemirror.min.css"),
    script(vue_codemirror)
]

external_mode_deps() = [
    script(src = "https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.2/mode/javascript/javascript.min.js")
    script(src = "https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.2/mode/julia/julia.min.js")
    script(src = "https://cdnjs.cloudflare.com/ajax/libs/codemirror/5.65.2/mode/python/python.min.js")
]

function __init__()
    # @deps StippleCodeMirror codemirror_deps
    Stipple.register_global_components(StippleCodeMirror, "VueCodeMirror", legacy = true)
    route.(deps_routes)
end

function codemirror(code::Symbol;
    mode::Union{Symbol, AbstractString} = "julia",
    options::Union{Symbol, AbstractString, AbstractDict} = opts(lineNumbers = true),
    textcolor::Union{Symbol, AbstractString, Colorant} = "#000",
    background::Union{Symbol, AbstractString, Colorant} = "#fff0",
    highlights::Union{Symbol, AbstractString, AbstractDict{Symbol, Any}, Colorant} = opts(css = "", tokens = OrderedDict{Symbol, Any}[]),
    kwargs...
)
    vue(:code__mirror; var"v-model" = code, mode, options, background, textcolor, highlights, mergemappings = false, kwargs...)
end

@define_mixin EditorMixin begin
    code = ""
    mode = "julia"
    options = opts(lineNumbers = true), READONLY
    background::Union{String, Colorant} = "#fff0"
    textcolor::Union{String, Colorant} = "#000"
    highlights = opts(css = "", tokens = []), READONLY
end

end # module