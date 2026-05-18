<template>
  <div class="new-request">
    <el-card>
      <template #header>
        <span>提交请示</span>
      </template>

      <el-form :model="form" label-width="120px">
        <el-form-item label="所属组织" required>
          <el-select v-model="form.org_id" placeholder="请选择组织">
            <el-option v-for="org in organizations" :key="org.id" :label="org.name" :value="org.id" />
          </el-select>
        </el-form-item>

        <el-form-item label="请示类别" required>
          <el-select v-model="form.category" placeholder="请选择类别" @change="onCategoryChange">
            <el-option v-for="cat in categories" :key="cat" :label="cat" :value="cat" />
          </el-select>
        </el-form-item>

        <el-form-item label="进度" required>
          <el-select v-model="form.step" placeholder="请选择进度">
            <el-option v-for="step in steps" :key="step" :label="step" :value="step" />
          </el-select>
        </el-form-item>

        <el-form-item label="请示标题" required>
          <el-input v-model="form.title" placeholder="请输入请示标题" />
        </el-form-item>

        <el-form-item label="请示页数">
          <el-input-number v-model="form.page_count" :min="1" />
        </el-form-item>

        <el-form-item label="附件份数">
          <el-input-number v-model="form.attachment_count" :min="0" />
        </el-form-item>

        <el-divider>组织信息</el-divider>

        <el-form-item label="涉及党组织名称">
          <el-input v-model="form.involved_orgs" type="textarea" :rows="3" placeholder="多个组织请换行输入" />
        </el-form-item>

        <el-form-item label="涉及党组织数">
          <el-input-number v-model="form.involved_org_count" :min="0" />
        </el-form-item>

        <el-form-item label="新成立党组织信息" v-if="form.category === '成立'">
          <el-input v-model="form.new_org_info" type="textarea" />
        </el-form-item>

        <el-form-item label="党员大会时间" v-if="form.category === '换届'">
          <el-date-picker v-model="form.meeting_time" type="date" placeholder="选择日期" value-format="YYYY-MM-DD" />
        </el-form-item>

        <el-divider>人员信息</el-divider>

        <el-form-item label="书记候选人">
          <el-input v-model="form.secretary_candidate" />
        </el-form-item>

        <el-form-item label="副书记候选人">
          <el-input v-model="form.deputy_secretary_candidate" />
        </el-form-item>

        <el-form-item label="委员候选人">
          <el-input v-model="form.committee_members" type="textarea" />
        </el-form-item>

        <el-divider>组织统计</el-divider>

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

        <el-form-item>
          <el-button type="primary" @click="submitRequest" :loading="loading">提交请示</el-button>
          <el-button @click="router.back()">取消</el-button>
        </el-form-item>
      </el-form>
    </el-card>
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
.new-request {
  padding: 20px;
}
</style>
