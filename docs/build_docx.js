const fs = require("fs");
const path = require("path");
const {
  Document, Packer, Paragraph, TextRun, ImageRun, HeadingLevel, AlignmentType,
  Table, TableRow, TableCell, WidthType, PageOrientation, BorderStyle,
} = require("docx");

// Read PNG dimensions from the IHDR chunk
function pngSize(buf) { return { w: buf.readUInt32BE(16), h: buf.readUInt32BE(20) }; }

const MAX_W = 860, MAX_H = 520; // landscape page, in points-ish pixels
function img(file) {
  const data = fs.readFileSync(path.join(__dirname, "diagrams", file));
  const { w, h } = pngSize(data);
  const s = Math.min(MAX_W / w, MAX_H / h, 1);
  return new Paragraph({
    alignment: AlignmentType.CENTER,
    children: [new ImageRun({ type: "png", data, transformation: { width: Math.round(w * s), height: Math.round(h * s) } })],
  });
}
const h1 = (t) => new Paragraph({ heading: HeadingLevel.HEADING_1, pageBreakBefore: true, children: [new TextRun(t)] });
const h2 = (t) => new Paragraph({ heading: HeadingLevel.HEADING_2, spacing: { before: 200 }, children: [new TextRun(t)] });
const p = (t) => new Paragraph({ spacing: { after: 120 }, children: [new TextRun(t)] });
const cap = (t) => new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 200 }, children: [new TextRun({ text: t, italics: true, size: 20 })] });
const bullet = (t) => new Paragraph({ bullet: { level: 0 }, children: [new TextRun(t)] });

function table(rows, widths) {
  const b = { style: BorderStyle.SINGLE, size: 4, color: "94A3B8" };
  const borders = { top: b, bottom: b, left: b, right: b };
  return new Table({
    width: { size: widths.reduce((a, c) => a + c, 0), type: WidthType.DXA },
    columnWidths: widths,
    rows: rows.map((r, i) => new TableRow({
      tableHeader: i === 0,
      children: r.map((c, j) => new TableCell({
        borders, width: { size: widths[j], type: WidthType.DXA },
        shading: i === 0 ? { fill: "0284C7" } : undefined,
        margins: { top: 60, bottom: 60, left: 100, right: 100 },
        children: [new Paragraph({ children: [new TextRun({ text: c, bold: i === 0, color: i === 0 ? "FFFFFF" : "000000", size: 20 })] })],
      })),
    })),
  });
}

const children = [
  new Paragraph({ heading: HeadingLevel.TITLE, children: [new TextRun("Kausap AI — System Design Documentation")] }),
  p("Software Development Model, System Flowcharts, Data Flow Diagrams, Use Case Diagram, and Entity Relationship Diagram."),

  h2("1. Software Development Model"),
  p("The Kausap AI platform was developed using the Agile Iterative-Incremental model. The system was built in small, working increments (24+ tracked phases, from backend setup and signup flows to dark mode, security hardening, and micro-interactions), with each increment going through planning, design, development, testing, deployment, and review. Feedback from beta testers (students and counselors) fed directly into the product backlog for the next increment."),
  p("This model was chosen because mental-health requirements (clinical guardrails, counselor triage, privacy) evolved as stakeholders reviewed working builds, and because it allowed continuous delivery via CI/CD."),
  table([
    ["Stage", "Activities in Kausap AI", "Tools"],
    ["Planning", "Select phase scope from backlog; write implementation plans", "Markdown plans, GitHub"],
    ["Design", "UI screens, REST API contracts, SQLModel database schema", "Flutter widgets, FastAPI, SQLModel"],
    ["Development", "Flutter client and FastAPI backend, AI provider chain, clinical guardrails", "Dart, Python, VS Code / Antigravity IDE"],
    ["Testing", "Backend test suites, E2E browser test, static analysis", "Pytest scripts, Playwright, flutter analyze"],
    ["Deployment", "Automated web and APK builds; backend hosting", "GitHub Actions, Firebase Hosting, Render"],
    ["Review", "Beta feedback and bug-fix cycle", "Sentry monitoring, beta testing notes"],
  ], [1700, 5200, 3000]),
  img("01_sdlc_model.png"),
  cap("Figure 1. Agile Iterative-Incremental Development Model"),

  h1("2. System Flowcharts"),
  p("Flowchart 1 shows the overall user journey and role-based routing (Student, Counselor, Administrator). Flowchart 2 details the AI chat pipeline with its three safety layers and multi-provider fallback chain."),
  img("02_system_flowchart_main.png"),
  cap("Figure 2. Main System Flowchart"),
  h1("2.1 AI Chat Pipeline Flowchart"),
  img("03_system_flowchart_ai.png"),
  cap("Figure 3. AI Chat Pipeline and Clinical Guardrails Flowchart"),

  h1("3. Data Flow Diagram"),
  h2("3.1 Context Diagram (Level 0)"),
  img("04_dfd_level0.png"),
  cap("Figure 4. DFD Level 0 — Context Diagram"),
  h1("3.2 Level 1 Data Flow Diagram"),
  img("05_dfd_level1.png"),
  cap("Figure 5. DFD Level 1"),

  h1("4. Use Case Diagram"),
  p("Actors: Student/Client, Guidance Counselor, System Administrator; external actors: AI Provider and Email Service."),
  h2("4.1 Student / Client"),
  img("06a_use_case_student.png"),
  cap("Figure 6. Use Case Diagram — Student / Client"),
  h1("4.2 Guidance Counselor"),
  img("06b_use_case_counselor.png"),
  cap("Figure 7. Use Case Diagram — Guidance Counselor"),
  h1("4.3 System Administrator"),
  img("06c_use_case_admin.png"),
  cap("Figure 8. Use Case Diagram — System Administrator"),

  h1("5. Entity Relationship Diagram"),
  p("Database: Neon Serverless PostgreSQL, modeled with SQLModel/SQLAlchemy."),
  img("07_erd.png"),
  cap("Figure 9. Entity Relationship Diagram"),
];

const doc = new Document({
  styles: { default: { document: { run: { font: "Calibri", size: 22 } } } },
  sections: [{
    properties: { page: { size: { orientation: PageOrientation.LANDSCAPE }, margin: { top: 720, bottom: 720, left: 720, right: 720 } } },
    children,
  }],
});
Packer.toBuffer(doc).then((b) => { fs.writeFileSync(path.join(__dirname, "Kausap_AI_System_Design.docx"), b); console.log("done"); });
