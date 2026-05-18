<template>
  <div class="templates">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>模板管理</span>
          <el-button type="primary" @click="showUploadDialog = true">上传模板</el-button>
        </div>
      </template>

      <el-table :data="templates" style="width: 100%">
        <el-table-column prop="id" label="ID" width="60" />
        <el-table-column prop="category" label="类别" />
        <el-table-column prop="step" label="进度" />
        <el-table-column prop="filename" label="文件名" />
        <el-table-column prop="variables" label="变量">
          <template #default="{ row }">
            <el-tag v-for="v in parseVariables(row.variables)" :key="v" size="small" style="margin: 2px;">{{ v }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="150">
          <template #default="{ row }">
            <el-button link type="primary" @click="editTemplate(row)">编辑</el-button>
            <el-popconfirm title="确定删除吗？" @confirm="deleteTemplate(row.id)">
              <template #reference>
                <el-button link type="danger">删除</el-button>
              </template>
            </el-popconfirm>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 上传模板对话框 -->
    <el-dialog v-model="showUploadDialog" title="上传模板">
      <el-form :model="uploadForm" label-width="80px">
        <el-form-item label="类别" required>
          <el-select v-model="uploadForm.category">
            <el-option v-for="cat in categories" :key="cat" :label="cat" :value="cat" />
          </el-select>
        </el-form-item>
        <el-form-item label="进度" required>
          <el-input v-model="uploadForm.step" placeholder="如: 成立-1, 换届-2" />
        </el-form-item>
        <el-form-item label="模板文件" required>
          <el-upload :auto-upload="false" :on-change="onFileChange" accept=".docx">
            <el-button>选择文件</el-button>
            <template #tip>
              <div class="el-upload__tip">只能上传 .docx 文件</div>
            </template>
          </el-upload>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showUploadDialog = false">取消</el-button>
        <el-button type="primary" @click="uploadTemplate" :loading="loading">上传</el-button>
      </template>
    </el-dialog>

    <!-- 编辑模板对话框 -->
    <el-dialog v-model="showEditDialog" title="编辑模板">
      <el-form :model="editForm" label-width="80px">
        <el-form-item label="类别" required>
          <el-select v-model="editForm.category">
            <el-option v-for="cat in categories" :key="cat" :label="cat" :value="cat" />
          </el-select>
        </el-form-item>
        <el-form-item label="进度" required>
          <el-input v-model="editForm.step" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showEditDialog = false">取消</el-button>
        <el-button type="primary" @click="saveEdit" :loading="loading">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import api from '../../api'

const loading = ref(false)
const templates = ref([])
const showUploadDialog = ref(false)
const showEditDialog = ref(false)
const editingTemplate = ref<any>(null)
const uploadFile = ref<File | null>(null)

const categories = ['成立', '换届', '增补', '调整', '更名', '撤销', '延期', '架构调整']

const uploadForm = ref({
  category: '',
  step: ''
})

const editForm = ref({
  category: '',
  step: ''
})

function parseVariables(variables: string) {
  try {
    return JSON.parse(variables)
  } catch {
    return []
  }
}

function onFileChange(file: any) {
  uploadFile.value = file.raw
}

function editTemplate(template: any) {
  editingTemplate.value = template
  editForm.value = {
    category: template.category,
    step: template.step
  }
  showEditDialog.value = true
}

async function uploadTemplate() {
  if (!uploadForm.value.category || !uploadForm.value.step || !uploadFile.value) {
    ElMessage.warning('请填写所有必填字段')
    return
  }

  loading.value = true
  try {
    const formData = new FormData()
    formData.append('file', uploadFile.value)
    formData.append('category', uploadForm.value.category)
    formData.append('step', uploadForm.value.step)

    await api.post('/templates', formData, {
      headers: { 'Content-Type': 'multipart/form-data' }
    })

    ElMessage.success('上传成功')
    showUploadDialog.value = false
    uploadForm.value = { category: '', step: '' }
    uploadFile.value = null
    loadTemplates()
  } catch (error: any) {
    ElMessage.error(error.response?.data?.error || '上传失败')
  } finally {
    loading.value = false
  }
}

async function saveEdit() {
  loading.value = true
  try {
    await api.put(`/templates/${editingTemplate.value.id}`, editForm.value)
    ElMessage.success('更新成功')
    showEditDialog.value = false
    loadTemplates()
  } catch (error: any) {
    ElMessage.error(error.response?.data?.error || '更新失败')
  } finally {
    loading.value = false
  }
}

async function deleteTemplate(id: number) {
  try {
    await api.delete(`/templates/${id}`)
    ElMessage.success('删除成功')
    loadTemplates()
  } catch (error: any) {
    ElMessage.error(error.response?.data?.error || '删除失败')
  }
}

async function loadTemplates() {
  try {
    const response = await api.get('/templates')
    templates.value = response.data
  } catch (error) {
    console.error('获取模板列表失败:', error)
  }
}

onMounted(() => {
  loadTemplates()
})
</script>

<style scoped>
.templates {
  padding: 20px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
