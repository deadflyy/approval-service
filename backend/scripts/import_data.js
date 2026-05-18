const XLSX = require('xlsx');
const path = require('path');
const Database = require('better-sqlite3');

const dbPath = path.join(__dirname, '..', 'data', 'approval.db');
const excelPath = path.join(__dirname, '..', '..', 'approval', '2026年组织建设批复进度表.xlsx');

const db = new Database(dbPath);
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = OFF');

console.log('=== 开始导入数据 ===');

try {
  console.log('\n1. 清除现有组织数据...');
  db.prepare('DELETE FROM organizations').run();
  db.prepare('DELETE FROM user_org_auth').run();
  db.prepare('DELETE FROM requests').run();
  db.prepare("UPDATE SQLITE_SEQUENCE SET seq = 0 WHERE name IN ('organizations', 'requests')").run();
  console.log('   ✓ 组织和请示数据已清除');

  console.log('\n2. 读取Excel文件...');
  const workbook = XLSX.readFile(excelPath);
  const sheetName = workbook.SheetNames[0];
  const worksheet = workbook.Sheets[sheetName];
  const data = XLSX.utils.sheet_to_json(worksheet, { header: 1 });
  
  console.log(`   ✓ 读取成功，共 ${data.length} 行数据`);

  const orgNames = new Set();
  const requests = [];

  for (let i = 11; i < data.length; i++) {
    const row = data[i];
    if (!row || !row[0] || typeof row[0] === 'string' && row[0].trim() === '') {
      continue;
    }

    const orgName = row[1] ? String(row[1]).trim() : '';
    const title = row[2] ? String(row[2]).trim() : '';
    const category = row[11] ? String(row[11]).trim() : '';
    const step = row[12] ? String(row[12]).trim() : '';
    const pageCount = row[3] ? parseInt(String(row[3])) || 0 : 0;
    const secretary = row[7] ? String(row[7]).trim() : '';
    const deputySecretary = row[8] ? String(row[8]).trim() : '';
    const members = row[9] ? String(row[9]).trim() : '';
    const involvedOrgs = row[6] ? String(row[6]).trim() : '';

    if (orgName) {
      orgNames.add(orgName);
    }

    if (involvedOrgs) {
      const orgs = involvedOrgs.split('\n').map(o => o.trim()).filter(o => o);
      orgs.forEach(o => orgNames.add(o));
    }

    if (title && category) {
      requests.push({
        orgName,
        title,
        category,
        step,
        pageCount,
        secretary,
        deputySecretary,
        members,
        involvedOrgs
      });
    }
  }

  console.log(`\n3. 导入组织数据...`);
  console.log(`   共发现 ${orgNames.size} 个党组织`);
  
  const orgMap = {};
  const insertOrg = db.prepare(`
    INSERT INTO organizations (name, parent_id, level)
    VALUES (?, ?, ?)
  `);

  let orgCount = 0;
  for (const orgName of orgNames) {
    if (!orgName || typeof orgName !== 'string') continue;
    
    let level = 'branch';
    if (orgName.includes('党委')) {
      level = 'party_committee';
    } else if (orgName.includes('总支')) {
      level = 'general_branch';
    } else if (orgName.includes('支部')) {
      level = 'branch';
    }

    const result = insertOrg.run(orgName, null, level);
    orgMap[orgName] = result.lastInsertRowid;
    orgCount++;
  }

  console.log(`   ✓ 成功导入 ${orgCount} 个组织`);

  console.log(`\n4. 导入请示批复数据...`);
  console.log(`   共 ${requests.length} 条记录`);

  const insertRequest = db.prepare(`
    INSERT INTO requests (
      org_id, user_id, title, category, step, status, 
      page_count, secretary_candidate, deputy_secretary_candidate, 
      committee_members, involved_orgs
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `);

  let reqCount = 0;
  for (const req of requests) {
    const orgId = orgMap[req.orgName] || 1;
    const finalStep = req.step || (req.category === '换届' ? '换届-1' : 
                                   req.category === '成立' ? '成立' : 
                                   req.category === '增补' ? '增补-1' : req.category);

    insertRequest.run(
      orgId,
      1,
      req.title,
      req.category,
      finalStep,
      'approved',
      req.pageCount,
      req.secretary,
      req.deputySecretary,
      req.members,
      req.involvedOrgs
    );
    reqCount++;
  }

  console.log(`   ✓ 成功导入 ${reqCount} 条请示`);

  db.pragma('foreign_keys = ON');
  console.log('\n=== 数据导入完成 ===');
  console.log(`\n统计信息:`);
  console.log(`- 党组织: ${orgCount} 个`);
  console.log(`- 请示记录: ${reqCount} 条（状态均为已通过）`);

} catch (error) {
  console.error('导入失败:', error);
  db.pragma('foreign_keys = ON');
  process.exit(1);
} finally {
  db.close();
}
