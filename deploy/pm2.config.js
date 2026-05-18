module.exports = {
  apps: [
    {
      name: 'approval-backend',
      script: 'npm',
      args: 'run dev',
      cwd: '/opt/approval-service/backend',
      interpreter: 'none',
      env: {
        NODE_ENV: 'production',
        PORT: 3000
      },
      error_file: '/opt/approval-service/logs/backend-error.log',
      out_file: '/opt/approval-service/logs/backend-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '500M'
    },
    {
      name: 'approval-frontend',
      script: 'npm',
      args: 'run preview',
      cwd: '/opt/approval-service/frontend',
      interpreter: 'none',
      env: {
        NODE_ENV: 'production'
      },
      error_file: '/opt/approval-service/logs/frontend-error.log',
      out_file: '/opt/approval-service/logs/frontend-out.log',
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '500M'
    }
  ]
};
