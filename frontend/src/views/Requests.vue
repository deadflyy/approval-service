<template>
  <div class="requests-page">
    <!-- Page header -->
    <div class="page-header">
      <div class="header-left">
        <h1 class="page-title">{{ title }}</h1>
        <p class="page-subtitle">共 {{ requests.length }} 条记录</p>
      </div>
      <div class="header-right">
        <el-input
          v-model="searchText"
          placeholder="搜索请示..."
          prefix-icon="Search"
          clearable
          class="search-input"
        />
        <el-button v-if="authStore.user?.role === 'applicant'" type="primary" @click="router.push('/requests/new')">
          <el-icon><Plus /></el-icon>
          提交请示
        </el-button>
      </div>
    </div>

    <!-- Filters -->
    <div class="filters-bar">
      <el-radio-group v-model="statusFilter" size="small">
        <el-radio-button label="">全部</el-radio-button>
        <el-radio-button label="pending">待审批</el-radio-button>
        <el-radio-button label="approved">已通过</el-radio-button>
        <el-radio-button label="rejected">已退回</el-radio-button>
        <el-radio-button label="signed">已签批</el-radio-button>
        <el-radio-button label="collected">已领取</el-radio-button>
      </el-radio-group>
    </div>

    <!-- Table -->
    <div class="table-wrapper">
      <el-table :data="filteredRequests" style="width: 100%" :header-cell-style="{ background: 'var(--gray-50)' }">
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column prop="org_name" label="组织" min-width="180" show-overflow-tooltip />
        <el-table-column prop="title" label="标题" min-width="240" show-overflow-tooltip />
        <el-table-column prop="category" label="类别" width="80">
          <template #default="{ row }">
            <span class="category-tag">{{ row.category }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="step" label="进度" width="90" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="statusType(row.status)" size="small" effect="light">
              {{ statusLabel(row.status) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="batch_number" label="批复号" width="160" show-overflow-tooltip />
        <el-table-column prop="created_at" label="提交时间" width="110" />
        <el-table-column label="操作" width="80" fixed="right" align="center">
          <template #default="{ row }">
            <el-button link type="primary" @click="router.push(`/requests/${row.id}`)" class="detail-btn">
              详情
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import api from '../api'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()
const requests = ref([])
const searchText = ref('')
const statusFilter = ref(route.query.status as string || '')

const title = computed(() => {
  if (authStore.user?.role === 'liaison') return '我的请示'
  if (authStore.user?.role === 'applicant') return '我的请示'
  return '所有请示'
})

const filteredRequests = computed(() => {
  let result = requests.value

  if (statusFilter.value) {
    result = result.filter((r: any) => r.status === statusFilter.value)
  }

  if (searchText.value) {
    const search = searchText.value.toLowerCase()
    result = result.filter((r: any) =>
      r.title?.toLowerCase().includes(search) ||
      r.org_name?.toLowerCase().includes(search)
    )
  }

  return result
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
  return types[status] || 'info'
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

watch(statusFilter, (val) => {
  router.replace({ query: val ? { status: val } : {} })
})

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
.requests-page {
  padding: 28px 32px;
  max-width: 1400px;
}

/* Page header */
.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  margin-bottom: 20px;
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
  font-size: 13px;
  margin-top: 4px;
}

.header-right {
  display: flex;
  align-items: center;
  gap: 12px;
}

.search-input {
  width: 240px;
}

/* Filters */
.filters-bar {
  margin-bottom: 16px;
  padding: 12px 16px;
  background: var(--bg-card);
  border-radius: var(--radius-lg);
  border: 1px solid var(--border-light);
}

.filters-bar :deep(.el-radio-button__inner) {
  border: none;
  background: transparent;
  padding: 6px 14px;
  font-size: 13px;
  font-weight: 500;
  color: var(--text-secondary);
  box-shadow: none !important;
}

.filters-bar :deep(.el-radio-button__original-radio:checked + .el-radio-button__inner) {
  background: var(--primary-50);
  color: var(--primary-600);
  border-radius: var(--radius-sm);
}

/* Table */
.table-wrapper {
  background: var(--bg-card);
  border-radius: var(--radius-lg);
  border: 1px solid var(--border-light);
  overflow: hidden;
}

.category-tag {
  font-size: 12px;
  font-weight: 500;
  color: var(--primary-600);
  background: var(--primary-50);
  padding: 2px 8px;
  border-radius: 4px;
}

.detail-btn {
  font-weight: 500;
}

@media (max-width: 1024px) {
  .requests-page {
    padding: 20px 16px;
  }

  .page-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 16px;
  }

  .header-right {
    width: 100%;
  }

  .search-input {
    flex: 1;
  }
}
</style>
