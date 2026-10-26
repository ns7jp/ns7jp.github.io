const { setTimeout: waitFor } = require("node:timers/promises");

const transientStatuses = new Set([500, 502, 503, 504]);
const maxAttempts = 3;

// Retry only transient HTTP responses; persistent and other failures stay failures.
async function retryTransientResponse(operation, { wait = waitFor, onRetry = () => {} } = {}) {
  for (let attempt = 1; attempt <= maxAttempts; attempt += 1) {
    const result = await operation();
    if (result.ok || !transientStatuses.has(result.status) || attempt === maxAttempts) {
      return result;
    }
    const delayMs = attempt * 1000;
    onRetry({ status: result.status, attempt, maxAttempts, delayMs });
    await wait(delayMs);
  }
}

module.exports = { retryTransientResponse };
