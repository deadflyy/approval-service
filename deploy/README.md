# 党组织建设批复系统 - 部署手册

## 系统要求

| 项目 | 要求 |
|------|------|
| 操作系统 | Ubuntu 20.04+ / CentOS 7+ / RHEL 8+ |
| Node.js | 18.x+ (推荐 LTS) |
| 编译工具 | make, gcc/g++, python3 (node-gyp 编译 better-sqlite3) |
| 内存 | >= 2GB |
| 磁盘 | >= 1GB |

> better-sqlite3 需要通过 node-gyp 编译原生模块，服务器需安装 make/gcc/g++/python3（部署脚本会自动安装）。

## 快速部署

### 1. 上传项目

```bash
scp -r approval-service root@服务器IP:/opt/
```

### 2. 一键部署

```bash
cd /opt/approval-service/deploy
chmod +x *.sh
./deploy.sh
```

部署过程自动完成：环境检测 -> 依赖安装 -> node-gyp 编译 better-sqlite3 -> 数据库初始化 -> 服务启动。

> 如果检测到已有服务在运行，脚本会提示确认是否重新部署。

## 服务管理

```bash
cd /opt/approval-service/deploy

# 管理所有服务
./service.sh start|stop|restart|status|logs

# 单独管理后端
./backend.sh start|stop|restart|status|logs

# 单独管理前端
./frontend.sh start|stop|restart|status|logs|build
```

## 脚本说明

| 脚本 | 用途 |
|------|------|
| `deploy.sh` | 一键部署（首次使用） |
| `setup-env.sh` | 环境检测与依赖安装 |
| `init-db.sh` | 数据库初始化（可重复运行，自动备份） |
| `service.sh` | 综合服务管理（启停所有服务） |
| `backend.sh` | 后端服务管理 |
| `frontend.sh` | 前端服务管理 |
| `fix-sqlite3.sh` | 修复 better-sqlite3（安装编译工具 + node-gyp 编译） |
| `quick-start.sh` | 显示可用命令 |
| `common.sh` | 公共函数库（被其他脚本引用） |
| `pm2.config.js` | PM2 进程管理配置 |
| `import-templates.js` | Word 模板导入工具 |

## 访问地址

| 服务 | 地址 |
|------|------|
| 前端 | http://服务器IP:4173 |
| 后端 API | http://服务器IP:3000 |

## 默认管理员

> **安全提醒：部署后请立即修改默认密码！**

| 字段 | 值 |
|------|-----|
| 用户名 | `admin` |
| 密码 | `admin123` |
| 角色 | 系统管理员 |

## 目录结构

```
/opt/approval-service/
├── backend/              # 后端代码
│   ├── src/              # 源码
│   └── data/             # SQLite 数据库 + 模板文件
├── frontend/             # 前端代码
├── templates/            # Word 模板源文件
├── logs/                 # PM2 日志
└── deploy/               # 部署脚本
```

## Nginx 反向代理（可选）

如需通过 80/443 端口访问，配置 Nginx：

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:4173;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
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

## 数据备份

数据库文件位于 `backend/data/approval.db`，备份方法：

```bash
# 手动备份
cp /opt/approval-service/backend/data/approval.db /opt/approval-service/backend/data/approval.db.$(date +%Y%m%d).backup

# 使用 init-db.sh 会自动备份已有数据库
./init-db.sh
```

## 故障排查

### better-sqlite3 不可用

```bash
# 自动安装编译工具并重新编译
cd /opt/approval-service/deploy
./fix-sqlite3.sh
```

手动编译：

```bash
cd /opt/approval-service/backend
npx --yes node-gyp rebuild --directory=node_modules/better-sqlite3
```

### 端口被占用

```bash
lsof -i :3000
lsof -i :4173
./service.sh stop && ./service.sh start
```

### 查看日志

```bash
pm2 logs approval-backend
pm2 logs approval-frontend
```

### 重置数据库

```bash
cp backend/data/approval.db backend/data/approval.db.bak
rm backend/data/approval.db
./init-db.sh
```
