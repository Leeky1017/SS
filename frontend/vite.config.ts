import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  const devProxyTarget = env.VITE_DEV_PROXY_TARGET

  return {
    plugins: [react()],
    server: devProxyTarget
      ? {
          proxy: {
            '/v1': {
              target: devProxyTarget,
              changeOrigin: true,
              secure: false,
            },
            '/api/admin': {
              target: devProxyTarget,
              changeOrigin: true,
              secure: false,
            },
          },
        }
      : undefined,
  }
})
