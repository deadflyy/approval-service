<template>
  <div class="login-page">
    <!-- Decorative background -->
    <div class="login-bg">
      <div class="bg-shape bg-shape-1"></div>
      <div class="bg-shape bg-shape-2"></div>
      <div class="bg-shape bg-shape-3"></div>
      <div class="bg-grid"></div>
    </div>

    <div class="login-container">
      <!-- Left branding -->
      <div class="login-branding">
        <div class="brand-content">
          <div class="brand-icon">
            <svg width="48" height="48" viewBox="0 0 48 48" fill="none">
              <rect width="48" height="48" rx="14" fill="rgba(255,255,255,0.15)"/>
              <path d="M14 24L20 30L34 16" stroke="white" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
            </svg>
          </div>
          <h1>请示批复系统</h1>
          <p>张江科学城综合党委</p>
          <div class="brand-features">
            <div class="feature-item">
              <el-icon><Check /></el-icon>
              <span>流程标准化</span>
            </div>
            <div class="feature-item">
              <el-icon><Check /></el-icon>
              <span>审批高效化</span>
            </div>
            <div class="feature-item">
              <el-icon><Check /></el-icon>
              <span>管理数字化</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Login form -->
      <div class="login-form-wrapper">
        <div class="login-form-content">
          <div class="form-header">
            <h2>欢迎回来</h2>
            <p>请登录您的账户</p>
          </div>

          <el-form :model="form" @submit.prevent="handleLogin" class="login-form">
            <el-form-item>
              <template #label>
                <span class="form-label">用户名</span>
              </template>
              <el-input
                v-model="form.username"
                placeholder="请输入用户名"
                size="large"
                prefix-icon="User"
              />
            </el-form-item>

            <el-form-item>
              <template #label>
                <span class="form-label">密码</span>
              </template>
              <el-input
                v-model="form.password"
                type="password"
                placeholder="请输入密码"
                show-password
                size="large"
                prefix-icon="Lock"
              />
            </el-form-item>

            <el-form-item>
              <el-button
                type="primary"
                native-type="submit"
                :loading="loading"
                size="large"
                class="login-btn"
              >
                {{ loading ? '登录中...' : '登录' }}
              </el-button>
            </el-form-item>
          </el-form>

          <div class="form-footer">
            
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { ElMessage } from 'element-plus'

const router = useRouter()
const authStore = useAuthStore()
const loading = ref(false)
const form = ref({
  username: '',
  password: ''
})

async function handleLogin() {
  if (!form.value.username || !form.value.password) {
    ElMessage.warning('请输入用户名和密码')
    return
  }

  loading.value = true
  try {
    await authStore.login(form.value.username, form.value.password)
    router.push('/dashboard')
  } catch (error: any) {
    ElMessage.error(error.response?.data?.error || '登录失败')
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--gray-950);
  position: relative;
  overflow: hidden;
}

/* Background decoration */
.login-bg {
  position: absolute;
  inset: 0;
  pointer-events: none;
}

.bg-shape {
  position: absolute;
  border-radius: 50%;
  filter: blur(80px);
  opacity: 0.4;
}

.bg-shape-1 {
  width: 500px;
  height: 500px;
  background: var(--primary-600);
  top: -150px;
  right: -100px;
}

.bg-shape-2 {
  width: 400px;
  height: 400px;
  background: var(--primary-400);
  bottom: -100px;
  left: -100px;
}

.bg-shape-3 {
  width: 300px;
  height: 300px;
  background: #818cf8;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
}

.bg-grid {
  position: absolute;
  inset: 0;
  background-image:
    linear-gradient(rgba(255,255,255,0.03) 1px, transparent 1px),
    linear-gradient(90deg, rgba(255,255,255,0.03) 1px, transparent 1px);
  background-size: 60px 60px;
}

/* Container */
.login-container {
  display: flex;
  width: 900px;
  max-width: 95vw;
  min-height: 540px;
  border-radius: var(--radius-xl);
  overflow: hidden;
  box-shadow: 0 25px 60px rgba(0, 0, 0, 0.3);
  position: relative;
  z-index: 1;
}

/* Left branding */
.login-branding {
  width: 380px;
  background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%);
  padding: 48px 36px;
  display: flex;
  align-items: center;
  position: relative;
  overflow: hidden;
}

.login-branding::before {
  content: '';
  position: absolute;
  inset: 0;
  background:
    radial-gradient(circle at 20% 80%, rgba(61, 82, 245, 0.2) 0%, transparent 50%),
    radial-gradient(circle at 80% 20%, rgba(96, 120, 255, 0.15) 0%, transparent 50%);
}

.brand-content {
  position: relative;
  z-index: 1;
}

.brand-icon {
  margin-bottom: 24px;
}

.brand-content h1 {
  color: #fff;
  font-size: 28px;
  font-weight: 700;
  letter-spacing: -0.02em;
  margin-bottom: 8px;
}

.brand-content > p {
  color: var(--gray-400);
  font-size: 15px;
  font-weight: 400;
  margin-bottom: 40px;
}

.brand-features {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.feature-item {
  display: flex;
  align-items: center;
  gap: 10px;
  color: var(--gray-300);
  font-size: 14px;
  font-weight: 450;
}

.feature-item .el-icon {
  color: var(--success);
  font-size: 16px;
}

/* Right form */
.login-form-wrapper {
  flex: 1;
  background: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 48px 40px;
}

.login-form-content {
  width: 100%;
  max-width: 340px;
}

.form-header {
  margin-bottom: 36px;
}

.form-header h2 {
  color: var(--text-primary);
  font-size: 24px;
  font-weight: 700;
  letter-spacing: -0.02em;
  margin-bottom: 6px;
}

.form-header p {
  color: var(--text-muted);
  font-size: 14px;
}

.login-form {
  margin-bottom: 24px;
}

.form-label {
  font-size: 13px;
  font-weight: 500;
  color: var(--text-secondary);
}

.login-btn {
  width: 100%;
  height: 46px;
  font-size: 15px;
  font-weight: 600;
  margin-top: 8px;
}

.form-footer {
  text-align: center;
  padding-top: 20px;
  border-top: 1px solid var(--border-light);
}

.form-footer p {
  color: var(--text-muted);
  font-size: 12px;
}

@media (max-width: 768px) {
  .login-container {
    flex-direction: column;
    min-height: auto;
    margin: 16px;
  }

  .login-branding {
    width: 100%;
    padding: 32px 24px;
  }

  .brand-features {
    display: none;
  }

  .login-form-wrapper {
    padding: 32px 24px;
  }
}
</style>
