<template>
  <div class="dashboard">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>欢迎, {{ authStore.user?.name }}</span>
          <el-tag>{{ roleLabel }}</el-tag>
        </div>
      </template>
      <el-row :gutter="20">
        <el-col :span="6" v-for="item in menuItems" :key="item.path">
          <el-card shadow="hover" @click="router.push(item.path)" class="menu-card">
            <el-icon :size="40"><component :is="item.icon" /></el-icon>
            <h3>{{ item.title }}</h3>
            <p>{{ item.desc }}</p>
          </el-card>
        </el-col>
      </el-row>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

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

const menuItems = computed(() => {
  const role = authStore.user?.role
  const items = []

  if (role === 'applicant') {
    items.push(
      { path: '/requests/new', icon: 'Plus', title: '提交请示', desc: '提交新的请示申请' },
      { path: '/requests', icon: 'List', title: '我的请示', desc: '查看请示状态' }
    )
  }

  if (role === 'approver') {
    items.push(
      { path: '/requests?status=pending', icon: 'Check', title: '待审批', desc: '审批请示' },
      { path: '/requests', icon: 'List', title: '所有请示', desc: '查看所有请示' }
    )
  }

  if (role === 'liaison') {
    items.push(
      { path: '/requests', icon: 'List', title: '我的请示', desc: '跟踪关联请示' }
    )
  }

  if (role === 'admin') {
    items.push(
      { path: '/admin/users', icon: 'User', title: '用户管理', desc: '管理系统用户' },
      { path: '/admin/organizations', icon: 'OfficeBuilding', title: '组织管理', desc: '管理党组织' },
      { path: '/admin/templates', icon: 'Document', title: '模板管理', desc: '管理批复模板' },
      { path: '/admin/batch-numbers', icon: 'Number', title: '批复号管理', desc: '管理批复号序列' },
      { path: '/admin/stats', icon: 'DataAnalysis', title: '统计汇总', desc: '查看组织统计' },
      { path: '/requests', icon: 'List', title: '所有请示', desc: '查看所有请示' }
    )
  }

  return items
})
</script>

<style scoped>
.dashboard {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.menu-card {
  text-align: center;
  cursor: pointer;
  margin-bottom: 20px;
}

.menu-card:hover {
  background-color: #f5f7fa;
}

.menu-card h3 {
  margin: 10px 0 5px;
}

.menu-card p {
  color: #909399;
  font-size: 12px;
}
</style>
