import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        ink: "#161616",
        "ink-deep": "#0c0c0c",
        panel: "#222222",
        "panel-dark": "#1d1d1d",
        line: "#333333",
        "line-light": "#444444",
        crimson: "#9a0f28",
        "crimson-bright": "#b5173a",
        "crimson-glow": "#e11d48",
        bone: "#f4f4f4",
        mute: "#9a9a9a",
        grey: "#d9d9d9",
      },
      fontFamily: {
        sans: ["var(--font-inter)", "Inter", "system-ui", "sans-serif"],
      },
      animation: {
        "pulse-slow": "pulse 4s cubic-bezier(0.4, 0, 0.6, 1) infinite",
        float: "float 6s ease-in-out infinite",
        glow: "glow 2.5s ease-in-out infinite alternate",
      },
      keyframes: {
        float: {
          "0%, 100%": { transform: "translateY(0px)" },
          "50%": { transform: "translateY(-8px)" },
        },
        glow: {
          "0%": { filter: "drop-shadow(0 0 12px rgba(181, 23, 58, 0.3))" },
          "100%": { filter: "drop-shadow(0 0 30px rgba(225, 29, 72, 0.7))" },
        },
      },
    },
  },
  plugins: [],
};

export default config;
