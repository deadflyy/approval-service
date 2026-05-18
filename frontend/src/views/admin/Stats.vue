<template>
  <div class="stats">
    <el-card>
      <template #header>
        <span>统计汇总</span>
      </template>

      <el-table :data="requests" style="width: 100%">
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column prop="org_name" label="组织" width="200" show-overflow-tooltip />
        <el-table-column prop="title" label="标题" show-overflow-tooltip />
        <el-table-column prop="category" label="类别" width="80" />
        <el-table-column prop="has_senior_leader" label="高层担任" width="80">
          <template #default="{ row }">{{ row.has_senior_leader ? '是' : '否' }}</template>
        </el-table-column>
        <el-table-column prop="branch_count" label="支部数" width="80" />
        <el-table-column prop="general_branch_count" label="总支数" width="80" />
        <el-table-column prop="committee_count" label="党委数" width="80" />
        <el-table-column prop="party_committee_secretary_count" label="党委书记" width="80" />
        <el-table-column prop="party_committee_deputy_count" label="党委副书" width="80" />
        <el-table-column prop="party_committee_member_count" label="党委委员" width="80" />
        <el-table-column prop="general_branch_secretary_count" label="总支书记" width="80" />
        <el-table-column prop="general_branch_deputy_count" label="总支副书" width="80" />
        <el-table-column prop="general_branch_member_count" label="总支委员" width="80" />
        <el-table-column prop="branch_secretary_count" label="支部书记" width="80" />
        <el-table-column prop="branch_deputy_count" label="支部副书" width="80" />
        <el-table-column prop="branch_member_count" label="支部委员" width="80" />
        <el-table-column label="操作" width="80" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" @click="editStats(row)">编辑</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog v-model="showDialog" title="编辑统计数据">
      <el-form :model="form" label-width="120px">
        <el-form-item label="是否有高层担任班子">
          <el-select v-model="form.has_senior_leader">
            <el-option label="否" :value="0" />
            <el-option label="是" :value="1" />
          </el-select>
        </el-form-item>
        <el-row :gutter="20">
          <el-col :span="8">
            <el-form-item label="涉及支部数">
              <el-input-number v-model="form.branch_count" :min="0" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="涉及总支数">
              <el-input-number v-model="form.general_branch_count" :min="0" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="涉及党委">
              <el-input-number v-model="form.committee_count" :min="0" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="8">
            <el-form-item label="党委书记数">
              <el-input-number v-model="form.party_committee_secretary_count" :min="0" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="党委副书记数">
              <el-input-number v-model="form.party_committee_deputy_count" :min="0" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="党委委员数">
              <el-input-number v-model="form.party_committee_member_count" :min="0" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="8">
            <el-form-item label="总支书记数">
              <el-input-number v-model="form.general_branch_secretary_count" :min="0" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="总支副书记数">
              <el-input-number v-model="form.general_branch_deputy_count" :min="0" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="总支委员数">
              <el-input-number v-model="form.general_branch_member_count" :min="0" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="20">
          <el-col :span="8">
            <el-form-item label="支部书记数">
              <el-input-number v-model="form.branch_secretary_count" :min="0" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="支部副书记数">
              <el-input-number v-model="form.branch_deputy_count" :min="0" />
            </el-form-item>
          </el-col>
          <el-col :span="8">
            <el-form-item label="支部委员数">
              <el-input-number v-model="form.branch_member_count" :min="0" />
            </el-form-item>
          </el-col>
        </el-row>
      </el-form>
      <template #footer>
        <el-button @click="showDialog = false">取消</el-button>
        <el-button type="primary" @click="saveStats" :loading="loading">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import api from '../../api'

const loading = ref(false)
const requests = ref([])
const showDialog = ref(false)
const editingId = ref<number | null>(null)

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
    const response = await api.get('/requests')
    requests.value = response.data
  } catch (error) {
    console.error('获取请示列表失败:', error)
  }
}

onMounted(() => {
  loadRequests()
})
</script>

<style scoped>
.stats {
  padding: 20px;
}
</style>
