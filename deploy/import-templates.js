const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');
const JSZip = require('jszip');

const projectDir = path.resolve(__dirname, '..');
const dbPath = path.join(projectDir, 'backend', 'data', 'approval.db');
const templatesDir = path.join(projectDir, 'templates');
const targetDir = path.join(projectDir, 'backend', 'data', 'templates');

if (!fs.existsSync(templatesDir)) {
    console.log('模板目录不存在，跳过导入');
    process.exit(0);
}

const files = fs.readdirSync(templatesDir).filter(f => f.endsWith('.docx'));
if (files.length === 0) {
    console.log('未发现 .docx 模板文件，跳过导入');
    process.exit(0);
}

console.log(`发现 ${files.length} 个模板文件`);

const db = new Database(dbPath);

// 确保目标目录存在
fs.mkdirSync(targetDir, { recursive: true });

const insertTemplate = db.prepare(`
    INSERT OR REPLACE INTO templates (category, step, filename, variables)
    VALUES (?, ?, ?, ?)
`);

async function extractVariables(filePath) {
    try {
        const content = fs.readFileSync(filePath);
        const zip = await JSZip.loadAsync(content);
        const xml = await zip.file('word/document.xml')?.async('string') || '';
        const variables = [];
        const regex = /\$\{(\w+)\}/g;
        let match;
        while ((match = regex.exec(xml)) !== null) {
            if (!variables.includes(match[1])) {
                variables.push(match[1]);
            }
        }
        return variables;
    } catch (e) {
        return [];
    }
}

async function importTemplates() {
    const insertMany = db.transaction((templates) => {
        for (const t of templates) {
            insertTemplate.run(t.category, t.step, t.filename, JSON.stringify(t.variables));
        }
    });

    const templates = [];
    for (const file of files) {
        const basename = file.replace('.docx', '');
        let category = basename;
        let step = basename;

        const match = basename.match(/^(.+?)(\d+)$/);
        if (match) {
            category = match[1];
            step = `${category}-${match[2]}`;
        }

        const sourcePath = path.join(templatesDir, file);
        const targetPath = path.join(targetDir, file);
        fs.copyFileSync(sourcePath, targetPath);

        const variables = await extractVariables(sourcePath);
        templates.push({ category, step, filename: file, variables });
    }

    insertMany(templates);

    for (const t of templates) {
        console.log(`  ✓ ${t.filename} -> ${t.category} / ${t.step}`);
    }
}

importTemplates()
    .then(() => {
        db.close();
        console.log('模板导入完成');
    })
    .catch((err) => {
        console.error('模板导入失败:', err.message);
        db.close();
        process.exit(1);
    });
