# Stata Service Frontend

独立的 React 前端项目，基于 Figma 设计重构，对接新的三段式上传 API 流程。

## 技术栈

- **React 18** + TypeScript
- **Vite** 构建工具
- **TailwindCSS** 样式框架
- **Radix UI** 无障碍组件
- **Lucide React** 图标库

## 新 API 流程

前端已对接 TaskE+F 新主链路：

```
1. POST /task-codes/redeem      → 兑换任务码，获取 job_id + token
2. POST /jobs/{job_id}/bundle   → 声明要上传的文件列表
3. POST /jobs/{job_id}/upload-sessions → 获取 presigned URLs
4. PUT  {presigned_url}         → 浏览器直传文件到对象存储
5. POST /upload-sessions/{id}/finalize → 完成上传
6. GET  /jobs/{job_id}/artifacts → 列出可下载的产出物
7. GET  /jobs/{job_id}/artifacts/{id}/download → 获取单文件下载链接
8. POST /jobs/{job_id}/artifacts/zip → 请求打包下载
```

## 开发

```bash
# 安装依赖
cd frontend
npm install

# 启动开发服务器 (端口 5173，自动代理 API 到 localhost:8000)
npm run dev

# 构建生产版本
npm run build
```

## 目录结构

```
frontend/
├── src/
│   ├── api/
│   │   └── stataService.ts    # API 服务层，封装所有后端调用
│   ├── components/
│   │   ├── ui/                # shadcn/ui 基础组件
│   │   ├── Header.tsx         # 页头
│   │   ├── Hero.tsx           # 主标题区
│   │   ├── StepIndicator.tsx  # 步骤指示器
│   │   ├── TaskCreationForm.tsx  # 任务创建表单（Step 1）
│   │   ├── TaskQuery.tsx      # 任务查询（Step 2）
│   │   └── TaskResult.tsx     # 提交结果展示
│   ├── lib/
│   │   └── utils.ts           # 工具函数
│   ├── App.tsx                # 主应用
│   ├── main.tsx               # 入口
│   └── index.css              # 全局样式
├── index.html
├── package.json
├── vite.config.ts
├── tailwind.config.js
└── tsconfig.json
```

## 与后端集成

### 开发模式

Vite 开发服务器会自动将 API 请求代理到 `http://localhost:8000`：

```ts
// vite.config.ts
server: {
  proxy: {
    '/task-codes': 'http://localhost:8000',
    '/jobs': 'http://localhost:8000',
    '/upload-sessions': 'http://localhost:8000',
  }
}
```

### 生产模式

构建后的静态文件在 `dist/` 目录，可以：

1. **方案 A**：使用 FastAPI 的 `StaticFiles` 中间件服务
2. **方案 B**：使用 Nginx/Caddy 等反向代理服务静态文件

## Token 管理

- 用户兑换任务码后，token 自动存储到 `localStorage`
- 后续所有 API 调用自动携带 `Authorization: Bearer {token}` 头
- 相关函数：`saveAuth()`, `getAuth()`, `clearAuth()`

## 与 main.py 旧前端的对比

| 特性 | 旧版 (main.py 内嵌) | 新版 (独立 React) |
|------|---------------------|-------------------|
| API 流程 | 调用已废弃的 `/api/web_submit` | 对接新三段式流程 |
| 文件上传 | 传到应用服务器 | 直传 presigned URL |
| Token | 无 | 自动管理 Bearer Token |
| UI 框架 | 原生 HTML/CSS | React + TailwindCSS |
| 组件化 | 无 | 完整组件架构 |
