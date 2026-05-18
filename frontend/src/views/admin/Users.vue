<template>
  <div class="users">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>用户管理</span>
          <el-button type="primary" @click="showDialog = true">新增用户</el-button>
        </div>
      </template>

      <el-table :data="users" style="width: 100%">
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column prop="username" label="用户名" />
        <el-table-column prop="name" label="姓名" />
        <el-table-column prop="role" label="角色">
          <template #default="{ row }">
            <el-tag>{{ roleLabel(row.role) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" />
        <el-table-column label="操作" width="200">
          <template #default="{ row }">
            <el-button link type="primary" @click="editUser(row)">编辑</el-button>
            <el-button link type="primary" @click="editAuth(row)">授权</el-button>
            <el-popconfirm title="确定删除吗？" @confirm="deleteUser(row.id)">
              <template #reference>
                <el-button link type="danger">删除</el-button>
              </template>
            </el-popconfirm>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 新增/编辑用户对话框 -->
    <el-dialog v-model="showDialog" :title="editingUser ? '编辑用户' : '新增用户'">
      <el-form :model="form" label-width="80px">
        <el-form-item label="用户名" required>
          <el-input v-model="form.username" :disabled="!!editingUser" />
        </el-form-item>
        <el-form-item label="姓名" required>
          <el-input v-model="form.name" />
        </el-form-item>
        <el-form-item label="密码" :required="!editingUser">
          <el-input v-model="form.password" type="password" :placeholder="editingUser ? '留空则不修改' : '请输入密码'" />
        </el-form-item>
        <el-form-item label="角色" required>
          <el-select v-model="form.role">
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

    <!-- 组织授权对话框 -->
    <el-dialog v-model="showAuthDialog" title="组织授权">
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
import { ElMessage } from 'element-plus'
import api from '../../api'

const loading = ref(false)
const users = ref([])
const showDialog = ref(false)
const showAuthDialog = ref(false)
const editingUser = ref<any>(null)
const editingUserId = ref<number | null>(null)
const selectedOrgs = ref<number[]>([])
const allOrgs = ref<any[]>([])

const form = ref({
  username: '',
  name: '',
  password: '',
  role: ''
})

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
    const response = await api.get('/users')
    users.value = response.data
  } catch (error) {
    console.error('获取用户列表失败:', error)
  }
}

onMounted(() => {
  loadUsers()
})
</script>

<style scoped>
.users {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
