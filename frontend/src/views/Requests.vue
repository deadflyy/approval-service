<template>
  <div class="requests">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>{{ title }}</span>
          <el-button v-if="authStore.user?.role === 'applicant'" type="primary" @click="router.push('/requests/new')">
            提交请示
          </el-button>
        </div>
      </template>

      <el-table :data="requests" style="width: 100%">
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column prop="org_name" label="组织" width="200" show-overflow-tooltip />
        <el-table-column prop="title" label="标题" show-overflow-tooltip />
        <el-table-column prop="category" label="类别" width="80" />
        <el-table-column prop="step" label="进度" width="80" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="statusType(row.status)">{{ statusLabel(row.status) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="batch_number" label="批复号" width="160" />
        <el-table-column prop="created_at" label="提交时间" width="160" />
        <el-table-column label="操作" width="100" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="router.push(`/requests/${row.id}`)">查看</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import api from '../api'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()
const requests = ref([])

const title = computed(() => {
  if (route.query.status === 'pending') return '待审批列表'
  if (authStore.user?.role === 'liaison') return '我的请示'
  if (authStore.user?.role === 'applicant') return '我的请示'
  return '所有请示'
})

function statusType(status: string) {
  const types: Record<string, string> = {
    pending: 'warning',
    approved: 'success',
    rejected: 'danger',
    signed: '',
    printed: 'success',
    collected: 'success'
  }
  return types[status] || ''
}

function statusLabel(status: string) {
  const labels: Record<string, string> = {
    draft: '草稿',
    pending: '待审批',
    approved: '已审批',
    rejected: '退回修改',
    signed: '已签批',
    printed: '已打印',
    collected: '已领取'
  }
  return labels[status] || status
}

onMounted(async () => {
  try {
    const params: any = {}
    if (route.query.status) {
      params.status = route.query.status
    }
    const response = await api.get('/requests', { params })
    requests.value = response.data
  } catch (error) {
    console.error('获取请示列表失败:', error)
  }
})
</script>

<style scoped>
.requests {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
