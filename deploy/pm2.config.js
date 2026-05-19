const path = require('path');

const PROJECT_DIR = path.resolve(__dirname, '..');
const LOG_DIR = path.join(PROJECT_DIR, 'logs');

module.exports = {
  apps: [
    {
      name: 'approval-backend',
      script: 'npm',
      args: 'run start',
      cwd: path.join(PROJECT_DIR, 'backend'),
      interpreter: 'none',
      env: {
        NODE_ENV: 'production',
        PORT: 3000
      },
      error_file: path.join(LOG_DIR, 'backend-error.log'),
      out_file: path.join(LOG_DIR, 'backend-out.log'),
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
      cwd: path.join(PROJECT_DIR, 'frontend'),
      interpreter: 'none',
      env: {
        NODE_ENV: 'production'
      },
      error_file: path.join(LOG_DIR, 'frontend-error.log'),
      out_file: path.join(LOG_DIR, 'frontend-out.log'),
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      merge_logs: true,
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '500M'
    }
  ]
};
