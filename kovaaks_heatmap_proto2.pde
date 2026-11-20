AimHeatmap heatmap;

void setup() {
  size(900, 620);
  smooth(8);
  textFont(createFont("SansSerif", 12));

  ArrayList<SessionEntry> sessions = createMockData();
  heatmap = new AimHeatmap(sessions, 120, 140, width - 240, height - 230);
}

void draw() {
  background(16, 18, 24);

  fill(240, 244, 248);
  textAlign(LEFT, TOP);
  textSize(22);
  text("KOVAAK'S AIM TRAINING // CONSISTENCY & PB MATRIX", 60, 40);

  fill(140, 150, 165);
  textSize(13);
  text("Ring diameter & glow = Minutes Played   |   Gold Crosshair = Personal Best (PB)   |   Hover any target for details", 60, 72);

  heatmap.display();
}

// ============================================================================
// CLASS 1: Data Model for a single CSV row
// ============================================================================
class SessionEntry {
  String dateStr;
  String dayOfWeek;
  float minutesPlayed;
  boolean hitPB;
  int year;
  int month;
  int dayOfMonth;
  int dayIndex;   // 0 = Monday ... 6 = Sunday
  int weekNumber; // Week index for vertical stacking

  SessionEntry(String dateStr, String dayOfWeek, float minutesPlayed, boolean hitPB) {
    this.dateStr = dateStr;
    this.dayOfWeek = dayOfWeek;
    this.minutesPlayed = minutesPlayed;
    this.hitPB = hitPB;

    // Split "2026.02.12" using Processing's built-in split()
    String[] parts = split(dateStr, '.');
    this.year = int(parts[0]);
    this.month = int(parts[1]);
    this.dayOfMonth = int(parts[2]);

    // Convert dayOfWeek string into 0..6 index (Monday = 0)
    this.dayIndex = dayOfWeekToIndex(dayOfWeek);

    // Simple week bucket based on day of year (approx) so weeks stack cleanly
    int approxDayOfYear = (this.month - 1) * 30 + this.dayOfMonth;
    this.weekNumber = approxDayOfYear / 7;
  }

  int dayOfWeekToIndex(String dow) {
    String clean = dow.trim().toLowerCase();
    if (clean.equals("monday") || clean.equals("mon")) return 0;
    if (clean.equals("tuesday") || clean.equals("tue")) return 1;
    if (clean.equals("wednesday") || clean.equals("wed")) return 2;
    if (clean.equals("thursday") || clean.equals("thu")) return 3;
    if (clean.equals("friday") || clean.equals("fri")) return 4;
    if (clean.equals("saturday") || clean.equals("sat")) return 5;
    if (clean.equals("sunday") || clean.equals("sun")) return 6;
    return 0;
  }
}

// ============================================================================
// CLASS 2: Custom Visual Renderer (The Heatmap / Target Matrix)
// ============================================================================
class AimHeatmap {
  ArrayList<SessionEntry> entries;
  float x, y, w, h;
  float maxMinutes = 1.0;
  int minWeek = 999999;
  int maxWeek = -999999;

  String[] dayLabels = {"MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"};

  AimHeatmap(ArrayList<SessionEntry> entries, float x, float y, float w, float h) {
    this.entries = entries;
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;

    for (SessionEntry e : entries) {
      if (e.minutesPlayed > maxMinutes) maxMinutes = e.minutesPlayed;
      if (e.weekNumber < minWeek) minWeek = e.weekNumber;
      if (e.weekNumber > maxWeek) maxWeek = e.weekNumber;
    }
  }

  void display() {
    int totalWeeks = max(1, (maxWeek - minWeek) + 1);
    float colWidth = w / 7.0;
    float rowHeight = h / totalWeeks;

    textAlign(CENTER, CENTER);
    textSize(12);
    for (int col = 0; col < 7; col++) {
      float cx = x + col * colWidth + colWidth * 0.5;
      fill(130, 140, 158);
      text(dayLabels[col], cx, y - 25);

      stroke(32, 36, 46);
      strokeWeight(1);
      line(cx, y - 10, cx, y + h);
    }

    textAlign(RIGHT, CENTER);
    for (int row = 0; row < totalWeeks; row++) {
      float cy = y + row * rowHeight + rowHeight * 0.5;
      fill(100, 110, 128);
      text("WK " + (row + 1), x - 20, cy);
    }

    SessionEntry hoveredEntry = null;
    float hoverX = 0, hoverY = 0;

    for (SessionEntry e : entries) {
      int row = e.weekNumber - minWeek;
      float cx = x + e.dayIndex * colWidth + colWidth * 0.5;
      float cy = y + row * rowHeight + rowHeight * 0.5;

      float norm = constrain(e.minutesPlayed / maxMinutes, 0, 1);
      float maxRadius = min(colWidth, rowHeight) * 0.38;
      float r = lerp(10, maxRadius, norm);

      boolean isHovered = dist(mouseX, mouseY, cx, cy) < max(r, 16);
      if (isHovered) {
        hoveredEntry = e;
        hoverX = cx;
        hoverY = cy;
      }

      drawTargetGlyph(cx, cy, r, norm, e.hitPB, isHovered);
    }

    drawLegend();
    if (hoveredEntry != null) {
      drawTooltip(hoveredEntry, hoverX, hoverY);
    }
  }

  void drawTargetGlyph(float cx, float cy, float r, float intensity, boolean hitPB, boolean isHovered) {
    noStroke();
    color baseCol = hitPB ? color(255, 190, 55) : color(56, 189, 248);

    fill(baseCol, isHovered ? 65 : lerp(15, 45, intensity));
    ellipse(cx, cy, r * 2.5, r * 2.5);

    noFill();
    stroke(baseCol, isHovered ? 255 : lerp(110, 230, intensity));
    strokeWeight(isHovered ? 2.2 : 1.5);
    ellipse(cx, cy, r * 2.0, r * 2.0);

    stroke(baseCol, lerp(80, 180, intensity));
    strokeWeight(1);
    ellipse(cx, cy, r * 1.1, r * 1.1);

    noStroke();
    fill(baseCol, 240);
    ellipse(cx, cy, 4.5, 4.5);

    if (hitPB) {
      stroke(255, 220, 110, 230);
      strokeWeight(1.5);
      float tick = r + 5;
      line(cx - tick, cy, cx - r * 0.55, cy);
      line(cx + r * 0.55, cy, cx + tick, cy);
      line(cx, cy - tick, cx, cy - r * 0.55);
      line(cx, cy + r * 0.55, cx, cy + tick);
    }
  }

  void drawLegend() {
    float ly = height - 45;
    noStroke();
    fill(56, 189, 248);
    ellipse(65, ly, 10, 10);
    fill(170, 180, 195);
    textAlign(LEFT, CENTER);
    textSize(12);
    text("Standard Session", 80, ly);

    fill(255, 190, 55);
    ellipse(225, ly, 10, 10);
    fill(170, 180, 195);
    text("Personal Best Achieved (Hit_PB = True)", 240, ly);
  }

  void drawTooltip(SessionEntry e, float tx, float ty) {
    float boxW = 185;
    float boxH = 74;
    float bx = constrain(tx + 18, 20, width - boxW - 20);
    float by = constrain(ty - boxH * 0.5, 20, height - boxH - 20);

    fill(26, 30, 40, 245);
    stroke(e.hitPB ? color(255, 190, 55) : color(56, 189, 248));
    strokeWeight(1.2);
    rect(bx, by, boxW, boxH, 6);

    textAlign(LEFT, TOP);
    fill(245);
    textSize(12);
    text(e.dateStr + " (" + e.dayOfWeek.substring(0, 3) + ")", bx + 12, by + 10);

    fill(180, 190, 205);
    text("Played: " + nf(e.minutesPlayed, 0, 1) + " mins", bx + 12, by + 30);

    fill(e.hitPB ? color(255, 195, 70) : color(130, 140, 155));
    text(e.hitPB ? "★ NEW PERSONAL BEST" : "No PB this session", bx + 12, by + 48);
  }
}

// ============================================================================
// HELPER: Mock Data Generator
// ============================================================================
ArrayList<SessionEntry> createMockData() {
  ArrayList<SessionEntry> list = new ArrayList<SessionEntry>();
  list.add(new SessionEntry("2026.02.09", "Monday",    35.0, false));
  list.add(new SessionEntry("2026.02.10", "Tuesday",   50.0, true));
  list.add(new SessionEntry("2026.02.12", "Thursday",  20.0, true));
  list.add(new SessionEntry("2026.02.13", "Friday",     4.0, false));
  list.add(new SessionEntry("2026.02.14", "Saturday",  65.0, true));
  list.add(new SessionEntry("2026.02.15", "Sunday",    45.0, false));

  list.add(new SessionEntry("2026.02.16", "Monday",    15.0, false));
  list.add(new SessionEntry("2026.02.18", "Wednesday", 55.0, true));
  list.add(new SessionEntry("2026.02.19", "Thursday",  30.0, false));
  list.add(new SessionEntry("2026.02.21", "Saturday",  75.0, true));
  list.add(new SessionEntry("2026.02.22", "Sunday",    40.0, false));

  list.add(new SessionEntry("2026.02.23", "Monday",    25.0, false));
  list.add(new SessionEntry("2026.02.24", "Tuesday",   60.0, false));
  list.add(new SessionEntry("2026.02.25", "Wednesday", 45.0, true));
  list.add(new SessionEntry("2026.02.27", "Friday",    10.0, false));
  list.add(new SessionEntry("2026.02.28", "Saturday",  80.0, true));
  return list;
}
