const fs = require('fs');
const path = require('path');
const Database = require('better-sqlite3');
const JSZip = require('jszip');

const dbPath = path.join(__dirname, '..', 'data', 'approval.db');
const sourceDir = path.join(__dirname, '..', '..', 'templates');
const targetDir = path.join(__dirname, '..', 'data', 'templates');

async function importTemplates() {
  const db = new Database(dbPath);
  db.pragma('journal_mode = WAL');

  console.log('=== 开始导入模板 ===');

  try {
    if (!fs.existsSync(targetDir)) {
      fs.mkdirSync(targetDir, { recursive: true });
      console.log('   ✓ 创建目标目录:', targetDir);
    }

    const files = fs.readdirSync(sourceDir).filter(file => file.endsWith('.docx'));
    console.log(`\n1. 发现 ${files.length} 个模板文件`);

    const insertTemplate = db.prepare(`
      INSERT INTO templates (category, step, filename, variables)
      VALUES (?, ?, ?, ?)
    `);

    let successCount = 0;
    let failCount = 0;

    for (const file of files) {
      try {
        const basename = file.replace('.docx', '');
        
        let category = basename;
        let step = basename;
        
        const match = basename.match(/^(.+?)(\d+)$/);
        if (match) {
          category = match[1];
          step = `${category}-${match[2]}`;
        }

        const sourcePath = path.join(sourceDir, file);
        const targetPath = path.join(targetDir, file);

        fs.copyFileSync(sourcePath, targetPath);

        const content = fs.readFileSync(sourcePath);
        const zip = await JSZip.loadAsync(content);
        const xml = await zip.file('word/document.xml')?.async('string') || '';

        const regex = /\$\{(\w+)\}/g;
        const variables = [];
        let matchVar;
        while ((matchVar = regex.exec(xml)) !== null) {
          if (!variables.includes(matchVar[1])) {
            variables.push(matchVar[1]);
          }
        }

        insertTemplate.run(category, step, file, JSON.stringify(variables));
        
        console.log(`   ✓ ${file} -> ${category} / ${step} (${variables.length}个变量)`);
        successCount++;

      } catch (error) {
        console.log(`   ✗ ${file} -> 导入失败: ${error.message}`);
        failCount++;
      }
    }

    console.log(`\n=== 导入完成 ===`);
    console.log(`成功: ${successCount} 个`);
    console.log(`失败: ${failCount} 个`);

  } catch (error) {
    console.error('导入失败:', error);
    process.exit(1);
  } finally {
    db.close();
  }
}

importTemplates();
