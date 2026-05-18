const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');
const JSZip = require('jszip');

const projectDir = path.dirname(path.dirname(__dirname));
const dbPath = path.join(projectDir, 'backend', 'data', 'approval.db');
const templatesDir = path.join(projectDir, 'templates');
const targetTemplatesDir = path.join(projectDir, 'backend', 'data', 'templates');

const db = new Database(dbPath);

if (!fs.existsSync(targetTemplatesDir)) {
    fs.mkdirSync(targetTemplatesDir, { recursive: true });
}

const files = fs.readdirSync(templatesDir).filter(file => file.endsWith('.docx'));
console.log(`发现 ${files.length} 个模板文件`);

const insertTemplate = db.prepare(`
    INSERT INTO templates (category, step, filename, variables)
    VALUES (?, ?, ?, ?)
`);

// 清空现有模板
db.prepare('DELETE FROM templates').run();

async function importTemplates() {
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
        const targetPath = path.join(targetTemplatesDir, file);
        
        fs.copyFileSync(sourcePath, targetPath);

        const content = fs.readFileSync(sourcePath);
        let variables = [];
        
        try {
            const zip = await JSZip.loadAsync(content);
            const xml = await zip.file('word/document.xml')?.async('string') || '';
            const regex = /\$\{(\w+)\}/g;
            let matchVar;
            while ((matchVar = regex.exec(xml)) !== null) {
                if (!variables.includes(matchVar[1])) {
                    variables.push(matchVar[1]);
                }
            }
        } catch (e) {
            variables = [];
        }

        insertTemplate.run(category, step, file, JSON.stringify(variables));
        console.log(`  ✓ ${file} -> ${category} / ${step}`);
    }
}

importTemplates().then(() => {
    db.close();
    console.log('模板导入完成');
}).catch((err) => {
    console.error('模板导入失败:', err);
    db.close();
    process.exit(1);
});
