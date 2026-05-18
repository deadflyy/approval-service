<template>
  <div class="new-request-page">
    <!-- Page header -->
    <div class="page-header">
      <div class="header-left">
        <el-button text @click="router.back()" class="back-btn">
          <el-icon><ArrowLeft /></el-icon>
          返回
        </el-button>
        <h1 class="page-title">提交请示</h1>
      </div>
    </div>

    <div class="form-container">
      <el-form :model="form" label-width="120px" label-position="top">
        <!-- Basic info section -->
        <div class="form-section">
          <h3 class="section-title">基本信息</h3>
          <div class="form-grid">
            <el-form-item label="所属组织" required>
              <el-select v-model="form.org_id" placeholder="请选择组织" style="width: 100%">
                <el-option v-for="org in organizations" :key="org.id" :label="org.name" :value="org.id" />
              </el-select>
            </el-form-item>

            <el-form-item label="请示类别" required>
              <el-select v-model="form.category" placeholder="请选择类别" @change="onCategoryChange" style="width: 100%">
                <el-option v-for="cat in categories" :key="cat" :label="cat" :value="cat" />
              </el-select>
            </el-form-item>

            <el-form-item label="进度" required>
              <el-select v-model="form.step" placeholder="请选择进度" style="width: 100%">
                <el-option v-for="step in steps" :key="step" :label="step" :value="step" />
              </el-select>
            </el-form-item>

            <el-form-item label="请示标题" required class="full-width">
              <el-input v-model="form.title" placeholder="请输入请示标题" />
            </el-form-item>

            <el-form-item label="请示页数">
              <el-input-number v-model="form.page_count" :min="1" style="width: 100%" />
            </el-form-item>

            <el-form-item label="附件份数">
              <el-input-number v-model="form.attachment_count" :min="0" style="width: 100%" />
            </el-form-item>
          </div>
        </div>

        <!-- Organization info section -->
        <div class="form-section">
          <h3 class="section-title">组织信息</h3>
          <div class="form-grid">
            <el-form-item label="涉及党组织名称" class="full-width">
              <el-input v-model="form.involved_orgs" type="textarea" :rows="3" placeholder="多个组织请换行输入" />
            </el-form-item>

            <el-form-item label="涉及党组织数">
              <el-input-number v-model="form.involved_org_count" :min="0" style="width: 100%" />
            </el-form-item>

            <el-form-item label="新成立党组织信息" v-if="form.category === '成立'">
              <el-input v-model="form.new_org_info" type="textarea" />
            </el-form-item>

            <el-form-item label="党员大会时间" v-if="form.category === '换届'">
              <el-date-picker v-model="form.meeting_time" type="date" placeholder="选择日期" value-format="YYYY-MM-DD" style="width: 100%" />
            </el-form-item>
          </div>
        </div>

        <!-- Personnel section -->
        <div class="form-section">
          <h3 class="section-title">人员信息</h3>
          <div class="form-grid">
            <el-form-item label="书记候选人">
              <el-input v-model="form.secretary_candidate" />
            </el-form-item>

            <el-form-item label="副书记候选人">
              <el-input v-model="form.deputy_secretary_candidate" />
            </el-form-item>

            <el-form-item label="委员候选人" class="full-width">
              <el-input v-model="form.committee_members" type="textarea" />
            </el-form-item>
          </div>
        </div>

        <!-- Statistics section -->
        <div class="form-section">
          <h3 class="section-title">组织统计</h3>
          <div class="form-grid">
            <el-form-item label="是否有高层担任班子">
              <el-select v-model="form.has_senior_leader" style="width: 100%">
                <el-option label="否" :value="0" />
                <el-option label="是" :value="1" />
              </el-select>
            </el-form-item>
          </div>

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
        </div>

        <!-- Submit -->
        <div class="form-actions">
          <el-button @click="router.back()">取消</el-button>
          <el-button type="primary" @click="submitRequest" :loading="loading" size="large">
            <el-icon><Check /></el-icon>
            提交请示
          </el-button>
        </div>
      </el-form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { ElMessage } from 'element-plus'
import api from '../api'

const router = useRouter()
const authStore = useAuthStore()
const loading = ref(false)
const organizations = ref([])
const categories = ['成立', '换届', '增补', '调整', '更名', '撤销', '延期', '架构调整']

const stepsByCategory: Record<string, string[]> = {
  '成立': ['成立', '成立-1', '成立-2', '成立-3'],
  '换届': ['换届-1', '换届-2', '换届-3'],
  '增补': ['增补-1', '增补-2'],
  '调整': ['调整'],
  '更名': ['更名'],
  '撤销': ['撤销'],
  '延期': ['延期'],
  '架构调整': ['架构调整']
}

const steps = ref<string[]>([])

const form = ref({
  org_id: null as number | null,
  category: '',
  step: '',
  title: '',
  page_count: 1,
  attachment_count: 0,
  involved_orgs: '',
  involved_org_count: 0,
  new_org_info: '',
  meeting_time: '',
  secretary_candidate: '',
  deputy_secretary_candidate: '',
  committee_members: '',
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

function onCategoryChange() {
  steps.value = stepsByCategory[form.value.category] || []
  form.value.step = ''
}

async function submitRequest() {
  if (!form.value.org_id || !form.value.category || !form.value.step || !form.value.title) {
    ElMessage.warning('请填写所有必填字段')
    return
  }

  loading.value = true
  try {
    await api.post('/requests', form.value)
    ElMessage.success('请示提交成功')
    router.push('/requests')
  } catch (error: any) {
    ElMessage.error(error.response?.data?.error || '提交失败')
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  try {
    const response = await api.get('/users/' + authStore.user?.id + '/organizations')
    organizations.value = response.data
  } catch (error) {
    console.error('获取组织列表失败:', error)
  }
})
</script>

<style scoped>
.new-request-page {
  padding: 28px 32px;
  max-width: 900px;
}

/* Page header */
.page-header {
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

/* Form container */
.form-container {
  background: var(--bg-card);
  border: 1px solid var(--border-light);
  border-radius: var(--radius-lg);
  padding: 32px;
}

/* Form sections */
.form-section {
  margin-bottom: 32px;
  padding-bottom: 24px;
  border-bottom: 1px solid var(--border-light);
}

.form-section:last-of-type {
  border-bottom: none;
  margin-bottom: 16px;
}

.section-title {
  font-size: 16px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 20px;
}

/* Form grid */
.form-grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);
  gap: 16px 20px;
}

.full-width {
  grid-column: 1 / -1;
}

/* Stats groups */
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

/* Form actions */
.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  padding-top: 24px;
  border-top: 1px solid var(--border-light);
  margin-top: 24px;
}

@media (max-width: 768px) {
  .new-request-page {
    padding: 20px 16px;
  }

  .form-container {
    padding: 20px;
  }

  .form-grid {
    grid-template-columns: 1fr;
  }

  .stats-grid {
    grid-template-columns: 1fr;
  }
}
</style>
