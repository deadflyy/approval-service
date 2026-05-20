# 党组织建设批复系统

党组织建设批复系统是一个线上请示批复管理平台，旨在替代传统的Excel收集、手工匹配Word模板的低效工作方式，实现请示提交、自动匹配模板、在线审批、状态跟踪的全流程管理。

## 功能特性

### 📝 请示提交
- 支持8类请示：成立、换届、增补、调整、更名、撤销、延期、架构调整
- 多步流程支持（成立3步、换届3步、增补2步）
- 动态表单渲染，根据请示类别和进度显示不同字段

### 📑 模板匹配与批复生成
- 根据请示类别和进度自动匹配Word模板
- 使用docxtemplater填充变量生成.docx批复文档
- 保持模板原有格式（字体、行间距）

### ✅ 审批流程
- 完整状态流转：待审批 → 已审批 → 已签批 → 已打印 → 已领取
- 支持退回修改，保留修改历史
- 自动分配批复号（格式：沪张江科综委〔2026〕X号）

### 👥 角色权限
| 角色 | 权限 |
|------|------|
| 申请者 | 提交请示、查看自己提交的请示 |
| 批复者 | 查看所有请示、审批通过/退回修改 |
| 联络员 | 查看关联请示、更新签批/打印/领取状态 |
| 管理员 | 管理用户、模板、组织数据、批复号 |

### 📊 组织统计
- 维护每次请示涉及的组织统计数据
- 支持统计数据查看和修改

## 技术栈

| 分类 | 技术 |
|------|------|
| 前端 | Vue 3 + TypeScript + Vite |
| 后端 | Node.js + Express + TypeScript |
| 数据库 | SQLite |
| 文档生成 | docxtemplater |
| 认证 | JWT |
| 部署 | PM2 |

## 项目结构

```
approval-service/
├── backend/              # 后端服务
│   ├── src/              # 源代码
│   ├── scripts/          # 数据导入脚本
│   └── data/             # SQLite数据库
├── frontend/             # 前端应用
│   ├── src/
│   │   ├── views/        # 页面组件
│   │   ├── components/   # 通用组件
│   │   ├── api/          # API调用
│   │   └── stores/       # 状态管理
│   └── public/           # 静态资源
├── deploy/               # 部署脚本
├── openspec/             # OpenSpec规范文档
└── templates/            # Word模板文件
```

## 快速开始

### 系统要求

| 项目 | 要求 |
|------|------|
| 操作系统 | Ubuntu 20.04+ / CentOS 7+ / RHEL 8+ |
| Node.js | 18.x+ (推荐 LTS) |
| 编译工具 | make, gcc/g++, python3 |

### 一键部署

```bash
# 上传项目到服务器
scp -r approval-service root@服务器IP:/opt/

# 进入部署目录
cd /opt/approval-service/deploy

# 执行一键部署
chmod +x *.sh
./deploy.sh
```

### 服务管理

```bash
# 管理所有服务
./service.sh start|stop|restart|status|logs

# 单独管理后端
./backend.sh start|stop|restart|status|logs

# 单独管理前端
./frontend.sh start|stop|restart|status|logs|build
```

## 访问地址

| 服务 | 地址 |
|------|------|
| 前端 | http://服务器IP:4173 |
| 后端API | http://服务器IP:3000 |

## 默认管理员

> **安全提醒：部署后请立即修改默认密码！**

| 字段 | 值 |
|------|-----|
| 用户名 | `admin` |
| 密码 | `admin123` |

## 详细文档

- **部署指南**: [`deploy/README.md`](deploy/README.md)
- **功能规范**: [`openspec/`](openspec/)

## 许可证

MIT License