<template>
  <el-config-provider :locale="zhCn">
    <div v-if="authStore.isAuthenticated" class="app-layout">
      <el-container>
        <el-header>
          <div class="header-content">
            <h1>请示批复系统</h1>
            <div class="header-right">
              <span>{{ authStore.user?.name }}</span>
              <el-tag style="margin-left: 10px;">{{ roleLabel }}</el-tag>
              <el-button link @click="logout" style="margin-left: 20px;">退出</el-button>
            </div>
          </div>
        </el-header>
        <el-container>
          <el-aside width="200px">
            <el-menu :default-active="route.path" router>
              <el-menu-item index="/dashboard">
                <el-icon><HomeFilled /></el-icon>
                <span>首页</span>
              </el-menu-item>

              <template v-if="authStore.user?.role === 'applicant'">
                <el-menu-item index="/requests/new">
                  <el-icon><Plus /></el-icon>
                  <span>提交请示</span>
                </el-menu-item>
                <el-menu-item index="/requests">
                  <el-icon><List /></el-icon>
                  <span>我的请示</span>
                </el-menu-item>
              </template>

              <template v-if="authStore.user?.role === 'approver'">
                <el-menu-item index="/requests?status=pending">
                  <el-icon><Check /></el-icon>
                  <span>待审批</span>
                </el-menu-item>
                <el-menu-item index="/requests">
                  <el-icon><List /></el-icon>
                  <span>所有请示</span>
                </el-menu-item>
              </template>

              <template v-if="authStore.user?.role === 'liaison'">
                <el-menu-item index="/requests">
                  <el-icon><List /></el-icon>
                  <span>我的请示</span>
                </el-menu-item>
              </template>

              <template v-if="authStore.user?.role === 'admin'">
                <el-menu-item index="/requests">
                  <el-icon><List /></el-icon>
                  <span>所有请示</span>
                </el-menu-item>
                <el-sub-menu index="admin">
                  <template #title>
                    <el-icon><Setting /></el-icon>
                    <span>系统管理</span>
                  </template>
                  <el-menu-item index="/admin/users">用户管理</el-menu-item>
                  <el-menu-item index="/admin/organizations">组织管理</el-menu-item>
                  <el-menu-item index="/admin/templates">模板管理</el-menu-item>
                  <el-menu-item index="/admin/batch-numbers">批复号管理</el-menu-item>
                  <el-menu-item index="/admin/stats">统计汇总</el-menu-item>
                </el-sub-menu>
              </template>
            </el-menu>
          </el-aside>
          <el-main>
            <router-view />
          </el-main>
        </el-container>
      </el-container>
    </div>
    <router-view v-else />
  </el-config-provider>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from './stores/auth'
import zhCn from 'element-plus/es/locale/lang/zh-cn'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()

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

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
}

.app-layout {
  min-height: 100vh;
}

.el-header {
  background-color: #409eff;
  color: white;
  display: flex;
  align-items: center;
}

.header-content {
  width: 100%;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-content h1 {
  font-size: 20px;
  font-weight: 500;
}

.header-right {
  display: flex;
  align-items: center;
}

.el-aside {
  background-color: #304156;
}

.el-menu {
  border-right: none;
}

.el-main {
  background-color: #f5f7fa;
  min-height: calc(100vh - 60px);
}
</style>
