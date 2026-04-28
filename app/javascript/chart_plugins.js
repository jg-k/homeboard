// Plugin: round only the top of the topmost segment in each stacked bar.
// Chart.js doesn't natively know which segment is on top; this walks each
// stack and emits a per-bar borderRadius array.

const stackedBarRoundedTop = {
  id: "stackedBarRoundedTop",
  beforeUpdate(chart) {
    const datasets = chart.data && chart.data.datasets;
    if (!datasets || datasets.length === 0) return;

    const isStacked = (chart.options.scales?.y?.stacked) || (chart.options.scales?.x?.stacked);
    if (!isStacked) return;

    // For each (stack, dataIndex), find the highest dataset index with a positive value.
    const topIndex = new Map(); // key: `${stack}|${dataIndex}` → datasetIndex

    datasets.forEach((dataset, datasetIndex) => {
      if (dataset.type && dataset.type !== "bar") return;
      const stack = dataset.stack || "default";
      (dataset.data || []).forEach((value, dataIndex) => {
        const numeric = typeof value === "object" && value !== null ? value.y : value;
        if (numeric != null && numeric !== 0) {
          topIndex.set(`${stack}|${dataIndex}`, datasetIndex);
        }
      });
    });

    datasets.forEach((dataset, datasetIndex) => {
      if (dataset.type && dataset.type !== "bar") return;
      const stack = dataset.stack || "default";
      dataset.borderRadius = (dataset.data || []).map((_, dataIndex) => {
        const top = topIndex.get(`${stack}|${dataIndex}`);
        return top === datasetIndex ? { topLeft: 6, topRight: 6 } : 0;
      });
      dataset.borderSkipped = false;
    });
  }
};

if (typeof Chart !== "undefined") {
  Chart.register(stackedBarRoundedTop);
}

export default stackedBarRoundedTop;
