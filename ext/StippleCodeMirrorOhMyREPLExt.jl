module StippleCodeMirrorOhMyREPLExt

using StippleCodeMirror
using OhMyREPL
using OhMyREPL.JuliaSyntax
using OhMyREPL.Crayons
using Colors

import StippleCodeMirror: ansicolor_to_rgb, cm_index
import Stipple.opts

# using StippleCodeMirror.Colors

function StippleCodeMirror.highlight(str::AbstractString, rpc::OhMyREPL.PassHandler = OhMyREPL.PASS_HANDLER, cursorpos::Int = 1, cursormovement::Bool = false; indent::Int = 0)
    tokens = tokenize(str)
    inds = pushfirst!(findall('\n', str), 0)

    OhMyREPL.apply_passes!(rpc, tokens, str, cursorpos, cursormovement)
    global cc = collect(rpc.accum_crayons)
    colors = StippleCodeMirror.ansicolor_to_rgb.(cc, default = colorant"#123123")
    all_colors = setdiff!(union(colors), [colorant"#123123"])
    classes = "cm-" .* hex.(colors, :rrggbb)
    css = join([".cm-$c { color: #$c}" for c in hex.(all_colors, :rrggbb)], " ")
    tokens = [opts(
        start = cm_index(first(t.range), inds),
        var"end" = cm_index(last(t.range) + 1, inds),
        className = c)
        for (t, c) in zip(tokens, classes) if !isempty(t.range)
    ]
    opts(; css, tokens)
end

function highlight(io::IO,  rpc::OhMyREPL.PassHandler = OhMyREPL.PASS_HANDLER, cursorpos::Int = 1, cursormovement::Bool = false; indent::Int = 0)
    highlight(String(take!(io)), rpc, cursorpos, cursormovement; indent)
end

end #module