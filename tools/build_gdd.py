#!/usr/bin/env python3
"""Builds the GDD PDF and combined Markdown from docs/src/*.md.

Usage: python3 tools/build_gdd.py
Outputs: docs/IdleParty_GDD.pdf, docs/IdleParty_GDD.md
"""
import glob
import os
import re

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (BaseDocTemplate, Frame, KeepTogether, PageBreak,
                                PageTemplate, Paragraph, Preformatted, Spacer,
                                Table, TableStyle, NextPageTemplate, CondPageBreak)
from reportlab.platypus.tableofcontents import TableOfContents

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "docs", "src")
OUT_PDF = os.path.join(ROOT, "docs", "IdleParty_GDD.pdf")
OUT_MD = os.path.join(ROOT, "docs", "IdleParty_GDD.md")

TITLE = "IDLE PARTY: Desktop Legends"
SUBTITLE = "Oyun Tasarım Dokümanı (GDD) ve Yapay Zeka Geliştirme Yol Haritası"
VERSION = "Sürüm 1.0 - Ekim 2026"

FONT_DIR = "/usr/share/fonts/truetype/dejavu"
pdfmetrics.registerFont(TTFont("Sans", f"{FONT_DIR}/DejaVuSans.ttf"))
pdfmetrics.registerFont(TTFont("Sans-Bold", f"{FONT_DIR}/DejaVuSans-Bold.ttf"))
pdfmetrics.registerFont(TTFont("Mono", f"{FONT_DIR}/DejaVuSansMono.ttf"))
pdfmetrics.registerFontFamily("Sans", normal="Sans", bold="Sans-Bold",
                              italic="Sans", boldItalic="Sans-Bold")

# Palette (matches the UI palette in the GDD)
C_DARK = colors.HexColor("#1E1A1F")
C_FRAME = colors.HexColor("#3A2A22")
C_FRAME2 = colors.HexColor("#5C4033")
C_GOLD = colors.HexColor("#C8A165")
C_ORANGE = colors.HexColor("#E8742A")
C_CREAM = colors.HexColor("#F2E6C9")
C_TEXT = colors.HexColor("#2A2328")
C_ROW = colors.HexColor("#F7F1E6")
C_NOTE = colors.HexColor("#FFF3E3")
C_CODE = colors.HexColor("#F1EEF3")

PAGE_W, PAGE_H = A4
MARGIN = 18 * mm
CONTENT_W = PAGE_W - 2 * MARGIN

S = {
    "body": ParagraphStyle("body", fontName="Sans", fontSize=9.2, leading=13.2,
                           textColor=C_TEXT, spaceAfter=5),
    "h1": ParagraphStyle("h1", fontName="Sans-Bold", fontSize=18, leading=23,
                         textColor=C_CREAM, backColor=C_FRAME, borderPadding=(7, 8, 7, 8),
                         spaceBefore=4, spaceAfter=14),
    "h2": ParagraphStyle("h2", fontName="Sans-Bold", fontSize=13, leading=17,
                         textColor=C_ORANGE, spaceBefore=10, spaceAfter=6),
    "h3": ParagraphStyle("h3", fontName="Sans-Bold", fontSize=10.5, leading=14,
                         textColor=C_FRAME2, spaceBefore=8, spaceAfter=4),
    "bullet": ParagraphStyle("bullet", fontName="Sans", fontSize=9.2, leading=13,
                             textColor=C_TEXT, leftIndent=14, bulletIndent=4, spaceAfter=2),
    "bullet2": ParagraphStyle("bullet2", fontName="Sans", fontSize=9, leading=12.5,
                              textColor=C_TEXT, leftIndent=28, bulletIndent=18, spaceAfter=2),
    "cell": ParagraphStyle("cell", fontName="Sans", fontSize=7.6, leading=9.6, textColor=C_TEXT),
    "cellh": ParagraphStyle("cellh", fontName="Sans-Bold", fontSize=7.8, leading=9.8,
                            textColor=C_CREAM),
    "note": ParagraphStyle("note", fontName="Sans", fontSize=9, leading=13, textColor=C_TEXT),
    "code": ParagraphStyle("code", fontName="Mono", fontSize=7, leading=9, textColor=C_TEXT),
    "toc0": ParagraphStyle("toc0", fontName="Sans-Bold", fontSize=10, leading=15,
                           textColor=C_FRAME, leftIndent=6),
    "toc1": ParagraphStyle("toc1", fontName="Sans", fontSize=8.5, leading=11.5,
                           textColor=C_TEXT, leftIndent=22),
}


def inline(text: str) -> str:
    """Escape and convert minimal markdown inline markup to reportlab markup."""
    text = text.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
    text = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", text)
    text = re.sub(r"`([^`]+)`", r'<font face="Mono" size="8" color="#7A3E1D">\1</font>', text)
    return text


class GDDDoc(BaseDocTemplate):
    def __init__(self, path):
        super().__init__(path, pagesize=A4, leftMargin=MARGIN, rightMargin=MARGIN,
                         topMargin=MARGIN + 6, bottomMargin=MARGIN,
                         title=TITLE, author="IDLE PARTY ekibi", subject=SUBTITLE)
        frame = Frame(MARGIN, MARGIN, CONTENT_W, PAGE_H - 2 * MARGIN - 6, id="f")
        self.addPageTemplates([
            PageTemplate(id="cover", frames=[frame], onPage=draw_cover),
            PageTemplate(id="body", frames=[frame], onPage=draw_page),
        ])
        self._h_seq = 0

    def beforeDocument(self):
        self._h_seq = 0

    def afterFlowable(self, flowable):
        if isinstance(flowable, Paragraph) and getattr(flowable, "_toc_level", None) is not None:
            level = flowable._toc_level
            text = flowable.getPlainText()
            key = f"h{self._h_seq}"
            self._h_seq += 1
            self.canv.bookmarkPage(key)
            self.canv.addOutlineEntry(text, key, level=level, closed=level > 0)
            self.notify("TOCEntry", (level, text, self.page, key))


def draw_page(canv, doc):
    canv.saveState()
    canv.setFillColor(C_FRAME)
    canv.rect(0, PAGE_H - 12 * mm, PAGE_W, 12 * mm, stroke=0, fill=1)
    canv.setFillColor(C_GOLD)
    canv.rect(0, PAGE_H - 12 * mm - 1.2, PAGE_W, 1.2, stroke=0, fill=1)
    canv.setFont("Sans-Bold", 8)
    canv.setFillColor(C_CREAM)
    canv.drawString(MARGIN, PAGE_H - 7.5 * mm, TITLE)
    canv.setFont("Sans", 7.5)
    canv.drawRightString(PAGE_W - MARGIN, PAGE_H - 7.5 * mm, "GDD + AI Yol Haritası")
    canv.setFillColor(C_FRAME2)
    canv.setFont("Sans", 8)
    canv.drawCentredString(PAGE_W / 2, 9 * mm, f"- {doc.page} -")
    canv.restoreState()


# Small pixel-art heroes for the cover (each char = one pixel; '.' transparent)
PIX_COLORS = {
    "o": "#2B1B2E", "s": "#F2C9A0", "h": "#2A2A3A", "a": "#B8C2CC", "b": "#3D6FD6",
    "y": "#F5D547", "p": "#F29AC0", "w": "#F2F2F2", "g": "#6CC24A", "r": "#D63A3A",
    "m": "#8A5CC9", "k": "#7A4E2D", "e": "#FFE45C",
}
KNIGHT = [
    "....oooo....",
    "...ohhhho...",
    "..ohhhhhho..",
    "..ohssssho..",
    "..osossoso..",
    "..ossssss...",
    ".obaaaaaabo.",
    "obbaaaaaabbo",
    "obaaoaaoaabo",
    ".oaaaaaaaao.",
    "..oaao.oaao.",
    "..ooo..ooo..",
]
ARCHER = [
    "...oooooo...",
    "..oyyyyyyo..",
    ".oyyyyyyyyo.",
    ".oyssssssyo.",
    ".oysossosyoy",
    "..ossssss.oy",
    "..oppwwppo.y",
    ".opppwwpppo.",
    ".oppwwwwppo.",
    "..owwwwwwo..",
    "..osso.osso.",
    "..ooo..ooo..",
]
CLERIC = [
    "...eeeeee...",
    "..owwwwwwo..",
    ".owwwwwwwwo.",
    ".owssssssyo.",
    ".owsossosyo.",
    "..ossssss...",
    "..owwyywwo..",
    ".owwwyywwwo.",
    ".owwyyyywwo.",
    ".owwwwwwwwo.",
    "..oko..oko..",
    "..ooo..ooo..",
]
MAGE = [
    ".....oo.....",
    "....ommo....",
    "...ommmmo...",
    "..ommmmmmo..",
    ".ommmmmmmmo.",
    "..owsssswo..",
    "..wsossosw..",
    "..wssssssw.b",
    "..ommmmmmo.k",
    ".ommmmmmmmok",
    "..oko..okok.",
    "..ooo..ooo..",
]
SLIME = [
    "............",
    "............",
    "............",
    "............",
    "....oooo....",
    "...oggggo...",
    "..oggwgggo..",
    ".ogggggggo..",
    ".ogogggogo..",
    ".oggggggggo.",
    ".oggggggggo.",
    "..oooooooo..",
]


def draw_sprite(canv, sprite, x, y, px):
    for row, line in enumerate(sprite):
        for col, ch in enumerate(line):
            if ch == ".":
                continue
            canv.setFillColor(colors.HexColor(PIX_COLORS[ch]))
            canv.rect(x + col * px, y + (len(sprite) - 1 - row) * px, px, px, stroke=0, fill=1)


def draw_cover(canv, doc):
    canv.saveState()
    # Night sky gradient made of pixel bands
    bands = ["#141024", "#1A1530", "#221B3D", "#2C2149", "#3A2752", "#4B2E57"]
    band_h = PAGE_H / len(bands)
    for i, c in enumerate(bands):
        canv.setFillColor(colors.HexColor(c))
        canv.rect(0, PAGE_H - (i + 1) * band_h, PAGE_W, band_h + 1, stroke=0, fill=1)
    # Pixel stars
    import random
    rnd = random.Random(7)
    for _ in range(90):
        sx, sy = rnd.uniform(0, PAGE_W), rnd.uniform(PAGE_H * 0.35, PAGE_H)
        canv.setFillColor(colors.HexColor(rnd.choice(["#F2E6C9", "#FFE45C", "#7FD8FF"])))
        s = rnd.choice([1.5, 1.5, 2.5])
        canv.rect(sx, sy, s, s, stroke=0, fill=1)
    # Distant castle silhouette
    canv.setFillColor(colors.HexColor("#1A1326"))
    base = PAGE_H * 0.30
    for bx, bw, bh in [(330, 40, 120), (370, 30, 90), (400, 50, 150), (450, 26, 100),
                       (476, 40, 70), (300, 30, 60)]:
        canv.rect(bx, base, bw, bh, stroke=0, fill=1)
        for k in range(0, int(bw), 8):
            canv.rect(bx + k, base + bh, 5, 6, stroke=0, fill=1)
    # Hills / ground
    canv.setFillColor(colors.HexColor("#2E3B2A"))
    canv.rect(0, 0, PAGE_W, base + 4, stroke=0, fill=1)
    canv.setFillColor(colors.HexColor("#3F5236"))
    canv.rect(0, base - 2, PAGE_W, 6, stroke=0, fill=1)
    canv.setFillColor(colors.HexColor("#5C4033"))
    canv.rect(0, base - 40, PAGE_W, 16, stroke=0, fill=1)
    # Party marching on the "strip"
    px = 5
    ground = base - 24
    x0 = 70
    for spr in [ARCHER, MAGE, CLERIC, KNIGHT]:
        draw_sprite(canv, spr, x0, ground, px)
        x0 += 13 * px + 8
    for k in range(3):
        draw_sprite(canv, SLIME, 400 + k * 52, ground, px - 1)
    # Damage numbers
    canv.setFont("Sans-Bold", 14)
    canv.setFillColor(colors.HexColor("#FFE45C"))
    canv.drawString(420, ground + 75, "1,337!")
    canv.setFont("Sans-Bold", 10)
    canv.setFillColor(colors.white)
    canv.drawString(470, ground + 60, "248")
    # Title plaque
    plaque_w, plaque_h = PAGE_W - 120, 150
    px0, py0 = 60, PAGE_H - 330
    canv.setFillColor(C_FRAME)
    canv.rect(px0, py0, plaque_w, plaque_h, stroke=0, fill=1)
    canv.setStrokeColor(C_GOLD)
    canv.setLineWidth(3)
    canv.rect(px0 + 5, py0 + 5, plaque_w - 10, plaque_h - 10, stroke=1, fill=0)
    canv.setFillColor(C_GOLD)
    for cx, cy in [(px0 + 10, py0 + 10), (px0 + plaque_w - 16, py0 + 10),
                   (px0 + 10, py0 + plaque_h - 16), (px0 + plaque_w - 16, py0 + plaque_h - 16)]:
        canv.rect(cx, cy, 6, 6, stroke=0, fill=1)
    canv.setFillColor(C_ORANGE)
    canv.setFont("Sans-Bold", 40)
    canv.drawCentredString(PAGE_W / 2, py0 + 88, "IDLE PARTY")
    canv.setFillColor(C_CREAM)
    canv.setFont("Sans-Bold", 18)
    canv.drawCentredString(PAGE_W / 2, py0 + 58, "Desktop Legends")
    canv.setFont("Sans", 9.5)
    canv.drawCentredString(PAGE_W / 2, py0 + 30, SUBTITLE)
    # Info block
    canv.setFillColor(C_CREAM)
    canv.setFont("Sans", 10)
    lines = [
        "Masaüstü widget tarzı idle / auto-battler pixel RPG  -  PC (Steam)",
        "Motor: Godot 4.3+  -  Hedef çıkış: 9-12 ay",
        VERSION,
    ]
    for i, ln in enumerate(lines):
        canv.drawCentredString(PAGE_W / 2, PAGE_H - 380 - i * 16, ln)
    canv.setFont("Sans", 7.5)
    canv.setFillColor(colors.HexColor("#C9BBA5"))
    canv.drawCentredString(PAGE_W / 2, 20, "\"IDLE PARTY\" çalışma adıdır. Bu doküman yapay zeka ajanları tarafından "
                                           "uygulanmak üzere hazırlanmıştır.")
    canv.restoreState()


def make_table(rows):
    header, body = rows[0], rows[1:]
    ncol = len(header)
    for r in body:
        while len(r) < ncol:
            r.append("")
    # Column widths proportional to content length (clamped)
    lens = []
    for c in range(ncol):
        m = max(len(r[c]) for r in rows)
        avg = sum(len(r[c]) for r in rows) / len(rows)
        lens.append(max(4, min(60, (m + 2 * avg) / 3)))
    total = sum(lens)
    widths = [CONTENT_W * l / total for l in lens]
    min_w = 44
    for i, w in enumerate(widths):
        if w < min_w:
            widths[i] = min_w
    scale = CONTENT_W / sum(widths)
    widths = [w * scale for w in widths]
    data = [[Paragraph(inline(h), S["cellh"]) for h in header]]
    data += [[Paragraph(inline(c), S["cell"]) for c in r[:ncol]] for r in body]
    t = Table(data, colWidths=widths, repeatRows=1, hAlign="LEFT")
    style = [
        ("BACKGROUND", (0, 0), (-1, 0), C_FRAME),
        ("LINEBELOW", (0, 0), (-1, 0), 1.2, C_GOLD),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("GRID", (0, 0), (-1, -1), 0.3, colors.HexColor("#D8CCB8")),
        ("TOPPADDING", (0, 0), (-1, -1), 3),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
        ("LEFTPADDING", (0, 0), (-1, -1), 4),
        ("RIGHTPADDING", (0, 0), (-1, -1), 4),
    ]
    for i in range(1, len(data)):
        if i % 2 == 0:
            style.append(("BACKGROUND", (0, i), (-1, i), C_ROW))
    t.setStyle(TableStyle(style))
    return t


def boxed(flowable, bg, border):
    t = Table([[flowable]], colWidths=[CONTENT_W])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), bg),
        ("LINEBEFORE", (0, 0), (0, -1), 3, border),
        ("TOPPADDING", (0, 0), (-1, -1), 6),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 6),
        ("LEFTPADDING", (0, 0), (-1, -1), 8),
    ]))
    return t


def parse(md: str):
    story = []
    lines = md.split("\n")
    i = 0
    para = []

    def flush():
        if para:
            story.append(Paragraph(inline(" ".join(para)), S["body"]))
            para.clear()

    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        if stripped.startswith("```"):
            flush()
            i += 1
            code = []
            while i < len(lines) and not lines[i].strip().startswith("```"):
                code.append(lines[i])
                i += 1
            i += 1
            pre = Preformatted("\n".join(code), S["code"])
            story.append(Spacer(1, 2))
            story.append(boxed(pre, C_CODE, colors.HexColor("#8A5CC9")))
            story.append(Spacer(1, 6))
            continue
        if stripped == "\\pagebreak":
            flush()
            story.append(PageBreak())
        elif stripped == "---":
            flush()
            story.append(Spacer(1, 8))
        elif stripped.startswith("# "):
            flush()
            p = Paragraph(inline(stripped[2:]), S["h1"])
            p._toc_level = 0
            story.append(p)
        elif stripped.startswith("## "):
            flush()
            p = Paragraph(inline(stripped[3:]), S["h2"])
            p._toc_level = 1
            story.append(CondPageBreak(60))
            story.append(p)
        elif stripped.startswith("### "):
            flush()
            story.append(CondPageBreak(50))
            story.append(Paragraph(inline(stripped[4:]), S["h3"]))
        elif stripped.startswith("|"):
            flush()
            rows = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                cells = [c.strip() for c in lines[i].strip().strip("|").split("|")]
                if not all(re.fullmatch(r":?-{2,}:?", c) for c in cells):
                    rows.append(cells)
                i += 1
            story.append(make_table(rows))
            story.append(Spacer(1, 8))
            continue
        elif stripped.startswith("> "):
            flush()
            note = []
            while i < len(lines) and lines[i].strip().startswith("> "):
                note.append(lines[i].strip()[2:])
                i += 1
            story.append(boxed(Paragraph(inline(" ".join(note)), S["note"]), C_NOTE, C_ORANGE))
            story.append(Spacer(1, 6))
            continue
        elif re.match(r"^\s*- \[ \] ", line):
            flush()
            story.append(Paragraph(inline(stripped[6:]), S["bullet"], bulletText="\u2610"))
        elif re.match(r"^ {2,}- ", line):
            flush()
            story.append(Paragraph(inline(stripped[2:]), S["bullet2"], bulletText="\u25e6"))
        elif stripped.startswith("- "):
            flush()
            story.append(Paragraph(inline(stripped[2:]), S["bullet"], bulletText="\u2022"))
        elif re.match(r"^\d+\. ", stripped):
            flush()
            num, rest = stripped.split(". ", 1)
            story.append(Paragraph(inline(rest), S["bullet"], bulletText=f"{num}."))
        elif stripped == "":
            flush()
        else:
            para.append(stripped)
        i += 1
    flush()
    return story


def main():
    files = sorted(glob.glob(os.path.join(SRC, "*.md")))
    md = "\n\n".join(open(f, encoding="utf-8").read() for f in files)

    header_md = f"# {TITLE}\n\n**{SUBTITLE}**\n\n{VERSION}\n\n"
    with open(OUT_MD, "w", encoding="utf-8") as fh:
        fh.write(header_md + md.replace("\\pagebreak\n", ""))

    doc = GDDDoc(OUT_PDF)
    toc = TableOfContents()
    toc.levelStyles = [S["toc0"], S["toc1"]]
    toc.dotsMinLevel = 0
    story = [NextPageTemplate("body"), PageBreak()]
    story.append(Paragraph("İçindekiler", S["h1"]))
    story.append(toc)
    story.append(PageBreak())
    story.extend(parse(md))
    doc.multiBuild(story)
    print("PDF:", OUT_PDF)
    print("MD :", OUT_MD)


if __name__ == "__main__":
    main()
