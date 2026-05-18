<template>
  <div class="admin-page">
    <!-- Page header -->
    <div class="page-header">
      <div class="header-left">
        <h1 class="page-title">用户管理</h1>
        <p class="page-subtitle">共 {{ pagination.total }} 个用户</p>
      </div>
      <div class="header-right">
        <el-input
          v-model="searchText"
          placeholder="搜索用户..."
          prefix-icon="Search"
          clearable
          class="search-input"
          @input="handleSearch"
        />
        <el-select v-model="roleFilter" placeholder="角色筛选" clearable @change="handleFilterChange" class="filter-select">
          <el-option label="申请者" value="applicant" />
          <el-option label="批复者" value="approver" />
          <el-option label="联络员" value="liaison" />
          <el-option label="管理员" value="admin" />
        </el-select>
        <el-button type="primary" @click="showDialog = true">
          <el-icon><Plus /></el-icon>
          新增用户
        </el-button>
      </div>
    </div>

    <!-- Table -->
    <div class="table-wrapper">
      <el-table :data="users" style="width: 100%">
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column prop="username" label="用户名" width="140" />
        <el-table-column prop="name" label="姓名" width="120" />
        <el-table-column prop="role" label="角色" width="100">
          <template #default="{ row }">
            <el-tag :type="roleType(row.role)" size="small" effect="light">
              {{ roleLabel(row.role) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" min-width="160" />
        <el-table-column label="操作" width="200" fixed="right" align="center">
          <template #default="{ row }">
            <el-button link type="primary" @click="editUser(row)">编辑</el-button>
            <el-button link type="primary" @click="editAuth(row)">授权</el-button>
            <el-popconfirm title="确定删除此用户？" @confirm="deleteUser(row.id)">
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

    <!-- User dialog -->
    <el-dialog v-model="showDialog" :title="editingUser ? '编辑用户' : '新增用户'" width="480px">
      <el-form :model="form" label-position="top">
        <el-form-item label="用户名" required>
          <el-input v-model="form.username" :disabled="!!editingUser" placeholder="请输入用户名" />
        </el-form-item>
        <el-form-item label="姓名" required>
          <el-input v-model="form.name" placeholder="请输入姓名" />
        </el-form-item>
        <el-form-item label="密码" :required="!editingUser">
          <el-input v-model="form.password" type="password" :placeholder="editingUser ? '留空则不修改' : '请输入密码'" show-password />
        </el-form-item>
        <el-form-item label="角色" required>
          <el-select v-model="form.role" placeholder="请选择角色" style="width: 100%">
            <el-option label="申请者" value="applicant" />
            <el-option label="批复者" value="approver" />
            <el-option label="联络员" value="liaison" />
            <el-option label="管理员" value="admin" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showDialog = false">取消</el-button>
        <el-button type="primary" @click="saveUser" :loading="loading">保存</el-button>
      </template>
    </el-dialog>

    <!-- Auth dialog -->
    <el-dialog v-model="showAuthDialog" title="组织授权" width="600px">
      <el-transfer v-model="selectedOrgs" :data="allOrgs" :titles="['可选组织', '已授权组织']" />
      <template #footer>
        <el-button @click="showAuthDialog = false">取消</el-button>
        <el-button type="primary" @click="saveAuth" :loading="loading">保存</el-button>
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
const users = ref([])
const searchText = ref('')
const roleFilter = ref('')
const showDialog = ref(false)
const showAuthDialog = ref(false)
const editingUser = ref<any>(null)
const editingUserId = ref<number | null>(null)
const selectedOrgs = ref<number[]>([])
const allOrgs = ref<any[]>([])
const pagination = ref({
  page: Number(route.query.page) || 1,
  pageSize: Number(route.query.pageSize) || 20,
  total: 0,
  totalPages: 0
})

let searchTimeout: ReturnType<typeof setTimeout> | null = null

const form = ref({
  username: '',
  name: '',
  password: '',
  role: ''
})

function roleType(role: string) {
  const types: Record<string, string> = {
    applicant: '',
    approver: 'success',
    liaison: 'warning',
    admin: 'danger'
  }
  return types[role] || 'info'
}

function roleLabel(role: string) {
  const labels: Record<string, string> = {
    applicant: '申请者',
    approver: '批复者',
    liaison: '联络员',
    admin: '管理员'
  }
  return labels[role] || role
}

function editUser(user: any) {
  editingUser.value = user
  form.value = {
    username: user.username,
    name: user.name,
    password: '',
    role: user.role
  }
  showDialog.value = true
}

async function editAuth(user: any) {
  editingUserId.value = user.id
  try {
    const [orgsRes, userOrgsRes] = await Promise.all([
      api.get('/organizations'),
      api.get(`/users/${user.id}/organizations`)
    ])
    allOrgs.value = orgsRes.data.map((o: any) => ({
      key: o.id,
      label: o.name
    }))
    selectedOrgs.value = userOrgsRes.data.map((o: any) => o.id)
    showAuthDialog.value = true
  } catch (error) {
    console.error('获取组织数据失败:', error)
  }
}

function handleSearch() {
  if (searchTimeout) {
    clearTimeout(searchTimeout)
  }
  searchTimeout = setTimeout(() => {
    pagination.value.page = 1
    loadUsers()
  }, 300)
}

function handleFilterChange() {
  pagination.value.page = 1
  loadUsers()
}

function handlePageChange(page: number) {
  pagination.value.page = page
  loadUsers()
}

function handlePageSizeChange(pageSize: number) {
  pagination.value.pageSize = pageSize
  pagination.value.page = 1
  loadUsers()
}

async function saveUser() {
  if (!form.value.username || !form.value.name || !form.value.role) {
    ElMessage.warning('请填写所有必填字段')
    return
  }

  loading.value = true
  try {
    if (editingUser.value) {
      await api.put(`/users/${editingUser.value.id}`, form.value)
    } else {
      if (!form.value.password) {
        ElMessage.warning('请输入密码')
        return
      }
      await api.post('/users', form.value)
    }
    ElMessage.success('保存成功')
    showDialog.value = false
    editingUser.value = null
    form.value = { username: '', name: '', password: '', role: '' }
    loadUsers()
  } catch (error: any) {
    ElMessage.error(error.response?.data?.error || '保存失败')
  } finally {
    loading.value = false
  }
}

async function saveAuth() {
  loading.value = true
  try {
    await api.post(`/users/${editingUserId.value}/organizations`, { orgIds: selectedOrgs.value })
    ElMessage.success('授权更新成功')
    showAuthDialog.value = false
  } catch (error: any) {
    ElMessage.error(error.response?.data?.error || '更新失败')
  } finally {
    loading.value = false
  }
}

async function deleteUser(id: number) {
  try {
    await api.delete(`/users/${id}`)
    ElMessage.success('删除成功')
    loadUsers()
  } catch (error: any) {
    ElMessage.error(error.response?.data?.error || '删除失败')
  }
}

async function loadUsers() {
  try {
    const params: any = {
      page: pagination.value.page,
      pageSize: pagination.value.pageSize
    }
    if (searchText.value) {
      params.keyword = searchText.value
    }
    if (roleFilter.value) {
      params.role = roleFilter.value
    }
    const response = await api.get('/users', { params })
    users.value = response.data.data
    pagination.value.total = response.data.pagination.total
    pagination.value.totalPages = response.data.pagination.totalPages
  } catch (error) {
    console.error('获取用户列表失败:', error)
  }
}

onMounted(() => {
  loadUsers()
})
</script>

<style scoped>
.admin-page {
  padding: 28px 32px;
  max-width: 1200px;
}

/* Page header */
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

/* Table */
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
