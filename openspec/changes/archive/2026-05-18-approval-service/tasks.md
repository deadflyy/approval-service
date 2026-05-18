## 1. 项目初始化

- [x] 1.1 创建 Vue 3 前端项目（Vite + TypeScript）
- [x] 1.2 创建 Node.js 后端项目（Express + TypeScript）
- [x] 1.3 初始化 SQLite 数据库，创建表结构（users, organizations, user_org_auth, templates, requests, approvals, org_stats）
- [x] 1.4 安装依赖：前端 Element Plus，后端 express, better-sqlite3, jsonwebtoken, docxtemplater, multer

## 2. 用户认证

- [x] 2.1 实现用户登录 API（POST /api/auth/login）
- [x] 2.2 实现 JWT 中间件，校验 token 和角色
- [x] 2.3 实现登录页面（Vue）
- [x] 2.4 实现路由守卫，根据角色跳转不同首页

## 3. 管理员后台 - 用户与组织管理

- [x] 3.1 实现用户 CRUD API（GET/POST/PUT/DELETE /api/users）
- [x] 3.2 实现组织 CRUD API（GET/POST/PUT/DELETE /api/organizations）
- [x] 3.3 实现用户-组织授权 API（POST /api/users/:id/organizations）
- [x] 3.4 实现用户管理页面（Vue）
- [x] 3.5 实现组织管理页面（Vue）

## 4. 管理员后台 - 模板管理

- [x] 4.1 实现模板上传 API（POST /api/templates），解析 docx 中的变量
- [x] 4.2 实现模板列表 API（GET /api/templates）
- [x] 4.3 实现模板映射配置 API（PUT /api/templates/:id）
- [x] 4.4 实现模板管理页面（Vue），包含上传、变量预览、映射配置

## 5. 管理员后台 - 批复号管理

- [x] 5.1 实现批复号查询 API（GET /api/batch-numbers）
- [x] 5.2 实现批复号重置 API（PUT /api/batch-numbers）
- [x] 5.3 实现批复号管理页面（Vue）

## 6. 请示提交

- [x] 6.1 实现请示类别和进度选择组件，根据类别动态显示可选进度
- [x] 6.2 实现动态表单组件，根据模板变量渲染不同字段
- [x] 6.3 实现请示提交 API（POST /api/requests）
- [x] 6.4 实现请示列表 API（GET /api/requests），支持按角色过滤
- [x] 6.5 实现请示提交页面（Vue）
- [x] 6.6 实现"我的请示"列表页面（Vue）

## 7. 审批流程

- [x] 7.1 实现待审批列表 API（GET /api/requests?status=pending）
- [x] 7.2 实现审批通过 API（POST /api/requests/:id/approve），自动生成批复号和批复文档
- [x] 7.3 实现退回修改 API（POST /api/requests/:id/reject）
- [x] 7.4 实现批复文档生成服务，使用 docxtemplater 填充模板
- [x] 7.5 实现待审批列表页面（Vue）
- [x] 7.6 实现请示详情页面（Vue），包含审批操作按钮

## 8. 联络员跟踪

- [x] 8.1 实现联络员请示列表 API（GET /api/requests?liaison=me）
- [x] 8.2 实现状态更新 API（PUT /api/requests/:id/status）
- [x] 8.3 实现联络员请示列表页面（Vue）
- [x] 8.4 实现状态更新操作（已签批/已打印/已领取）

## 9. 组织统计

- [x] 9.1 实现组织统计字段的存储（随请示一起保存）
- [x] 9.2 实现统计汇总 API（GET /api/org-stats）
- [x] 9.3 实现统计汇总页面（Vue）
- [x] 9.4 实现统计字段编辑功能（管理员）

## 10. 联络员分配

- [x] 10.1 实现联络员分配 API（PUT /api/requests/:id/liaison）
- [x] 10.2 在请示详情页添加联络员选择组件（管理员）
