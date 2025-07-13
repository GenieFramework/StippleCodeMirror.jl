#cd(dirname(@__DIR__))

using StippleCodeMirror

using Stipple, Stipple.ReactiveTools
using StippleUI
using OhMyREPL
using Colors


@app Editor begin
    @mixin EditorMixin(mode = "ohmyrepl")

    @in colorscheme = "GitHubLight"
    @in colorscheme_options = OhMyREPL.Passes.SyntaxHighlighter.SYNTAX_HIGHLIGHTER_SETTINGS.schemes |> keys

    @onchange isready begin
        code = read(@__FILE__, String)
    end
    @onchange mode notify(code)
    @onchange code on_code()
    @onchange colorscheme on_colorscheme()
end

@handler Editor function on_code()
    if mode == "ohmyrepl"
        highlights = StippleCodeMirror.highlight(code)
    end
end

@handler Editor function on_colorscheme()
    colorscheme!(colorscheme)
    notify(code)
    darkmode = contains(colorscheme, r"dark|night"i)
    textcolor = darkmode ? "#fff" : "#000"
    background = darkmode ? "#222" : "#fff"
end

@deps Editor local_codemirror_deps
@deps Editor local_mode_deps

ui() = row(cell(class = "st-module", [
    h3(class = "q-pb-lg", "Editor")

    Stipple.select(class = "q-pb-md", :colorscheme, "", options = :colorscheme_options, :standout, ref = "select")

    codemirror(class = "bg-red",
        :code,
        options = :options,
        mode = :mode,
        background = :background,
        textcolor = :textcolor,
        highlights = :highlights,
    )
]))

@page("/", ui, model = Editor, debounce = 0, throttle = 50)

up(open_browser = true)

