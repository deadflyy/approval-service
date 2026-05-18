<template>
  <div class="dashboard">
    <!-- Page header -->
    <div class="page-header">
      <div class="header-left">
        <h1 class="page-title">工作台</h1>
        <p class="page-subtitle">欢迎回来，{{ authStore.user?.name }}</p>
      </div>
      <div class="header-right">
        <div class="header-date">
          <el-icon><Calendar /></el-icon>
          <span>{{ currentDate }}</span>
        </div>
      </div>
    </div>

    <!-- Stats cards -->
    <div class="stats-grid">
      <div class="stat-card stat-card-primary">
        <div class="stat-icon">
          <el-icon><Document /></el-icon>
        </div>
        <div class="stat-content">
          <span class="stat-value">{{ stats.total || 0 }}</span>
          <span class="stat-label">总请示数</span>
        </div>
      </div>
      <div class="stat-card stat-card-warning">
        <div class="stat-icon">
          <el-icon><Clock /></el-icon>
        </div>
        <div class="stat-content">
          <span class="stat-value">{{ stats.pending || 0 }}</span>
          <span class="stat-label">待审批</span>
        </div>
      </div>
      <div class="stat-card stat-card-success">
        <div class="stat-icon">
          <el-icon><CircleCheck /></el-icon>
        </div>
        <div class="stat-content">
          <span class="stat-value">{{ stats.approved || 0 }}</span>
          <span class="stat-label">已通过</span>
        </div>
      </div>
      <div class="stat-card stat-card-danger">
        <div class="stat-icon">
          <el-icon><CircleClose /></el-icon>
        </div>
        <div class="stat-content">
          <span class="stat-value">{{ stats.rejected || 0 }}</span>
          <span class="stat-label">已退回</span>
        </div>
      </div>
    </div>

    <!-- Quick actions -->
    <div class="section">
      <h2 class="section-title">快捷操作</h2>
      <div class="actions-grid">
        <div
          v-for="item in menuItems"
          :key="item.path"
          class="action-card"
          @click="router.push(item.path)"
        >
          <div class="action-icon" :style="{ background: item.color }">
            <el-icon><component :is="item.icon" /></el-icon>
          </div>
          <div class="action-content">
            <h3>{{ item.title }}</h3>
            <p>{{ item.desc }}</p>
          </div>
          <el-icon class="action-arrow"><ArrowRight /></el-icon>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import api from '../api'

const router = useRouter()
const authStore = useAuthStore()

const stats = ref({
  total: 0,
  pending: 0,
  approved: 0,
  rejected: 0
})

const currentDate = computed(() => {
  const now = new Date()
  const weekdays = ['日', '一', '二', '三', '四', '五', '六']
  return `${now.getFullYear()}年${now.getMonth() + 1}月${now.getDate()}日 星期${weekdays[now.getDay()]}`
})

const menuItems = computed(() => {
  const role = authStore.user?.role
  const items = []

  if (role === 'applicant') {
    items.push(
      { path: '/requests/new', icon: 'Plus', title: '提交请示', desc: '创建新的请示申请', color: 'linear-gradient(135deg, #3d52f5 0%, #6078ff 100%)' },
      { path: '/requests', icon: 'Document', title: '我的请示', desc: '查看请示审批状态', color: 'linear-gradient(135deg, #10b981 0%, #34d399 100%)' }
    )
  }

  if (role === 'approver') {
    items.push(
      { path: '/requests?status=pending', icon: 'Bell', title: '待审批', desc: '审批待处理的请示', color: 'linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%)' },
      { path: '/requests', icon: 'Document', title: '所有请示', desc: '查看全部请示记录', color: 'linear-gradient(135deg, #3d52f5 0%, #6078ff 100%)' }
    )
  }

  if (role === 'liaison') {
    items.push(
      { path: '/requests', icon: 'Document', title: '我的请示', desc: '跟踪关联请示进度', color: 'linear-gradient(135deg, #3d52f5 0%, #6078ff 100%)' }
    )
  }

  if (role === 'admin') {
    items.push(
      { path: '/requests', icon: 'Document', title: '所有请示', desc: '查看全部请示记录', color: 'linear-gradient(135deg, #3d52f5 0%, #6078ff 100%)' },
      { path: '/admin/users', icon: 'User', title: '用户管理', desc: '管理系统用户账号', color: 'linear-gradient(135deg, #8b5cf6 0%, #a78bfa 100%)' },
      { path: '/admin/templates', icon: 'Files', title: '模板管理', desc: '管理批复文档模板', color: 'linear-gradient(135deg, #10b981 0%, #34d399 100%)' },
      { path: '/admin/stats', icon: 'DataAnalysis', title: '统计汇总', desc: '查看组织统计数据', color: 'linear-gradient(135deg, #f59e0b 0%, #fbbf24 100%)' }
    )
  }

  return items
})

onMounted(async () => {
  try {
    const response = await api.get('/requests')
    const requests = response.data.data
    stats.value = {
      total: requests.length,
      pending: requests.filter((r: any) => r.status === 'pending').length,
      approved: requests.filter((r: any) => r.status === 'approved' || r.status === 'signed' || r.status === 'printed' || r.status === 'collected').length,
      rejected: requests.filter((r: any) => r.status === 'rejected').length
    }
  } catch (error) {
    console.error('获取统计数据失败:', error)
  }
})
</script>

<style scoped>
.dashboard {
  padding: 28px 32px;
  max-width: 1200px;
}

/* Page header */
.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  margin-bottom: 28px;
}

.page-title {
  font-size: 26px;
  font-weight: 700;
  color: var(--text-primary);
  letter-spacing: -0.02em;
  line-height: 1.2;
}

.page-subtitle {
  color: var(--text-muted);
  font-size: 14px;
  margin-top: 4px;
}

.header-date {
  display: flex;
  align-items: center;
  gap: 6px;
  color: var(--text-muted);
  font-size: 13px;
  background: var(--bg-card);
  padding: 8px 14px;
  border-radius: var(--radius-md);
  border: 1px solid var(--border-light);
}

/* Stats grid */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin-bottom: 32px;
}

.stat-card {
  background: var(--bg-card);
  border-radius: var(--radius-lg);
  padding: 20px;
  display: flex;
  align-items: center;
  gap: 16px;
  border: 1px solid var(--border-light);
  transition: all var(--transition-base);
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-lg);
}

.stat-icon {
  width: 48px;
  height: 48px;
  border-radius: var(--radius-md);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 22px;
  flex-shrink: 0;
}

.stat-card-primary .stat-icon {
  background: var(--primary-50);
  color: var(--primary-500);
}

.stat-card-warning .stat-icon {
  background: var(--warning-light);
  color: var(--warning);
}

.stat-card-success .stat-icon {
  background: var(--success-light);
  color: var(--success);
}

.stat-card-danger .stat-icon {
  background: var(--danger-light);
  color: var(--danger);
}

.stat-content {
  display: flex;
  flex-direction: column;
}

.stat-value {
  font-size: 28px;
  font-weight: 700;
  color: var(--text-primary);
  line-height: 1.1;
  letter-spacing: -0.02em;
}

.stat-label {
  font-size: 13px;
  color: var(--text-muted);
  margin-top: 2px;
}

/* Section */
.section {
  margin-bottom: 32px;
}

.section-title {
  font-size: 16px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 16px;
}

/* Actions grid */
.actions-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 12px;
}

.action-card {
  background: var(--bg-card);
  border: 1px solid var(--border-light);
  border-radius: var(--radius-lg);
  padding: 18px 20px;
  display: flex;
  align-items: center;
  gap: 14px;
  cursor: pointer;
  transition: all var(--transition-base);
}

.action-card:hover {
  border-color: var(--primary-200);
  box-shadow: var(--shadow-md);
  transform: translateX(4px);
}

.action-icon {
  width: 44px;
  height: 44px;
  border-radius: var(--radius-md);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 20px;
  color: #fff;
  flex-shrink: 0;
}

.action-content {
  flex: 1;
}

.action-content h3 {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 2px;
}

.action-content p {
  font-size: 12px;
  color: var(--text-muted);
}

.action-arrow {
  color: var(--gray-300);
  font-size: 16px;
  transition: all var(--transition-fast);
}

.action-card:hover .action-arrow {
  color: var(--primary-500);
  transform: translateX(4px);
}

@media (max-width: 1024px) {
  .dashboard {
    padding: 20px 16px;
  }

  .stats-grid {
    grid-template-columns: repeat(2, 1fr);
  }

  .actions-grid {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 640px) {
  .stats-grid {
    grid-template-columns: 1fr;
  }
}
</style>
