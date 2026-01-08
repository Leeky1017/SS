import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react-swc'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    host: '0.0.0.0',  // 绑定所有接口，避免仅 IPv6 导致无法访问
    port: 5173,
    strictPort: true, // 端口被占用时报错而非切换端口
    proxy: {
      '/task-codes': 'http://localhost:8000',
      '/jobs': 'http://localhost:8000',
      '/upload-sessions': 'http://localhost:8000',
      '/storage': 'http://localhost:8000',
      '/api': 'http://localhost:8000',
      '/ping': 'http://localhost:8000',
    },
  },
  build: {
    outDir: '../web',
    emptyOutDir: true,
  },
})
