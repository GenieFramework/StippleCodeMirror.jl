using StippleCodeMirror
using Stipple, Stipple.ReactiveTools
using StippleUI
using OrderedCollections

DEFAULT_CODE::String = """
function hello(name)
    println("Hello, \$name!")
end

function fibonacci(n)
    if n <= 1
        return n
    end
    return fibonacci(n-1) + fibonacci(n-2)
end

function factorial(n)
    if n == 0
        return 1
    end
    return n * factorial(n-1)
end

function quicksort(arr)
    if length(arr) <= 1
        return arr
    end
    pivot = arr[1]
    left = [x for x in arr[2:end] if x <= pivot]
    right = [x for x in arr[2:end] if x > pivot]
    return [quicksort(left); pivot; quicksort(right)]
end

# Test the functions
hello("World")
println("Fibonacci(10) = ", fibonacci(10))
println("Factorial(5) = ", factorial(5))

# Add more lines to make scrolling useful
for i in 1:20
    println("Line \$i: Some text to make the editor scrollable")
end
"""

@app PositionEditor begin
    @mixin EditorMixin

    # Variables
    @in tab = "editor"
    @in jump_to_start = false
    @in jump_to_middle = false

    # Initialization
    @onchange isready begin
        code = DEFAULT_CODE
    end

    # Button handlers
    @onbutton jump_to_start begin
        position = OrderedDict("line" => 0, "ch" => 0, "scrollTop" => 0, "scrollLeft" => 0)
    end

    @onbutton jump_to_middle begin
        position = OrderedDict("line" => 15, "ch" => 10, "scrollTop" => 200, "scrollLeft" => 0)
    end
end

@deps PositionEditor codemirror_deps
@deps PositionEditor mode_deps

ui() = container([
    h3("CodeMirror Position Demo")

    p("The position is automatically saved and restored. Switch between tabs to test the restoration.")

    row([
        cell(class = "col-12", [
            tabgroup(
                :tab,
                inlinelabel = true,
                [
                    tab(name = "editor", icon = "code", label = "Editor"),
                    tab(name = "info", icon = "info", label = "Position Info"),
                    tab(name = "other", icon = "description", label = "Other Tab")
                ]
            )
        ])
    ])

    row([
        cell(class = "col-12", [
            tabpanels(
                :tab,
                animated = true,
                var"transition-prev" = "slide-down",
                var"transition-next" = "slide-up",
                [
                    tabpanel(name = "editor", [
                        row([
                            btn("Jump to Start", @click(:jump_to_start), color = "primary", class = "q-mr-md")
                            btn("Jump to Middle", @click(:jump_to_middle), color = "secondary")
                        ])

                        card(class = "q-mt-md", style = "height: 500px", [
                                codemirror(:code,
                                    class = "full",
                                    options = :options,
                                    mode = :mode,
                                    background = :background,
                                    textcolor = :textcolor,
                                    highlights = :highlights,
                                    position = :position,  # Bidirectional binding
                                    # style = "height: 450px"
                                )
                        ])
                    ])

                    tabpanel(name = "info", [
                        card([
                            card_section([
                                h5("Current Editor Position:")
                                p([strong("Line: "), span("{{ position.line }}")])
                                p([strong("Column: "), span("{{ position.ch }}")])
                                p([strong("Scroll Top: "), span("{{ position.scrollTop }}")])
                                p([strong("Scroll Left: "), span("{{ position.scrollLeft }}")])
                            ])
                        ])

                        card(class = "q-mt-md", [
                            card_section([
                                h5("Instructions:")
                                p("1. Switch to the 'Editor' tab")
                                p("2. Move the cursor and scroll in the editor")
                                p("3. Switch to this tab to see the position")
                                p("4. Switch back to the editor - the position is preserved!")
                            ])
                        ])
                    ])

                    tabpanel(name = "other", [
                        card([
                            card_section([
                                h5("This is another tab")
                                p("This tab demonstrates that the editor position is preserved even when you switch to a completely different tab.")
                                p("Go back to the Editor tab and you will see that the cursor and scroll position are exactly where you left them.")
                            ])
                        ])
                    ])
                ]
            )
        ])
    ])
])

@page("/", ui, model = PositionEditor, debounce = 0)

up(open_browser = true)
