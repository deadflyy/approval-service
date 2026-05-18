<template>
  <div class="admin-page">
    <!-- Page header -->
    <div class="page-header">
      <div class="header-left">
        <h1 class="page-title">统计汇总</h1>
        <p class="page-subtitle">组织统计数据</p>
      </div>
      <div class="header-right">
        <el-input
          v-model="searchText"
          placeholder="搜索..."
          prefix-icon="Search"
          clearable
          class="search-input"
        />
      </div>
    </div>

    <!-- Table -->
    <div class="table-wrapper">
      <el-table :data="requests" style="width: 100%" max-height="calc(100vh - 280px)">
        <el-table-column prop="id" label="ID" width="50" fixed />
        <el-table-column prop="org_name" label="组织" width="180" fixed show-overflow-tooltip />
        <el-table-column prop="title" label="标题" width="200" show-overflow-tooltip />
        <el-table-column prop="category" label="类别" width="70">
          <template #default="{ row }">
            <span class="category-tag">{{ row.category }}</span>
          </template>
        </el-table-column>
        <el-table-column label="高层担任" width="70" align="center">
          <template #default="{ row }">
            <el-icon v-if="row.has_senior_leader" class="stat-check"><Check /></el-icon>
            <span v-else>-</span>
          </template>
        </el-table-column>
        <el-table-column label="涉及组织" align="center">
          <el-table-column prop="branch_count" label="支部" width="55" align="center" />
          <el-table-column prop="general_branch_count" label="总支" width="55" align="center" />
          <el-table-column prop="committee_count" label="党委" width="55" align="center" />
        </el-table-column>
        <el-table-column label="党委" align="center">
          <el-table-column prop="party_committee_secretary_count" label="书记" width="55" align="center" />
          <el-table-column prop="party_committee_deputy_count" label="副书" width="55" align="center" />
          <el-table-column prop="party_committee_member_count" label="委员" width="55" align="center" />
        </el-table-column>
        <el-table-column label="总支" align="center">
          <el-table-column prop="general_branch_secretary_count" label="书记" width="55" align="center" />
          <el-table-column prop="general_branch_deputy_count" label="副书" width="55" align="center" />
          <el-table-column prop="general_branch_member_count" label="委员" width="55" align="center" />
        </el-table-column>
        <el-table-column label="支部" align="center">
          <el-table-column prop="branch_secretary_count" label="书记" width="55" align="center" />
          <el-table-column prop="branch_deputy_count" label="副书" width="55" align="center" />
          <el-table-column prop="branch_member_count" label="委员" width="55" align="center" />
        </el-table-column>
        <el-table-column label="操作" width="70" fixed="right" align="center">
          <template #default="{ row }">
            <el-button link type="primary" @click="editStats(row)" size="small">编辑</el-button>
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

    <!-- Edit dialog -->
    <el-dialog v-model="showDialog" title="编辑统计数据" width="600px">
      <el-form :model="form" label-position="top">
        <el-form-item label="是否有高层担任班子">
          <el-select v-model="form.has_senior_leader" style="width: 100%">
            <el-option label="否" :value="0" />
            <el-option label="是" :value="1" />
          </el-select>
        </el-form-item>

        <div class="stats-group">
          <h4 class="group-title">涉及组织</h4>
          <div class="stats-grid">
            <el-form-item label="支部数">
              <el-input-number v-model="form.branch_count" :min="0" style="width: 100%" />
            </el-form-item>
            <el-form-item label="总支数">
              <el-input-number v-model="form.general_branch_count" :min="0" style="width: 100%" />
            </el-form-item>
            <el-form-item label="党委">
              <el-input-number v-model="form.committee_count" :min="0" style="width: 100%" />
            </el-form-item>
          </div>
        </div>

        <div class="stats-group">
          <h4 class="group-title">党委</h4>
          <div class="stats-grid">
            <el-form-item label="书记数">
              <el-input-number v-model="form.party_committee_secretary_count" :min="0" style="width: 100%" />
            </el-form-item>
            <el-form-item label="副书记数">
              <el-input-number v-model="form.party_committee_deputy_count" :min="0" style="width: 100%" />
            </el-form-item>
            <el-form-item label="委员数">
              <el-input-number v-model="form.party_committee_member_count" :min="0" style="width: 100%" />
            </el-form-item>
          </div>
        </div>

        <div class="stats-group">
          <h4 class="group-title">总支</h4>
          <div class="stats-grid">
            <el-form-item label="书记数">
              <el-input-number v-model="form.general_branch_secretary_count" :min="0" style="width: 100%" />
            </el-form-item>
            <el-form-item label="副书记数">
              <el-input-number v-model="form.general_branch_deputy_count" :min="0" style="width: 100%" />
            </el-form-item>
            <el-form-item label="委员数">
              <el-input-number v-model="form.general_branch_member_count" :min="0" style="width: 100%" />
            </el-form-item>
          </div>
        </div>

        <div class="stats-group">
          <h4 class="group-title">支部</h4>
          <div class="stats-grid">
            <el-form-item label="书记数">
              <el-input-number v-model="form.branch_secretary_count" :min="0" style="width: 100%" />
            </el-form-item>
            <el-form-item label="副书记数">
              <el-input-number v-model="form.branch_deputy_count" :min="0" style="width: 100%" />
            </el-form-item>
            <el-form-item label="委员数">
              <el-input-number v-model="form.branch_member_count" :min="0" style="width: 100%" />
            </el-form-item>
          </div>
        </div>
      </el-form>
      <template #footer>
        <el-button @click="showDialog = false">取消</el-button>
        <el-button type="primary" @click="saveStats" :loading="loading">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { ElMessage } from 'element-plus'
import api from '../../api'
import Pagination from '../../components/Pagination.vue'

const loading = ref(false)
const requests = ref([])
const showDialog = ref(false)
const editingId = ref<number | null>(null)
const searchText = ref('')
const pagination = ref({
  page: 1,
  pageSize: 20,
  total: 0,
  totalPages: 0
})

const form = ref({
  has_senior_leader: 0,
  branch_count: 0,
  general_branch_count: 0,
  committee_count: 0,
  party_committee_secretary_count: 0,
  party_committee_deputy_count: 0,
  party_committee_member_count: 0,
  general_branch_secretary_count: 0,
  general_branch_deputy_count: 0,
  general_branch_member_count: 0,
  branch_secretary_count: 0,
  branch_deputy_count: 0,
  branch_member_count: 0
})

function handlePageChange(page: number) {
  pagination.value.page = page
  loadRequests()
}

function handlePageSizeChange(pageSize: number) {
  pagination.value.pageSize = pageSize
  pagination.value.page = 1
  loadRequests()
}

function editStats(request: any) {
  editingId.value = request.id
  form.value = {
    has_senior_leader: request.has_senior_leader,
    branch_count: request.branch_count,
    general_branch_count: request.general_branch_count,
    committee_count: request.committee_count,
    party_committee_secretary_count: request.party_committee_secretary_count,
    party_committee_deputy_count: request.party_committee_deputy_count,
    party_committee_member_count: request.party_committee_member_count,
    general_branch_secretary_count: request.general_branch_secretary_count,
    general_branch_deputy_count: request.general_branch_deputy_count,
    general_branch_member_count: request.general_branch_member_count,
    branch_secretary_count: request.branch_secretary_count,
    branch_deputy_count: request.branch_deputy_count,
    branch_member_count: request.branch_member_count
  }
  showDialog.value = true
}

async function saveStats() {
  loading.value = true
  try {
    await api.put(`/requests/${editingId.value}`, form.value)
    ElMessage.success('更新成功')
    showDialog.value = false
    loadRequests()
  } catch (error: any) {
    ElMessage.error(error.response?.data?.error || '更新失败')
  } finally {
    loading.value = false
  }
}

async function loadRequests() {
  try {
    const params: any = {
      page: pagination.value.page,
      pageSize: pagination.value.pageSize
    }
    if (searchText.value) {
      params.keyword = searchText.value
    }
    const response = await api.get('/requests', { params })
    requests.value = response.data.data
    pagination.value.total = response.data.pagination.total
    pagination.value.totalPages = response.data.pagination.totalPages
  } catch (error) {
    console.error('获取请示列表失败:', error)
  }
}

watch(searchText, () => {
  pagination.value.page = 1
  loadRequests()
})

onMounted(() => {
  loadRequests()
})
</script>

<style scoped>
.admin-page {
  padding: 28px 32px;
  max-width: 1400px;
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

.search-input {
  width: 240px;
}

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

.stat-check {
  color: var(--success);
  font-size: 16px;
}

.stats-group {
  margin-bottom: 20px;
}

.group-title {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-secondary);
  margin-bottom: 12px;
  padding-left: 12px;
  border-left: 3px solid var(--primary-400);
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
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

  .search-input {
    width: 100%;
  }
}
</style>
