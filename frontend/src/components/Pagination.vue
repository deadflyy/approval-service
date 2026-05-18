<template>
  <div class="pagination-wrapper">
    <div class="pagination-info">
      <span class="total-text">
        共 <strong>{{ total }}</strong> 条记录
      </span>
      <span class="separator">·</span>
      <span class="page-text">
        第 <strong>{{ currentPage }}</strong> / <strong>{{ totalPages }}</strong> 页
      </span>
    </div>

    <el-pagination
      v-model:current-page="currentPage"
      v-model:page-size="currentPageSize"
      :page-sizes="pageSizes"
      :total="total"
      layout="sizes, prev, pager, next, jumper"
      @size-change="handleSizeChange"
      @current-change="handleCurrentChange"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'

interface Props {
  total: number
  page?: number
  pageSize?: number
  pageSizes?: number[]
}

const props = withDefaults(defineProps<Props>(), {
  page: 1,
  pageSize: 20,
  pageSizes: () => [10, 20, 50, 100]
})

const emit = defineEmits<{
  'update:page': [value: number]
  'update:pageSize': [value: number]
}>()

const router = useRouter()
const route = useRoute()

const STORAGE_KEY = 'pagination-page-size'

const currentPage = ref(props.page)
const currentPageSize = ref(props.pageSize)

const totalPages = computed(() => {
  return Math.max(1, Math.ceil(props.total / currentPageSize.value))
})

// Load saved page size from localStorage
onMounted(() => {
  const savedPageSize = localStorage.getItem(STORAGE_KEY)
  if (savedPageSize && props.pageSizes.includes(Number(savedPageSize))) {
    currentPageSize.value = Number(savedPageSize)
    emit('update:pageSize', currentPageSize.value)
  }
})

// Sync with URL params
watch(() => route.query, (query) => {
  if (query.page) {
    currentPage.value = Number(query.page) || 1
  }
  if (query.pageSize && props.pageSizes.includes(Number(query.pageSize))) {
    currentPageSize.value = Number(query.pageSize)
  }
}, { immediate: true })

// Sync with props
watch(() => props.page, (val) => {
  currentPage.value = val
})

watch(() => props.pageSize, (val) => {
  currentPageSize.value = val
})

function handleSizeChange(size: number) {
  currentPageSize.value = size
  currentPage.value = 1
  localStorage.setItem(STORAGE_KEY, String(size))
  updateUrl()
  emit('update:pageSize', size)
  emit('update:page', 1)
}

function handleCurrentChange(page: number) {
  currentPage.value = page
  updateUrl()
  emit('update:page', page)
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

function updateUrl() {
  const query: Record<string, string> = { ...route.query } as Record<string, string>

  if (currentPage.value > 1) {
    query.page = String(currentPage.value)
  } else {
    delete query.page
  }

  if (currentPageSize.value !== 20) {
    query.pageSize = String(currentPageSize.value)
  } else {
    delete query.pageSize
  }

  router.replace({ query })
}
</script>

<style scoped>
.pagination-wrapper {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 20px 24px;
  background: var(--bg-card);
  border-top: 1px solid var(--border-light);
}

.pagination-info {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 13px;
  color: var(--text-muted);
}

.pagination-info strong {
  color: var(--text-primary);
  font-weight: 600;
}

.separator {
  color: var(--gray-300);
}

/* Override Element Plus pagination styles */
:deep(.el-pagination) {
  --el-pagination-font-size: 13px;
  --el-pagination-button-color: var(--text-secondary);
  --el-pagination-hover-color: var(--primary-600);
}

:deep(.el-pagination .el-pagination__sizes) {
  margin-right: 16px;
}

:deep(.el-pagination .el-select .el-input) {
  width: 100px;
}

:deep(.el-pagination .el-select .el-input__wrapper) {
  border-radius: var(--radius-sm) !important;
  box-shadow: 0 0 0 1px var(--border-light) inset;
}

:deep(.el-pagination .el-select .el-input__wrapper:hover) {
  box-shadow: 0 0 0 1px var(--primary-300) inset;
}

:deep(.el-pagination .el-select .el-input.is-focus .el-input__wrapper) {
  box-shadow: 0 0 0 1px var(--primary-500) inset, 0 0 0 3px rgb(61 82 245 / 0.1) !important;
}

:deep(.el-pagination .btn-prev),
:deep(.el-pagination .btn-next) {
  border-radius: var(--radius-sm);
  min-width: 32px;
  height: 32px;
}

:deep(.el-pagination .el-pager li) {
  border-radius: var(--radius-sm);
  min-width: 32px;
  height: 32px;
  font-weight: 500;
}

:deep(.el-pagination .el-pager li.is-active) {
  background: var(--primary-600);
  color: #fff;
  box-shadow: 0 2px 6px rgb(61 82 245 / 0.3);
}

:deep(.el-pagination .el-pagination__jump) {
  margin-left: 16px;
  font-size: 13px;
  color: var(--text-muted);
}

:deep(.el-pagination .el-pagination__jump .el-input) {
  width: 50px;
  margin: 0 8px;
}

:deep(.el-pagination .el-pagination__jump .el-input__wrapper) {
  border-radius: var(--radius-sm) !important;
  box-shadow: 0 0 0 1px var(--border-light) inset;
}

:deep(.el-pagination .el-pagination__jump .el-input__wrapper:hover) {
  box-shadow: 0 0 0 1px var(--primary-300) inset;
}

:deep(.el-pagination .el-pagination__jump .el-input.is-focus .el-input__wrapper) {
  box-shadow: 0 0 0 1px var(--primary-500) inset, 0 0 0 3px rgb(61 82 245 / 0.1) !important;
}

@media (max-width: 768px) {
  .pagination-wrapper {
    flex-direction: column;
    gap: 16px;
    padding: 16px;
  }

  .pagination-info {
    order: 2;
  }

  :deep(.el-pagination) {
    order: 1;
    flex-wrap: wrap;
    justify-content: center;
  }
}
</style>
