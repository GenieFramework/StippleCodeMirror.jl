vue_codemirror = js"""
Vue.component("VueCodeMirror", {
    data: () => ({ resizeObserver: null, positionTimer: null, settingPosition: false }),    
    template: `
        <div ref="editorContainer"></div>
    `,
    props: {
        modelValue: { // code
        type: String,
        default: ''
        },
        mode: {
            type: String,
            default: 'javascript'
        },
        background: {
            type: String,
            default: '#fff0' // default is transparent, so that classes and styles of the component apply
        },
        textcolor: {
            type: String,
            default: '#000'
        },
        fontsize: {
            type: String,
            default: '14px'
        },
        options: {
            type: Object,
            default: () => ({
                lineNumbers: false,
                mode: this.mode
            }),
        },
        highlights: {
            type: Object,
            default: () => ({})
        },
        style: {
            type: String,
            default: ''
        },
        position: {
            type: Object,
            default: () => ({ line: 0, ch: 0, scrollTop: 0, scrollLeft: 0 })
        },
    },
    mounted() {
        this.stylename = 'dynamic-cm-css-' + Math.floor(100000 + Math.random() * 900000);
        this.$nextTick(() => {
            this.options.mode = this.mode
            this.editor = CodeMirror(this.$refs.editorContainer, {
                ...this.options,
                value: this.modelValue,
            });
            // Update the v-model when the content changes
            this.editor.on('change', (instance) => {
                const content = instance.getValue();
                this.$emit('update:modelValue', content);
            });
            // Emit position changes when cursor moves or scroll changes
            this.editor.on('cursorActivity', () => {
                this.emitPosition();
            });
            this.editor.on('scroll', () => {
                this.emitPosition();
            });
            // Set initial position if provided
            if (this.position && (this.position.line || this.position.scrollTop)) {
                this.$nextTick(() => {
                    this.settingPosition = true;

                    const lineCount = this.editor.lineCount();
                    const targetLine = Math.min(Math.max(0, this.position.line || 0), lineCount - 1);
                    const lineLength = this.editor.getLine(targetLine)?.length || 0;
                    const targetCh = Math.min(Math.max(0, this.position.ch || 0), lineLength);

                    this.editor.setCursor({ line: targetLine, ch: targetCh });

                    // If scrollTop is set, use it, otherwise scroll to cursor
                    if (this.position.scrollTop) {
                        this.editor.scrollTo(this.position.scrollLeft || 0, this.position.scrollTop);
                    } else {
                        this.editor.scrollIntoView({ line: targetLine, ch: targetCh }, 100);
                    }

                    setTimeout(() => { this.settingPosition = false; }, 50);
                });
            }
            this.resizeObserver = new ResizeObserver(entries => {
                for (let entry of entries) {
                    const height = entry.contentRect.height;
                    // const width = entry.contentRect.width;
                    this.editor.setSize("100%", height); // Adjust the editor size
                }
            });
            this.applyStylesheet('');
            this.resizeObserver.observe(this.$refs.editorContainer.parentElement);
        });
    },
    methods: {
        clearHighlights: function() {
            const marks = this.editor.getAllMarks();
            marks.forEach(mark => mark.clear());
        },
        applyHighlights: function(tokens) {
            tokens.forEach(({ start, end, className }) => {
            this.editor.markText(start, end, { className });
            })
        },
        applyStylesheet: function(css) {
            // Remove existing styles if any
            if (!css) {css = ''};
            css += ` .CodeMirror { background: ${this.background} !important; color: ${this.textcolor} !important; font-size: ${this.fontsize} !important; ${this.style}}` +
                ` .CodeMirror-cursor {border-left: 1px solid #fff !important; border-right: 1px solid #000 !important; }`;
            const existingStyle = document.getElementById(this.stylename);
            if (existingStyle) {
                existingStyle.remove();
            };

            // Create a new style element
            const style = document.createElement('style');
            style.id = this.stylename; // Set an ID for easy removal
            style.textContent = css; // Set the CSS content
            document.head.appendChild(style); // Append the style to the head
        },
        highlight: function(data) {
            this.clearHighlights()
            this.applyStylesheet(data.css)
            this.applyHighlights(data.tokens)
        },
        emitPosition: function() {
            if (this.settingPosition || !this.editor) return;

            // Debounce to avoid too many updates
            clearTimeout(this.positionTimer);
            this.positionTimer = setTimeout(() => {
                const cursor = this.editor.getCursor();
                const scroll = this.editor.getScrollInfo();
                this.$emit('update:position', {
                    line: cursor.line,
                    ch: cursor.ch,
                    scrollTop: scroll.top,
                    scrollLeft: scroll.left
                });
            }, 100);
        }
    },
    watch: {
        modelValue(newValue) {
        if (newValue !== this.editor.getValue()) {
            this.editor.setValue(newValue);
        }
        },
        mode(newMode) {
            console.log(newMode)
            this.options.mode = newMode
        },
        background() {
            this.applyStylesheet(this.highlights.css)
        },
        textcolor() {
            this.applyStylesheet(this.highlights.css)
        },
        options: {
        deep: true, // Enable deep watching
        handler(newOptions) {
            // console.log("Options changed");
            for (const [key, value] of Object.entries(newOptions)) {
            this.editor.setOption(key, value);
            }
        },
        },
        highlights: {
            deep: true,
            handler(newHighlights) {
                this.highlight(newHighlights);
            }
        },
        position: {
            deep: true,
            handler(pos) {
                if (!this.editor || !pos || this.settingPosition) return;

                // Only set position if it actually changed
                const currentCursor = this.editor.getCursor();
                const currentScroll = this.editor.getScrollInfo();

                const cursorChanged = pos.line !== undefined &&
                    (pos.line !== currentCursor.line || (pos.ch || 0) !== currentCursor.ch);
                const scrollChanged = pos.scrollTop !== undefined &&
                    (pos.scrollTop !== currentScroll.top || (pos.scrollLeft || 0) !== currentScroll.left);

                if (!cursorChanged && !scrollChanged) return;

                this.settingPosition = true;

                if (cursorChanged) {
                    // Validate line number
                    const lineCount = this.editor.lineCount();
                    const targetLine = Math.min(Math.max(0, pos.line), lineCount - 1);

                    // Validate ch (limit to line length)
                    const lineLength = this.editor.getLine(targetLine)?.length || 0;
                    const targetCh = Math.min(Math.max(0, pos.ch || 0), lineLength);

                    this.editor.setCursor({ line: targetLine, ch: targetCh });

                    // Scroll to cursor if no explicit scroll position is set
                    if (!scrollChanged) {
                        this.editor.scrollIntoView({ line: targetLine, ch: targetCh }, 100);
                    }
                }

                if (scrollChanged) {
                    this.editor.scrollTo(pos.scrollLeft || 0, pos.scrollTop);
                }

                setTimeout(() => { this.settingPosition = false; }, 50);
            }
        }
    },
    beforeDestroy() {
        if (this.editor) {
        this.editor.toTextArea(); // Clean up
        }
    },
});
"""