<template>
  <div class="batch-numbers">
    <el-card>
      <template #header>
        <span>批复号管理</span>
      </template>

      <el-form :model="form" label-width="120px">
        <el-form-item label="年份">
          <el-input :value="currentYear" disabled />
        </el-form-item>
        <el-form-item label="前缀">
          <el-input v-model="form.prefix" />
        </el-form-item>
        <el-form-item label="当前序号">
          <el-input-number v-model="form.current_seq" :min="0" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="save" :loading="loading">保存</el-button>
        </el-form-item>
      </el-form>
    </el-card>
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
.batch-numbers {
  padding: 20px;
}
</style>
