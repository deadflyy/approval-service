<template>
  <div class="request-detail">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>请示详情</span>
          <el-button @click="router.back()">返回</el-button>
        </div>
      </template>

      <el-descriptions :column="2" border>
        <el-descriptions-item label="ID">{{ request.id }}</el-descriptions-item>
        <el-descriptions-item label="状态">
          <el-tag :type="statusType(request.status)">{{ statusLabel(request.status) }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="组织">{{ request.org_name }}</el-descriptions-item>
        <el-descriptions-item label="提交人">{{ request.user_name }}</el-descriptions-item>
        <el-descriptions-item label="类别">{{ request.category }}</el-descriptions-item>
        <el-descriptions-item label="进度">{{ request.step }}</el-descriptions-item>
        <el-descriptions-item label="标题" :span="2">{{ request.title }}</el-descriptions-item>
        <el-descriptions-item label="请示页数">{{ request.page_count }}</el-descriptions-item>
        <el-descriptions-item label="附件份数">{{ request.attachment_count }}</el-descriptions-item>
        <el-descriptions-item label="涉及党组织" :span="2">{{ request.involved_orgs }}</el-descriptions-item>
        <el-descriptions-item label="涉及党组织数">{{ request.involved_org_count }}</el-descriptions-item>
        <el-descriptions-item label="党员大会时间">{{ request.meeting_time }}</el-descriptions-item>
        <el-descriptions-item label="书记候选人">{{ request.secretary_candidate }}</el-descriptions-item>
        <el-descriptions-item label="副书记候选人">{{ request.deputy_secretary_candidate }}</el-descriptions-item>
        <el-descriptions-item label="委员候选人" :span="2">{{ request.committee_members }}</el-descriptions-item>
        <el-descriptions-item label="批复号">{{ request.batch_number }}</el-descriptions-item>
        <el-descriptions-item label="联络员">{{ request.liaison_name }}</el-descriptions-item>
        <el-descriptions-item label="退回原因" :span="2" v-if="request.reject_reason">{{ request.reject_reason }}</el-descriptions-item>
        <el-descriptions-item label="提交时间">{{ request.created_at }}</el-descriptions-item>
        <el-descriptions-item label="更新时间">{{ request.updated_at }}</el-descriptions-item>
      </el-descriptions>

      <el-divider>组织统计</el-divider>

      <el-descriptions :column="3" border>
        <el-descriptions-item label="是否有高层担任班子">{{ request.has_senior_leader ? '是' : '否' }}</el-descriptions-item>
        <el-descriptions-item label="涉及支部数">{{ request.branch_count }}</el-descriptions-item>
        <el-descriptions-item label="涉及总支数">{{ request.general_branch_count }}</el-descriptions-item>
        <el-descriptions-item label="涉及党委">{{ request.committee_count }}</el-descriptions-item>
        <el-descriptions-item label="党委书记数">{{ request.party_committee_secretary_count }}</el-descriptions-item>
        <el-descriptions-item label="党委副书记数">{{ request.party_committee_deputy_count }}</el-descriptions-item>
        <el-descriptions-item label="党委委员数">{{ request.party_committee_member_count }}</el-descriptions-item>
        <el-descriptions-item label="总支书记数">{{ request.general_branch_secretary_count }}</el-descriptions-item>
        <el-descriptions-item label="总支副书记数">{{ request.general_branch_deputy_count }}</el-descriptions-item>
        <el-descriptions-item label="总支委员数">{{ request.general_branch_member_count }}</el-descriptions-item>
        <el-descriptions-item label="支部书记数">{{ request.branch_secretary_count }}</el-descriptions-item>
        <el-descriptions-item label="支部副书记数">{{ request.branch_deputy_count }}</el-descriptions-item>
        <el-descriptions-item label="支部委员数">{{ request.branch_member_count }}</el-descriptions-item>
      </el-descriptions>

      <div class="actions" style="margin-top: 20px;">
        <!-- 批复者操作 -->
        <template v-if="authStore.user?.role === 'approver' && (request.status === 'pending' || request.status === 'rejected')">
          <el-button type="success" @click="approve" :loading="loading">审批通过</el-button>
          <el-button type="danger" @click="showRejectDialog = true">退回修改</el-button>
        </template>

        <!-- 联络员操作 -->
        <template v-if="authStore.user?.role === 'liaison' && request.liaison_id === authStore.user?.id">
          <el-button v-if="request.status === 'approved'" type="primary" @click="updateStatus('signed')">标记已签批</el-button>
          <el-button v-if="request.status === 'signed'" type="primary" @click="updateStatus('printed')">标记已打印</el-button>
          <el-button v-if="request.status === 'printed'" type="primary" @click="updateStatus('collected')">标记已领取</el-button>
        </template>

        <!-- 管理员分配联络员 -->
        <template v-if="authStore.user?.role === 'admin'">
          <el-button type="warning" @click="showLiaisonDialog = true">分配联络员</el-button>
        </template>
      </div>
    </el-card>

    <!-- 退回修改对话框 -->
    <el-dialog v-model="showRejectDialog" title="退回修改">
      <el-form>
        <el-form-item label="退回原因">
          <el-input v-model="rejectReason" type="textarea" :rows="3" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showRejectDialog = false">取消</el-button>
        <el-button type="danger" @click="reject" :loading="loading">确认退回</el-button>
      </template>
    </el-dialog>

    <!-- 分配联络员对话框 -->
    <el-dialog v-model="showLiaisonDialog" title="分配联络员">
      <el-form>
        <el-form-item label="选择联络员">
          <el-select v-model="selectedLiaison" placeholder="请选择联络员">
            <el-option v-for="user in liaisonUsers" :key="user.id" :label="user.name" :value="user.id" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showLiaisonDialog = false">取消</el-button>
        <el-button type="primary" @click="assignLiaison" :loading="loading">确认分配</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { ElMessage } from 'element-plus'
import api from '../api'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()
const loading = ref(false)
const request = ref<any>({})
const showRejectDialog = ref(false)
const showLiaisonDialog = ref(false)
const rejectReason = ref('')
const selectedLiaison = ref(null)
const liaisonUsers = ref([])

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

async function loadRequest() {
  try {
    const response = await api.get(`/requests/${route.params.id}`)
    request.value = response.data
  } catch (error) {
    console.error('获取请示详情失败:', error)
  }
}

async function approve() {
  loading.value = true
  try {
    await api.post(`/requests/${route.params.id}/approve`)
    ElMessage.success('审批通过')
    loadRequest()
  } catch (error: any) {
    ElMessage.error(error.response?.data?.error || '审批失败')
  } finally {
    loading.value = false
  }
}

async function reject() {
  loading.value = true
  try {
    await api.post(`/requests/${route.params.id}/reject`, { reason: rejectReason.value })
    ElMessage.success('已退回修改')
    showRejectDialog.value = false
    loadRequest()
  } catch (error: any) {
    ElMessage.error(error.response?.data?.error || '退回失败')
  } finally {
    loading.value = false
  }
}

async function updateStatus(status: string) {
  loading.value = true
  try {
    await api.put(`/requests/${route.params.id}/status`, { status })
    ElMessage.success('状态更新成功')
    loadRequest()
  } catch (error: any) {
    ElMessage.error(error.response?.data?.error || '更新失败')
  } finally {
    loading.value = false
  }
}

async function assignLiaison() {
  loading.value = true
  try {
    await api.put(`/requests/${route.params.id}/liaison`, { liaison_id: selectedLiaison.value })
    ElMessage.success('联络员分配成功')
    showLiaisonDialog.value = false
    loadRequest()
  } catch (error: any) {
    ElMessage.error(error.response?.data?.error || '分配失败')
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  loadRequest()

  if (authStore.user?.role === 'admin') {
    try {
      const response = await api.get('/users')
      liaisonUsers.value = response.data.filter((u: any) => u.role === 'liaison')
    } catch (error) {
      console.error('获取联络员列表失败:', error)
    }
  }
})
</script>

<style scoped>
.request-detail {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.actions {
  display: flex;
  gap: 10px;
}
</style>
