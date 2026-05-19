import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/Login.vue')
  },
  {
    path: '/',
    redirect: '/dashboard'
  },
  {
    path: '/dashboard',
    name: 'Dashboard',
    component: () => import('../views/Dashboard.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/requests',
    name: 'Requests',
    component: () => import('../views/Requests.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/requests/new',
    name: 'NewRequest',
    component: () => import('../views/NewRequest.vue'),
    meta: { requiresAuth: true, roles: ['applicant'] }
  },
  {
    path: '/requests/:id',
    name: 'RequestDetail',
    component: () => import('../views/RequestDetail.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/admin/users',
    name: 'Users',
    component: () => import('../views/admin/Users.vue'),
    meta: { requiresAuth: true, roles: ['admin'] }
  },
  {
    path: '/admin/organizations',
    name: 'Organizations',
    component: () => import('../views/admin/Organizations.vue'),
    meta: { requiresAuth: true, roles: ['admin'] }
  },
  {
    path: '/admin/templates',
    name: 'Templates',
    component: () => import('../views/admin/Templates.vue'),
    meta: { requiresAuth: true, roles: ['admin'] }
  },
  {
    path: '/admin/batch-numbers',
    name: 'BatchNumbers',
    component: () => import('../views/admin/BatchNumbers.vue'),
    meta: { requiresAuth: true, roles: ['admin'] }
  },
  {
    path: '/admin/stats',
    name: 'Stats',
    component: () => import('../views/admin/Stats.vue'),
    meta: { requiresAuth: true, roles: ['admin'] }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach((to, _from, next) => {
  const authStore = useAuthStore()
  const roles = (to.meta as { roles?: string[] }).roles

  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    next('/login')
  } else if (roles && !roles.includes(authStore.user?.role || '')) {
    next('/dashboard')
  } else {
    next()
  }
})

export default router
