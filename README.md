# Lake Hāwea levels

An interactive chart of Lake Hāwea's water level, compared year by year, published with GitHub Pages.

- **Data:** Otago Regional Council AQUARIUS portal: lake level at EM507 (Lake Hawea at Dam, from 1930) and river flow at EM218 (Hawea at Camphill Bridge, from 1968). `scripts/fetch_orc.py` pulls both and stores daily averages in `data/`, then derives a 7-day lake inflow estimate (outflow + change in storage, from 1982) in `data/hawea_inflow_7day.csv`. Checked against the Electricity Authority natural inflow series 1982–2024: weekly r = 0.99, mean absolute difference about 4 m³/s.
- **Automation:** `.github/workflows/update.yml` runs daily, refreshes the current and previous year, commits any new data and redeploys the site. Run it by hand with **backfill** ticked to rebuild the whole record.
- **Site:** `site/index.html`, a single static page using Plotly.

ORC data is provisional and comes with no warranty from ORC or the data providers.

Cost: nothing on a public repository (GitHub Actions and Pages are free).
