// Turns the five guls on the flag of Turkmenistan into charts of knots.
//
// How to run: open
//   https://upload.wikimedia.org/wikipedia/commons/1/1b/Flag_of_Turkmenistan.svg
// in a browser, open the developer console, paste this whole file and press
// Enter. It prints the charts as JSON; save them as tools/guls/flag_guls.json
// (keys gul1..gul5 and border), then run tools/guls/make_gol_charts.py.
//
// The flag is public domain. The rough boxes below are in the flag's own units
// (900 x 600); each box is then fitted tightly around its gul.
(async () => {
  const XH = 'http://www.w3.org/1999/xhtml';
  const S = 6, W = 900, H = 600, COLS = 97;   // knots across a gul
  const img = document.createElementNS(XH, 'img');
  img.src = window.__FLAG_URL || location.href;
  await new Promise((res, rej) => { img.onload = res; img.onerror = () => rej(new Error('image failed')); });
  const cv = document.createElementNS(XH, 'canvas');
  cv.width = W * S; cv.height = H * S;
  const ctx = cv.getContext('2d', { willReadFrequently: true });
  ctx.drawImage(img, 0, 0, W * S, H * S);
  const D = ctx.getImageData(0, 0, W * S, H * S).data, FW = W * S;

  // The flag uses five flat colours.
  const pal = { R: [216, 40, 56], y: [248, 200, 40], g: [8, 136, 56], w: [248, 248, 248], k: [56, 56, 56] };
  const classify = (r, g, b) => {
    let best = 'R', bd = Infinity;
    for (const [k, v] of Object.entries(pal)) {
      const d = (r - v[0]) ** 2 + (g - v[1]) ** 2 + (b - v[2]) ** 2;
      if (d < bd) { bd = d; best = k; }
    }
    return best;
  };
  const pixel = (ux, uy) => {
    const x = Math.min(FW - 1, Math.max(0, Math.round(ux * S)));
    const y = Math.min(H * S - 1, Math.max(0, Math.round(uy * S)));
    const i = (y * FW + x) * 4;
    return classify(D[i], D[i + 1], D[i + 2]);
  };

  // One knot is the most common colour among 5 x 5 samples of its cell.
  const sample = (cx, cy, cell, rows) => {
    const grid = [];
    for (let r = 0; r < rows; r++) {
      const row = [];
      for (let c = 0; c < COLS; c++) {
        const counts = {};
        for (let sy = 0; sy < 5; sy++) for (let sx = 0; sx < 5; sx++) {
          const k = pixel(
            cx - (COLS / 2) * cell + (c + (sx + 0.5) / 5) * cell,
            cy - (rows / 2) * cell + (r + (sy + 0.5) / 5) * cell,
          );
          counts[k] = (counts[k] || 0) + 1;
        }
        row.push(Object.entries(counts).sort((a, b) => b[1] - a[1])[0][0]);
      }
      grid.push(row);
    }
    return grid;
  };

  // Red cells reaching the edge are the carpet around the gul ('.'); red
  // inside is part of the gul ('r'). Yellow bits cut off from the gul belong
  // to the strip's side border and are dropped.
  const clean = (g0) => {
    const g = g0.map(r => r.slice()), R = g.length, C = g[0].length;
    const out = g.map(r => r.map(() => false)), st = [];
    for (let r = 0; r < R; r++) for (let c = 0; c < C; c++) {
      if ((r === 0 || c === 0 || r === R - 1 || c === C - 1) && g[r][c] === 'R') { out[r][c] = true; st.push([r, c]); }
    }
    while (st.length) {
      const [r, c] = st.pop();
      for (const [dr, dc] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
        const a = r + dr, b = c + dc;
        if (a >= 0 && a < R && b >= 0 && b < C && !out[a][b] && g[a][b] === 'R') { out[a][b] = true; st.push([a, b]); }
      }
    }
    for (let r = 0; r < R; r++) for (let c = 0; c < C; c++) if (g[r][c] === 'R') g[r][c] = out[r][c] ? '.' : 'r';
    const seen = g.map(r => r.map(() => false)), comps = [];
    for (let r = 0; r < R; r++) for (let c = 0; c < C; c++) {
      if (g[r][c] === '.' || seen[r][c]) continue;
      const cells = [], s2 = [[r, c]]; seen[r][c] = true;
      while (s2.length) {
        const [a, b] = s2.pop(); cells.push([a, b]);
        for (let da = -1; da <= 1; da++) for (let db = -1; db <= 1; db++) {
          const x = a + da, y = b + db;
          if (x >= 0 && x < R && y >= 0 && y < C && !seen[x][y] && g[x][y] !== '.') { seen[x][y] = true; s2.push([x, y]); }
        }
      }
      comps.push(cells);
    }
    comps.sort((a, b) => b.length - a.length);
    for (const comp of comps.slice(1)) if (comp.every(([a, b]) => g[a][b] === 'y')) for (const [a, b] of comp) g[a][b] = '.';
    return g;
  };

  const bbox = (g) => {
    let r0 = Infinity, r1 = -1, c0 = Infinity, c1 = -1;
    g.forEach((row, r) => row.forEach((k, c) => { if (k !== '.') { r0 = Math.min(r0, r); r1 = Math.max(r1, r); c0 = Math.min(c0, c); c1 = Math.max(c1, c); } }));
    return { r0, r1, c0, c1 };
  };

  // Rough boxes [x0, y0, x1, y1], top to bottom: Teke, Yomut, Arsary, Chowdur, Saryk.
  const guesses = [[124, 4, 254, 96], [121, 116, 257, 210], [119, 230, 259, 324], [121, 340, 257, 426], [128, 452, 250, 540]];
  const result = {};
  guesses.forEach((box, i) => {
    let cx = (box[0] + box[2]) / 2, cy = (box[1] + box[3]) / 2;
    let cell = (box[2] - box[0]) / COLS, rows = Math.round((box[3] - box[1]) / cell);
    if (rows % 2 === 0) rows++;
    for (let pass = 0; pass < 3; pass++) {           // fit the box around the gul
      const b = bbox(clean(sample(cx, cy, cell, rows)));
      const x0 = cx - (COLS / 2) * cell + b.c0 * cell, x1 = cx - (COLS / 2) * cell + (b.c1 + 1) * cell;
      const y0 = cy - (rows / 2) * cell + b.r0 * cell, y1 = cy - (rows / 2) * cell + (b.r1 + 1) * cell;
      cx = (x0 + x1) / 2; cy = (y0 + y1) / 2; cell = (x1 - x0) / COLS;
      rows = Math.round((y1 - y0) / cell); if (rows % 2 === 0) rows++;
    }
    result['gul' + (i + 1)] = clean(sample(cx, cy, cell, rows)).map(r => r.join(''));
  });
  // The strip's side border repeats every 114 units. Take one repeat from the
  // gap between the first two guls, where nothing else is drawn, and chart it
  // with the same knot size as the guls (a gul is 130 units across).
  const cellB = 130 / COLS;
  const bx0 = 108, bw = 12, by0 = 96, period = 114;
  const bCols = Math.round(bw / cellB), bRows = Math.round(period / cellB);
  const border = [];
  for (let r = 0; r < bRows; r++) {
    let row = '';
    for (let c = 0; c < bCols; c++) {
      const counts = {};
      for (let sy = 0; sy < 3; sy++) for (let sx = 0; sx < 3; sx++) {
        const k = pixel(bx0 + (c + (sx + 0.5) / 3) * cellB, by0 + (r + (sy + 0.5) / 3) * cellB);
        counts[k] = (counts[k] || 0) + 1;
      }
      const k = Object.entries(counts).sort((a, b) => b[1] - a[1])[0][0];
      row += k === 'R' ? '.' : k;
    }
    border.push(row);
  }
  result.border = border;
  const text = JSON.stringify(result, null, 2);
  console.log(text);
  // Optional: send it to a local server that saves it (used while developing).
  if (window.__SEND_TO) await fetch(window.__SEND_TO, { method: 'POST', body: text });
  return result;
})();
