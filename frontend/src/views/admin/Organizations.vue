<template>
  <div class="admin-page">
    <!-- Page header -->
    <div class="page-header">
      <div class="header-left">
        <h1 class="page-title">组织管理</h1>
        <p class="page-subtitle">共 {{ pagination.total }} 个组织</p>
      </div>
      <div class="header-right">
        <el-input
          v-model="searchText"
          placeholder="搜索组织..."
          prefix-icon="Search"
          clearable
          class="search-input"
          @input="handleSearch"
        />
        <el-select v-model="levelFilter" placeholder="层级筛选" clearable @change="handleFilterChange" class="filter-select">
          <el-option label="党委" value="party_committee" />
          <el-option label="总支" value="general_branch" />
          <el-option label="支部" value="branch" />
        </el-select>
        <el-button type="primary" @click="showDialog = true">
          <el-icon><Plus /></el-icon>
          新增组织
        </el-button>
      </div>
    </div>

    <!-- Table -->
    <div class="table-wrapper">
      <el-table :data="organizations" style="width: 100%">
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column prop="name" label="组织名称" min-width="240" show-overflow-tooltip />
        <el-table-column prop="level" label="层级" width="100">
          <template #default="{ row }">
            <el-tag :type="levelType(row.level)" size="small" effect="light">
              {{ levelLabel(row.level) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="parent_id" label="上级组织" width="200">
          <template #default="{ row }">
            {{ parentName(row.parent_id) }}
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" width="160" />
        <el-table-column label="操作" width="150" fixed="right" align="center">
          <template #default="{ row }">
            <el-button link type="primary" @click="editOrg(row)">编辑</el-button>
            <el-popconfirm title="确定删除此组织？" @confirm="deleteOrg(row.id)">
              <template #reference>
                <el-button link type="danger">删除</el-button>
              </template>
            </el-popconfirm>
          </template>
        </el-table-column>
      </el-table>

      <!-- Pagination -->
      <Pagination
        :total="pagination.total"
        :page="pagination.page"
        :page-size="pagination.pageSize"
        @update:page="handlePageChange"
        @update:page-size="handlePageSizeChange"
      />
    </div>

    <!-- Dialog -->
    <el-dialog v-model="showDialog" :title="editingOrg ? '编辑组织' : '新增组织'" width="480px">
      <el-form :model="form" label-position="top">
        <el-form-item label="名称" required>
          <el-input v-model="form.name" placeholder="请输入组织名称" />
        </el-form-item>
        <el-form-item label="层级" required>
          <el-select v-model="form.level" placeholder="请选择层级" style="width: 100%">
            <el-option label="党委" value="party_committee" />
            <el-option label="总支" value="general_branch" />
            <el-option label="支部" value="branch" />
          </el-select>
        </el-form-item>
        <el-form-item label="上级组织">
          <el-select v-model="form.parent_id" clearable placeholder="无" style="width: 100%">
            <el-option v-for="org in organizations" :key="org.id" :label="org.name" :value="org.id" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showDialog = false">取消</el-button>
        <el-button type="primary" @click="saveOrg" :loading="loading">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import api from '../../api'
import Pagination from '../../components/Pagination.vue'

const route = useRoute()
const loading = ref(false)
const organizations = ref([])
const searchText = ref('')
const levelFilter = ref('')
const showDialog = ref(false)
const editingOrg = ref<any>(null)
const pagination = ref({
  page: Number(route.query.page) || 1,
  pageSize: Number(route.query.pageSize) || 20,
  total: 0,
  totalPages: 0
})

let searchTimeout: ReturnType<typeof setTimeout> | null = null

const form = ref({
  name: '',
  level: '',
  parent_id: null as number | null
})

function levelType(level: string) {
  const types: Record<string, string> = {
    party_committee: 'danger',
    general_branch: 'warning',
    branch: ''
  }
  return types[level] || 'info'
}

function levelLabel(level: string) {
  const labels: Record<string, string> = {
    party_committee: '党委',
    general_branch: '总支',
    branch: '支部'
  }
  return labels[level] || level
}

function parentName(parentId: number | null) {
  if (!parentId) return '-'
  const parent = organizations.value.find((o: any) => o.id === parentId)
  return parent ? parent.name : '-'
}

function editOrg(org: any) {
  editingOrg.value = org
  form.value = {
    name: org.name,
    level: org.level,
    parent_id: org.parent_id
  }
  showDialog.value = true
}

function handleSearch() {
  if (searchTimeout) {
    clearTimeout(searchTimeout)
  }
  searchTimeout = setTimeout(() => {
    pagination.value.page = 1
    loadOrganizations()
  }, 300)
}

function handleFilterChange() {
  pagination.value.page = 1
  loadOrganizations()
}

function handlePageChange(page: number) {
  pagination.value.page = page
  loadOrganizations()
}

function handlePageSizeChange(pageSize: number) {
  pagination.value.pageSize = pageSize
  pagination.value.page = 1
  loadOrganizations()
}

async function saveOrg() {
  if (!form.value.name || !form.value.level) {
    ElMessage.warning('请填写所有必填字段')
    return
  }

  loading.value = true
  try {
    if (editingOrg.value) {
      await api.put(`/organizations/${editingOrg.value.id}`, form.value)
    } else {
      await api.post('/organizations', form.value)
    }
    ElMessage.success('保存成功')
    showDialog.value = false
    editingOrg.value = null
    form.value = { name: '', level: '', parent_id: null }
    loadOrganizations()
  } catch (error: any) {
    ElMessage.error(error.response?.data?.error || '保存失败')
  } finally {
    loading.value = false
  }
}

async function deleteOrg(id: number) {
  try {
    await api.delete(`/organizations/${id}`)
    ElMessage.success('删除成功')
    loadOrganizations()
  } catch (error: any) {
    ElMessage.error(error.response?.data?.error || '删除失败')
  }
}

async function loadOrganizations() {
  try {
    const params: any = {
      page: pagination.value.page,
      pageSize: pagination.value.pageSize
    }
    if (searchText.value) {
      params.keyword = searchText.value
    }
    if (levelFilter.value) {
      params.level = levelFilter.value
    }
    const response = await api.get('/organizations', { params })
    organizations.value = response.data.data
    pagination.value.total = response.data.pagination.total
    pagination.value.totalPages = response.data.pagination.totalPages
  } catch (error) {
    console.error('获取组织列表失败:', error)
  }
}

onMounted(() => {
  loadOrganizations()
})
</script>

<style scoped>
.admin-page {
  padding: 28px 32px;
  max-width: 1200px;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  margin-bottom: 24px;
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
  width: 200px;
}

.filter-select {
  width: 120px;
}

.table-wrapper {
  background: var(--bg-card);
  border-radius: var(--radius-lg);
  border: 1px solid var(--border-light);
  overflow: hidden;
}

@media (max-width: 1024px) {
  .admin-page {
    padding: 20px 16px;
  }

  .page-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 16px;
  }
}
</style>
