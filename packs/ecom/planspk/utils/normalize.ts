export function mergeScenarioArrays(input: { arrays: any[][] }) {
  const arrays = input.arrays || [];
  const merged: any[] = [];
  for (const arr of arrays) {
    if (Array.isArray(arr)) {
      for (const item of arr) {
        if (item) merged.push(item);
      }
    }
  }
  return { result: merged };
}
