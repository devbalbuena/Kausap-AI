const fs = require("fs");
const path = require("path");
const {
  Document, Packer, Paragraph, TextRun, HeadingLevel, AlignmentType,
  Table, TableRow, TableCell, WidthType, BorderStyle,
} = require("docx");

const p = (t, o = {}) => new Paragraph({ spacing: { after: 120 }, ...o, children: [new TextRun(t)] });
const rich = (parts) => new Paragraph({ spacing: { after: 120 }, children: parts.map(([t, b]) => new TextRun({ text: t, bold: !!b })) });
const h = (t) => new Paragraph({ heading: HeadingLevel.HEADING_2, spacing: { before: 240, after: 100 }, children: [new TextRun(t)] });
const b = (t) => new Paragraph({ bullet: { level: 0 }, spacing: { after: 60 }, children: [new TextRun(t)] });
const bb = (label, t) => new Paragraph({ bullet: { level: 0 }, spacing: { after: 60 }, children: [new TextRun({ text: label, bold: true }), new TextRun(t)] });

function table(rows, widths) {
  const s = { style: BorderStyle.SINGLE, size: 4, color: "94A3B8" };
  const borders = { top: s, bottom: s, left: s, right: s };
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
  new Paragraph({ heading: HeadingLevel.TITLE, children: [new TextRun("PHQ-9 and GAD-7 Self-Assessment")] }),
  p("How scoring works, why this method is used, and when a result is flagged to the app (counselor).", { alignment: AlignmentType.LEFT }),
  rich([["Project: ", true], ["Kausap AI", false]]),
  rich([["Prepared by: ", true], ["[Your name]", false]]),
  rich([["Date: ", true], ["October 15, 2026", false]]),

  h("1. How the result is calculated"),
  p("Both tests are scored with the standard published method."),
  b("Each question is answered 0 to 3: Not at all (0), Several days (1), More than half the days (2), Nearly every day (3)."),
  b("The total score is the sum of all answers."),
  b("PHQ-9 has 9 questions, so the score runs 0 to 27."),
  b("GAD-7 has 7 questions, so the score runs 0 to 21."),
  b("The total is then matched to a severity band."),

  h("2. Why we use this equation"),
  p("PHQ-9 and GAD-7 are universal, widely validated screening tools, so we did not create our own formula."),
  bb("PHQ-9: ", "Kroenke, Spitzer & Williams (2001). It follows the DSM criteria for major depression."),
  bb("GAD-7: ", "Spitzer, Kroenke, Williams & L\u00F6we (2006)."),
  b("Both use the same simple scoring over the past 2 weeks."),
  b("A score of 10 or more is the accepted threshold for probable depression or generalized anxiety (about 88\u201389% sensitivity)."),
  p(""),
  table([
    ["Score", "PHQ-9 band", "GAD-7 band"],
    ["0\u20134", "Minimal", "Minimal"],
    ["5\u20139", "Mild", "Mild"],
    ["10\u201314", "Moderate", "Moderate"],
    ["15\u201319", "Moderately severe", "Severe (15\u201321)"],
    ["20\u201327", "Severe", "n/a"],
  ], [2000, 3700, 3700]),

  h("3. When a result is flagged to the app (counselor)"),
  p("A student's result is sent to the counselor triage queue if any of these is true:"),
  b("PHQ-9 question 9 (thoughts of self-harm) is answered above 0, even if the total score is low. This follows standard clinical practice."),
  b("PHQ-9 total score is 15 or higher."),
  b("GAD-7 total score is 15 or higher."),
  p(""),
  p("What happens when a result is flagged:"),
  b("The case appears in the counselor's Triage tab with the score and the reason."),
  b("The student is told that the Guidance & Counseling Office may reach out."),
  b("If question 9 is positive, the student sees the NCMH Crisis Hotline 1553 (free, 24/7) with a one-tap call button, plus the other hotline numbers."),
  b("The server re-checks the rules itself, so the app alone cannot decide a flag."),
  b("If the phone is offline, the flag is saved and sent when the student next checks in."),
  b("The same case is not flagged twice within 6 hours."),

  h("4. Important notes"),
  b("These are screening tools, not a diagnosis. The app says this on the result screen, and we no longer describe them as \u201Clicensed assessments\u201D."),
  b("The PHQ-9 now shows the standard 5 bands. Before, scores of 15 and above were grouped into one \u201CElevated\u201D band."),

  h("5. Current status"),
  b("Done: scoring, the 5 PHQ-9 bands, flagging rules, the hotline card and the wording changes."),
  b("Backend rules are tested. The backend still has to be deployed to Render."),
  b("The app changes still need flutter analyze and a device test before release."),
  p(""),
  p("Please let me know if you would like the counselor to be notified in another way, for example by email through Brevo."),

  h("References"),
  b("Kroenke, K., Spitzer, R. L., & Williams, J. B. W. (2001). The PHQ-9: Validity of a brief depression severity measure. Journal of General Internal Medicine, 16(9), 606\u2013613."),
  b("Spitzer, R. L., Kroenke, K., Williams, J. B. W., & L\u00F6we, B. (2006). A brief measure for assessing generalized anxiety disorder: The GAD-7. Archives of Internal Medicine, 166(10), 1092\u20131097."),
];

const doc = new Document({
  styles: { default: { document: { run: { font: "Calibri", size: 22 } } } },
  sections: [{ properties: { page: { margin: { top: 1080, bottom: 1080, left: 1260, right: 1260 } } }, children }],
});
Packer.toBuffer(doc).then((buf) => {
  fs.writeFileSync(path.join(__dirname, "PHQ9_GAD7_Report_for_PM.docx"), buf);
  console.log("done");
});
