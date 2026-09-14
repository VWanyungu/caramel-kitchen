import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), tailwindcss()],
  server: {
    allowedHosts: [
      '.trycloudflare.com',
      '0711-154-159-252-83.ngrok-free.app',
      "4632-2a00-7c80-0-3af-00-11.ngrok-free.app",
    ]
  }
})
