import fs from 'fs';
import path from 'path';
import Docxtemplater from 'docxtemplater';
import PizZip from 'pizzip';

const TEMPLATES_DIR = path.join(__dirname, '..', '..', 'data', 'templates');
const OUTPUT_DIR = path.join(__dirname, '..', '..', 'data', 'approvals');

if (!fs.existsSync(OUTPUT_DIR)) {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
}

interface ApprovalData {
  name: string;
  title: string;
  ref_org: string;
  ref_person?: string;
  meet_time?: string;
  [key: string]: any;
}

export function generateApprovalDoc(templateFilename: string, data: ApprovalData): string {
  const templatePath = path.join(TEMPLATES_DIR, templateFilename);

  if (!fs.existsSync(templatePath)) {
    throw new Error(`模板文件不存在: ${templateFilename}`);
  }

  const content = fs.readFileSync(templatePath, 'binary');
  const zip = new PizZip(content);
  const doc = new Docxtemplater(zip, {
    paragraphLoop: true,
    linebreaks: true
  });

  doc.render(data);

  const buf = doc.getZip().generate({
    type: 'nodebuffer',
    compression: 'DEFLATE'
  });

  const timestamp = Date.now();
  const outputFilename = `approval_${timestamp}.docx`;
  const outputPath = path.join(OUTPUT_DIR, outputFilename);

  fs.writeFileSync(outputPath, buf);

  return outputPath;
}
