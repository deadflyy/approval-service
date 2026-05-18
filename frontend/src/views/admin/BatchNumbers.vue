<template>
  <div class="admin-page">
    <!-- Page header -->
    <div class="page-header">
      <div class="header-left">
        <h1 class="page-title">批复号管理</h1>
        <p class="page-subtitle">管理批复号序列</p>
      </div>
    </div>

    <!-- Content -->
    <div class="content-card">
      <div class="info-section">
        <h3 class="section-title">当前设置</h3>
        <p class="section-desc">批复号格式：前缀〔年份〕序号号</p>
      </div>

      <el-form :model="form" label-position="top" class="batch-form">
        <div class="form-grid">
          <el-form-item label="年份">
            <el-input :value="currentYear" disabled />
          </el-form-item>
          <el-form-item label="前缀">
            <el-input v-model="form.prefix" placeholder="如：沪张江科综委" />
          </el-form-item>
          <el-form-item label="当前序号">
            <el-input-number v-model="form.current_seq" :min="0" style="width: 100%" />
          </el-form-item>
        </div>

        <div class="preview-section">
          <h4 class="preview-title">预览</h4>
          <div class="preview-number">
            {{ form.prefix }}〔{{ currentYear }}〕{{ form.current_seq + 1 }}号
          </div>
        </div>

        <div class="form-actions">
          <el-button type="primary" @click="save" :loading="loading" size="large">
            <el-icon><Check /></el-icon>
            保存设置
          </el-button>
        </div>
      </el-form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import api from '../../api'

const loading = ref(false)
const currentYear = new Date().getFullYear()

const form = ref({
  prefix: '沪张江科综委',
  current_seq: 0
})

async function loadBatchNumber() {
  try {
    const response = await api.get('/batch-numbers')
    form.value = {
      prefix: response.data.prefix || '沪张江科综委',
      current_seq: response.data.current_seq || 0
    }
  } catch (error) {
    console.error('获取批复号失败:', error)
  }
}

async function save() {
  loading.value = true
  try {
    await api.put('/batch-numbers', form.value)
    ElMessage.success('保存成功')
  } catch (error: any) {
    ElMessage.error(error.response?.data?.error || '保存失败')
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadBatchNumber()
})
</script>

<style scoped>
.admin-page {
  padding: 28px 32px;
  max-width: 800px;
}

.page-header {
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

.content-card {
  background: var(--bg-card);
  border: 1px solid var(--border-light);
  border-radius: var(--radius-lg);
  padding: 32px;
}

.info-section {
  margin-bottom: 28px;
  padding-bottom: 20px;
  border-bottom: 1px solid var(--border-light);
}

.section-title {
  font-size: 16px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 6px;
}

.section-desc {
  font-size: 13px;
  color: var(--text-muted);
}

.batch-form {
  margin-bottom: 0;
}

.form-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
  margin-bottom: 28px;
}

.preview-section {
  background: var(--gray-50);
  border-radius: var(--radius-md);
  padding: 20px;
  margin-bottom: 28px;
}

.preview-title {
  font-size: 12px;
  font-weight: 600;
  color: var(--text-muted);
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 8px;
}

.preview-number {
  font-size: 24px;
  font-weight: 700;
  color: var(--primary-600);
  font-family: var(--font-mono);
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  padding-top: 20px;
  border-top: 1px solid var(--border-light);
}

@media (max-width: 768px) {
  .admin-page {
    padding: 20px 16px;
  }

  .content-card {
    padding: 20px;
  }

  .form-grid {
    grid-template-columns: 1fr;
  }
}
</style>
