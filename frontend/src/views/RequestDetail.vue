<template>
  <div class="detail-page">
    <!-- Page header -->
    <div class="page-header">
      <div class="header-left">
        <el-button text @click="router.back()" class="back-btn">
          <el-icon><ArrowLeft /></el-icon>
          返回
        </el-button>
        <h1 class="page-title">请示详情</h1>
      </div>
      <div class="header-right">
        <el-tag :type="statusType(request.status)" size="large" effect="light">
          {{ statusLabel(request.status) }}
        </el-tag>
      </div>
    </div>

    <!-- Main content -->
    <div class="detail-grid">
      <!-- Left: Main info -->
      <div class="detail-main">
        <div class="info-card">
          <div class="card-header">
            <h3>基本信息</h3>
            <span class="request-id">#{{ request.id }}</span>
          </div>
          <div class="card-body">
            <div class="info-row">
              <span class="info-label">请示标题</span>
              <span class="info-value title-value">{{ request.title }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">所属组织</span>
              <span class="info-value">{{ request.org_name }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">提交人</span>
              <span class="info-value">{{ request.user_name }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">请示类别</span>
              <span class="info-value">
                <span class="category-tag">{{ request.category }}</span>
              </span>
            </div>
            <div class="info-row">
              <span class="info-label">流程进度</span>
              <span class="info-value">{{ request.step }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">批复号</span>
              <span class="info-value batch-number">{{ request.batch_number || '待分配' }}</span>
            </div>
          </div>
        </div>

        <div class="info-card">
          <div class="card-header">
            <h3>组织信息</h3>
          </div>
          <div class="card-body">
            <div class="info-row">
              <span class="info-label">涉及党组织</span>
              <span class="info-value">{{ request.involved_orgs || '-' }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">涉及党组织数</span>
              <span class="info-value">{{ request.involved_org_count || 0 }}</span>
            </div>
            <div class="info-row" v-if="request.meeting_time">
              <span class="info-label">党员大会时间</span>
              <span class="info-value">{{ request.meeting_time }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">书记候选人</span>
              <span class="info-value">{{ request.secretary_candidate || '-' }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">副书记候选人</span>
              <span class="info-value">{{ request.deputy_secretary_candidate || '-' }}</span>
            </div>
            <div class="info-row">
              <span class="info-label">委员候选人</span>
              <span class="info-value">{{ request.committee_members || '-' }}</span>
            </div>
          </div>
        </div>

        <div class="info-card" v-if="request.reject_reason">
          <div class="card-header">
            <h3>退回原因</h3>
          </div>
          <div class="card-body">
            <div class="reject-reason">{{ request.reject_reason }}</div>
          </div>
        </div>
      </div>

      <!-- Right: Stats and actions -->
      <div class="detail-side">
        <div class="info-card">
          <div class="card-header">
            <h3>组织统计</h3>
          </div>
          <div class="card-body stats-body">
            <div class="stat-item">
              <span class="stat-label">高层担任班子</span>
              <span class="stat-value" :class="{ 'stat-yes': request.has_senior_leader }">
                {{ request.has_senior_leader ? '是' : '否' }}
              </span>
            </div>
            <div class="stat-divider"></div>
            <div class="stat-group-title">涉及组织</div>
            <div class="stat-row">
              <div class="stat-item">
                <span class="stat-label">支部</span>
                <span class="stat-value">{{ request.branch_count || 0 }}</span>
              </div>
              <div class="stat-item">
                <span class="stat-label">总支</span>
                <span class="stat-value">{{ request.general_branch_count || 0 }}</span>
              </div>
              <div class="stat-item">
                <span class="stat-label">党委</span>
                <span class="stat-value">{{ request.committee_count || 0 }}</span>
              </div>
            </div>
            <div class="stat-divider"></div>
            <div class="stat-group-title">党委</div>
            <div class="stat-row">
              <div class="stat-item">
                <span class="stat-label">书记</span>
                <span class="stat-value">{{ request.party_committee_secretary_count || 0 }}</span>
              </div>
              <div class="stat-item">
                <span class="stat-label">副书记</span>
                <span class="stat-value">{{ request.party_committee_deputy_count || 0 }}</span>
              </div>
              <div class="stat-item">
                <span class="stat-label">委员</span>
                <span class="stat-value">{{ request.party_committee_member_count || 0 }}</span>
              </div>
            </div>
            <div class="stat-divider"></div>
            <div class="stat-group-title">总支</div>
            <div class="stat-row">
              <div class="stat-item">
                <span class="stat-label">书记</span>
                <span class="stat-value">{{ request.general_branch_secretary_count || 0 }}</span>
              </div>
              <div class="stat-item">
                <span class="stat-label">副书记</span>
                <span class="stat-value">{{ request.general_branch_deputy_count || 0 }}</span>
              </div>
              <div class="stat-item">
                <span class="stat-label">委员</span>
                <span class="stat-value">{{ request.general_branch_member_count || 0 }}</span>
              </div>
            </div>
            <div class="stat-divider"></div>
            <div class="stat-group-title">支部</div>
            <div class="stat-row">
              <div class="stat-item">
                <span class="stat-label">书记</span>
                <span class="stat-value">{{ request.branch_secretary_count || 0 }}</span>
              </div>
              <div class="stat-item">
                <span class="stat-label">副书记</span>
                <span class="stat-value">{{ request.branch_deputy_count || 0 }}</span>
              </div>
              <div class="stat-item">
                <span class="stat-label">委员</span>
                <span class="stat-value">{{ request.branch_member_count || 0 }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Actions -->
        <div class="info-card actions-card">
          <div class="card-header">
            <h3>操作</h3>
          </div>
          <div class="card-body">
            <template v-if="authStore.user?.role === 'approver' && (request.status === 'pending' || request.status === 'rejected')">
              <el-button type="primary" @click="approve" :loading="loading" class="action-btn">
                <el-icon><Check /></el-icon>
                审批通过
              </el-button>
              <el-button type="danger" @click="showRejectDialog = true" class="action-btn" plain>
                <el-icon><Close /></el-icon>
                退回修改
              </el-button>
            </template>

            <template v-if="authStore.user?.role === 'liaison' && request.liaison_id === authStore.user?.id">
              <el-button v-if="request.status === 'approved'" type="primary" @click="updateStatus('signed')" :loading="loading" class="action-btn">
                <el-icon><Edit /></el-icon>
                标记已签批
              </el-button>
              <el-button v-if="request.status === 'signed'" type="primary" @click="updateStatus('printed')" :loading="loading" class="action-btn">
                <el-icon><Printer /></el-icon>
                标记已打印
              </el-button>
              <el-button v-if="request.status === 'printed'" type="success" @click="updateStatus('collected')" :loading="loading" class="action-btn">
                <el-icon><Finished /></el-icon>
                标记已领取
              </el-button>
            </template>

            <template v-if="authStore.user?.role === 'admin'">
              <el-button type="warning" @click="showLiaisonDialog = true" class="action-btn" plain>
                <el-icon><Connection /></el-icon>
                分配联络员
              </el-button>
            </template>

            <div class="action-info">
              <div class="info-row">
                <span class="info-label">联络员</span>
                <span class="info-value">{{ request.liaison_name || '未分配' }}</span>
              </div>
              <div class="info-row">
                <span class="info-label">提交时间</span>
                <span class="info-value">{{ request.created_at }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Dialogs -->
    <el-dialog v-model="showRejectDialog" title="退回修改" width="420px">
      <el-form>
        <el-form-item label="退回原因">
          <el-input v-model="rejectReason" type="textarea" :rows="4" placeholder="请输入退回原因" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showRejectDialog = false">取消</el-button>
        <el-button type="danger" @click="reject" :loading="loading">确认退回</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="showLiaisonDialog" title="分配联络员" width="420px">
      <el-form>
        <el-form-item label="选择联络员">
          <el-select v-model="selectedLiaison" placeholder="请选择联络员" style="width: 100%">
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
.detail-page {
  padding: 28px 32px;
  max-width: 1200px;
}

/* Page header */
.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 12px;
}

.back-btn {
  font-size: 14px;
  color: var(--text-secondary);
}

.page-title {
  font-size: 22px;
  font-weight: 700;
  color: var(--text-primary);
  letter-spacing: -0.02em;
}

/* Grid layout */
.detail-grid {
  display: grid;
  grid-template-columns: 1fr 340px;
  gap: 20px;
  align-items: start;
}

/* Cards */
.info-card {
  background: var(--bg-card);
  border: 1px solid var(--border-light);
  border-radius: var(--radius-lg);
  margin-bottom: 16px;
  overflow: hidden;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  border-bottom: 1px solid var(--border-light);
}

.card-header h3 {
  font-size: 15px;
  font-weight: 600;
  color: var(--text-primary);
}

.request-id {
  font-size: 13px;
  color: var(--text-muted);
  font-family: var(--font-mono);
}

.card-body {
  padding: 16px 20px;
}

/* Info rows */
.info-row {
  display: flex;
  align-items: flex-start;
  padding: 8px 0;
  border-bottom: 1px solid var(--gray-50);
}

.info-row:last-child {
  border-bottom: none;
}

.info-label {
  width: 100px;
  flex-shrink: 0;
  font-size: 13px;
  color: var(--text-muted);
  font-weight: 450;
}

.info-value {
  flex: 1;
  font-size: 13px;
  color: var(--text-primary);
}

.title-value {
  font-weight: 600;
  font-size: 14px;
}

.batch-number {
  font-family: var(--font-mono);
  color: var(--primary-600);
  font-weight: 500;
}

.category-tag {
  font-size: 12px;
  font-weight: 500;
  color: var(--primary-600);
  background: var(--primary-50);
  padding: 2px 8px;
  border-radius: 4px;
}

/* Reject reason */
.reject-reason {
  font-size: 14px;
  color: var(--danger);
  line-height: 1.6;
  padding: 12px;
  background: var(--danger-light);
  border-radius: var(--radius-md);
}

/* Stats */
.stats-body {
  padding: 12px 16px;
}

.stat-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 6px 0;
}

.stat-label {
  font-size: 12px;
  color: var(--text-muted);
}

.stat-value {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
}

.stat-yes {
  color: var(--primary-600);
}

.stat-divider {
  height: 1px;
  background: var(--border-light);
  margin: 8px 0;
}

.stat-group-title {
  font-size: 11px;
  font-weight: 600;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 4px;
}

.stat-row {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 4px;
}

.stat-row .stat-item {
  flex-direction: column;
  align-items: center;
  padding: 8px;
  background: var(--gray-50);
  border-radius: var(--radius-sm);
}

/* Actions card */
.actions-card .card-body {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.action-btn {
  width: 100%;
}

.action-info {
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px solid var(--border-light);
}

.action-info .info-row {
  padding: 4px 0;
}

@media (max-width: 1024px) {
  .detail-page {
    padding: 20px 16px;
  }

  .detail-grid {
    grid-template-columns: 1fr;
  }
}
</style>
