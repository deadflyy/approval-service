<template>
  <el-config-provider :locale="zhCn">
    <div v-if="authStore.isAuthenticated" class="app-layout">
      <!-- Sidebar -->
      <aside class="sidebar">
        <div class="sidebar-header">
          <div class="logo-mark">
            <svg width="28" height="28" viewBox="0 0 28 28" fill="none">
              <rect width="28" height="28" rx="8" fill="url(#logo-grad)"/>
              <path d="M8 14L12 18L20 10" stroke="white" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
              <defs>
                <linearGradient id="logo-grad" x1="0" y1="0" x2="28" y2="28">
                  <stop stop-color="#6078ff"/>
                  <stop offset="1" stop-color="#3d52f5"/>
                </linearGradient>
              </defs>
            </svg>
          </div>
          <div class="logo-text">
            <span class="logo-title">请示批复</span>
            <span class="logo-sub">审批管理系统</span>
          </div>
        </div>

        <nav class="sidebar-nav">
          <router-link to="/dashboard" class="nav-item" :class="{ active: route.path === '/dashboard' }">
            <el-icon><HomeFilled /></el-icon>
            <span>首页</span>
          </router-link>

          <template v-if="authStore.user?.role === 'applicant'">
            <router-link to="/requests/new" class="nav-item" :class="{ active: route.path === '/requests/new' }">
              <el-icon><Plus /></el-icon>
              <span>提交请示</span>
            </router-link>
            <router-link to="/requests" class="nav-item" :class="{ active: route.path === '/requests' && !route.query.status }">
              <el-icon><Document /></el-icon>
              <span>我的请示</span>
            </router-link>
          </template>

          <template v-if="authStore.user?.role === 'approver'">
            <router-link to="/requests?status=pending" class="nav-item" :class="{ active: route.query.status === 'pending' }">
              <el-icon><Bell /></el-icon>
              <span>待审批</span>
              <span class="nav-badge" v-if="pendingCount > 0">{{ pendingCount }}</span>
            </router-link>
            <router-link to="/requests" class="nav-item" :class="{ active: route.path === '/requests' && !route.query.status }">
              <el-icon><Document /></el-icon>
              <span>所有请示</span>
            </router-link>
          </template>

          <template v-if="authStore.user?.role === 'liaison'">
            <router-link to="/requests" class="nav-item" :class="{ active: route.path === '/requests' }">
              <el-icon><Document /></el-icon>
              <span>我的请示</span>
            </router-link>
          </template>

          <template v-if="authStore.user?.role === 'admin'">
            <router-link to="/requests" class="nav-item" :class="{ active: route.path === '/requests' && !route.query.status }">
              <el-icon><Document /></el-icon>
              <span>所有请示</span>
            </router-link>

            <div class="nav-divider"></div>
            <div class="nav-section-title">系统管理</div>

            <router-link to="/admin/users" class="nav-item" :class="{ active: route.path === '/admin/users' }">
              <el-icon><User /></el-icon>
              <span>用户管理</span>
            </router-link>
            <router-link to="/admin/organizations" class="nav-item" :class="{ active: route.path === '/admin/organizations' }">
              <el-icon><OfficeBuilding /></el-icon>
              <span>组织管理</span>
            </router-link>
            <router-link to="/admin/templates" class="nav-item" :class="{ active: route.path === '/admin/templates' }">
              <el-icon><Files /></el-icon>
              <span>模板管理</span>
            </router-link>
            <router-link to="/admin/batch-numbers" class="nav-item" :class="{ active: route.path === '/admin/batch-numbers' }">
              <el-icon><Tickets /></el-icon>
              <span>批复号管理</span>
            </router-link>
            <router-link to="/admin/stats" class="nav-item" :class="{ active: route.path === '/admin/stats' }">
              <el-icon><DataAnalysis /></el-icon>
              <span>统计汇总</span>
            </router-link>
          </template>
        </nav>

        <div class="sidebar-footer">
          <div class="user-avatar">{{ authStore.user?.name?.charAt(0) }}</div>
          <div class="user-info">
            <span class="user-name">{{ authStore.user?.name }}</span>
            <span class="user-role">{{ roleLabel }}</span>
          </div>
          <button class="logout-btn" @click="logout" title="退出登录">
            <el-icon><SwitchButton /></el-icon>
          </button>
        </div>
      </aside>

      <!-- Main content -->
      <main class="main-content">
        <router-view />
      </main>
    </div>

    <router-view v-else />
  </el-config-provider>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from './stores/auth'
import zhCn from 'element-plus/es/locale/lang/zh-cn'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const pendingCount = ref(0)

const roleLabel = computed(() => {
  const labels: Record<string, string> = {
    applicant: '申请者',
    approver: '批复者',
    liaison: '联络员',
    admin: '管理员'
  }
  return labels[authStore.user?.role || ''] || ''
})

function logout() {
  authStore.logout()
  router.push('/login')
}
</script>

<style scoped>
.app-layout {
  display: flex;
  min-height: 100vh;
}

/* Sidebar */
.sidebar {
  width: 240px;
  background: var(--bg-sidebar);
  display: flex;
  flex-direction: column;
  position: fixed;
  top: 0;
  left: 0;
  bottom: 0;
  z-index: 100;
  overflow-y: auto;
}

.sidebar-header {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 20px 20px 24px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
}

.logo-mark {
  flex-shrink: 0;
}

.logo-text {
  display: flex;
  flex-direction: column;
}

.logo-title {
  color: #fff;
  font-size: 16px;
  font-weight: 600;
  letter-spacing: 0.02em;
  line-height: 1.2;
}

.logo-sub {
  color: var(--gray-400);
  font-size: 11px;
  font-weight: 400;
  letter-spacing: 0.04em;
  margin-top: 2px;
}

.sidebar-nav {
  flex: 1;
  padding: 12px 10px;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 14px;
  border-radius: var(--radius-md);
  color: var(--gray-400);
  text-decoration: none;
  font-size: 13.5px;
  font-weight: 450;
  transition: all var(--transition-fast);
  position: relative;
}

.nav-item:hover {
  color: var(--gray-200);
  background: rgba(255, 255, 255, 0.06);
}

.nav-item.active {
  color: #fff;
  background: rgba(61, 82, 245, 0.2);
}

.nav-item.active::before {
  content: '';
  position: absolute;
  left: 0;
  top: 50%;
  transform: translateY(-50%);
  width: 3px;
  height: 20px;
  background: var(--primary-400);
  border-radius: 0 3px 3px 0;
}

.nav-item .el-icon {
  font-size: 17px;
  flex-shrink: 0;
}

.nav-badge {
  margin-left: auto;
  background: var(--danger);
  color: #fff;
  font-size: 11px;
  font-weight: 600;
  padding: 1px 7px;
  border-radius: 10px;
  min-width: 18px;
  text-align: center;
}

.nav-divider {
  height: 1px;
  background: rgba(255, 255, 255, 0.08);
  margin: 8px 14px;
}

.nav-section-title {
  color: var(--gray-500);
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  padding: 8px 14px 4px;
}

/* Sidebar footer */
.sidebar-footer {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 16px 16px 20px;
  border-top: 1px solid rgba(255, 255, 255, 0.08);
}

.user-avatar {
  width: 34px;
  height: 34px;
  border-radius: 10px;
  background: linear-gradient(135deg, var(--primary-500) 0%, var(--primary-400) 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  font-size: 14px;
  font-weight: 600;
  flex-shrink: 0;
}

.user-info {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
}

.user-name {
  color: var(--gray-200);
  font-size: 13px;
  font-weight: 500;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.user-role {
  color: var(--gray-500);
  font-size: 11px;
  font-weight: 400;
}

.logout-btn {
  background: none;
  border: none;
  color: var(--gray-500);
  cursor: pointer;
  padding: 6px;
  border-radius: var(--radius-sm);
  transition: all var(--transition-fast);
  display: flex;
  align-items: center;
  justify-content: center;
}

.logout-btn:hover {
  color: var(--danger);
  background: rgba(239, 68, 68, 0.1);
}

/* Main content */
.main-content {
  flex: 1;
  margin-left: 240px;
  min-height: 100vh;
  background: var(--bg-app);
}

</style>
