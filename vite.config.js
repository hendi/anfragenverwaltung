import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// https://vitejs.dev/config/
export default defineConfig({
  server: {
    port: process.env.VITE_PORT || 8000,
  },
  plugins: [react()],
});
