vue_codemirror = js"""
Vue.component("VueCodeMirror", {
    data: () => ({ resizeObserver: null }),    
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
        }
    },
    beforeDestroy() {
        if (this.editor) {
        this.editor.toTextArea(); // Clean up
        }
    },
});
"""