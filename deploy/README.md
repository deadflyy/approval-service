# 党组织建设批复系统 - Ubuntu 24.04 部署手册

## 项目简介

本系统是一个基于 Node.js 的党组织建设批复管理系统，包含前后端分离架构：
- 后端：Express + TypeScript + SQLite
- 前端：Vue3 + Vite + Element Plus

## 系统要求

- 操作系统：Ubuntu 24.04 LTS
- Node.js：18.x 或更高版本
- npm：8.x 或更高版本
- 推荐服务器配置：2核4G

## 快速开始

### 1. 上传项目文件

将整个项目上传到服务器，推荐目录：`/opt/approval-service`

```bash
# 在本地执行（假设服务器IP为1.2.3.4）
scp -r approval-service root@1.2.3.4:/opt/
```

### 2. 一键部署

```bash
cd /opt/approval-service/deploy
chmod +x *.sh
./deploy.sh
```

### 3. 服务管理

```bash
# 后端服务管理
./backend.sh start
./backend.sh stop
./backend.sh restart
./backend.sh status

# 前端服务管理
./frontend.sh start
./frontend.sh stop
./frontend.sh restart
./frontend.sh status
```

## 默认账号

- 用户名：`admin`
- 密码：`admin123`
- 角色：系统管理员

## 端口说明

- 后端服务：`http://localhost:3000`
- 前端服务：`http://localhost:5174`

## 详细部署步骤

### 步骤1：环境准备

系统会自动检测并安装以下组件：
- Node.js 18.x
- npm
- git
- build-essential
- pm2（用于进程管理）

### 步骤2：后端部署

- 安装后端依赖
- 初始化数据库（创建默认管理员）
- 导入模板文件
- 使用 pm2 启动后端服务

### 步骤3：前端部署

- 安装前端依赖
- 构建前端产物
- 使用 pm2 启动前端预览服务

### 步骤4：访问系统

在浏览器访问 `http://服务器IP:5174` 或配置 Nginx 反向代理后访问。

## Nginx 反向代理配置（可选）

创建 `/etc/nginx/sites-available/approval-service`：

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:5174;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_cache_bypass $http_upgrade;
    }

    location /api {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

启用配置：
```bash
ln -s /etc/nginx/sites-available/approval-service /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
```

## 目录结构

```
/opt/approval-service/
├── backend/              # 后端代码
│   ├── src/
│   ├── data/            # SQLite数据库
│   └── package.json
├── frontend/            # 前端代码
│   ├── src/
│   ├── dist/           # 构建产物
│   └── package.json
├── templates/           # 模板文件
└── deploy/             # 部署脚本
```

## 数据备份

### 备份数据库
```bash
cp /opt/approval-service/backend/data/approval.db /opt/approval-service/backup/approval.db.$(date +%Y%m%d)
```

### 备份模板
```bash
cp -r /opt/approval-service/templates /opt/approval-service/backup/templates.$(date +%Y%m%d)
```

## 常见问题

### 服务无法启动
检查 pm2 日志：
```bash
pm2 logs approval-backend
pm2 logs approval-frontend
```

### 端口被占用
修改端口配置或停止占用进程：
```bash
lsof -ti:3000 | xargs kill -9
lsof -ti:5174 | xargs kill -9
```

### 权限问题
确保项目目录权限正确：
```bash
chown -R www-data:www-data /opt/approval-service
chmod -R 755 /opt/approval-service
```

## 技术支持

如有问题，请检查：
1. Node.js 版本
2. npm 依赖是否完整安装
3. pm2 进程状态
4. 系统防火墙配置
