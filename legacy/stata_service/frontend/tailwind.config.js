/** @type {import('tailwindcss').Config} */
module.exports = {
    darkMode: ["class"],
    content: [
        "./index.html",
        "./src/**/*.{ts,tsx}",
        "./src/components/**/*.{ts,tsx}",
        // Include preview file content scanning if needed, but mainly for main app
    ],
    theme: {
        container: {
            center: true,
            padding: "2rem",
            screens: {
                "2xl": "1400px",
            },
        },
        extend: {
            colors: {
                /* Standard shadcn/ui mappings */
                border: "hsl(var(--border))",
                input: "hsl(var(--input))",
                ring: "hsl(var(--ring))",
                background: "hsl(var(--background))",
                foreground: "hsl(var(--foreground))",
                primary: {
                    DEFAULT: "hsl(var(--primary))",
                    foreground: "hsl(var(--primary-foreground))",
                },
                secondary: {
                    DEFAULT: "hsl(var(--secondary))",
                    foreground: "hsl(var(--secondary-foreground))",
                },
                destructive: {
                    DEFAULT: "hsl(var(--destructive))",
                    foreground: "hsl(var(--destructive-foreground))",
                },
                muted: {
                    DEFAULT: "hsl(var(--muted))",
                    foreground: "hsl(var(--muted-foreground))",
                },
                accent: {
                    DEFAULT: "hsl(var(--accent))",
                    foreground: "hsl(var(--accent-foreground))",
                },
                popover: {
                    DEFAULT: "hsl(var(--popover))",
                    foreground: "hsl(var(--popover-foreground))",
                },
                card: {
                    DEFAULT: "hsl(var(--card))",
                    foreground: "hsl(var(--card-foreground))",
                },

                /* 
                   G3 Override Magic: 
                   Remap standard colors used in App.tsx (slate, blue) 
                   to our G3 Palette variables to force the new look 
                   without changing class names.
                */
                slate: {
                    50: "hsl(var(--g3-hero-start))", // For Hero gradient start
                    // We can map other slate shades if needed, or leave default for utility
                },
                blue: {
                    50: "hsl(var(--g3-hero-end))",   // For Hero gradient end
                    100: "hsl(215 80% 92%)",         // Custom lighter blue
                    700: "hsl(var(--primary))",      // Map blue-700 text to our Primary Blue
                    600: "hsl(var(--primary))",      // Map blue-600 icons to Primary
                    // Map other blues generally to primary-ish shades if needed
                }
            },
            borderRadius: {
                lg: "var(--radius)",
                md: "calc(var(--radius) - 2px)",
                sm: "calc(var(--radius) - 4px)",
            },
            fontFamily: {
                sans: ["Inter", "var(--font-sans)", "sans-serif"],
                mono: ["JetBrains Mono", "var(--font-mono)", "monospace"],
            },
        },
    },
    plugins: [require("tailwindcss-animate")],
}
