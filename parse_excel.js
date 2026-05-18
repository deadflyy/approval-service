const XLSX = require('xlsx');
const path = require('path');

const filePath = path.join(__dirname, 'approval', '2026年组织建设批复进度表.xlsx');

const workbook = XLSX.readFile(filePath);
const sheetName = workbook.SheetNames[0];
const worksheet = workbook.Sheets[sheetName];

const data = XLSX.utils.sheet_to_json(worksheet, { header: 1 });

console.log('Excel文件内容:');
console.log('行数:', data.length);
console.log('\n表头:');
console.log(data[0]);
console.log('\n示例数据（前5行）:');
for (let i = 1; i < Math.min(6, data.length); i++) {
  console.log(`行${i}:`, data[i]);
}
