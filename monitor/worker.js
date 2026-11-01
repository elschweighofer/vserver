// Runs on a Cloudflare Cron Trigger: checks each URL and sends an ntfy push for
// any that fail. It alerts on every failed run, so a long outage repeats.
const TIMEOUT_MS = 15000;

async function check(url) {
  try {
    const res = await fetch(url, {
      redirect: "manual",
      signal: AbortSignal.timeout(TIMEOUT_MS),
    });
    return res.status < 400 ? null : `${url} returned ${res.status}`;
  } catch (err) {
    return `${url} failed: ${err.message}`;
  }
}

// One retry, so a single dropped request doesn't page anyone.
async function checkWithRetry(url) {
  return (await check(url)) && (await check(url));
}

export async function run(env) {
  const urls = JSON.parse(env.MONITOR_URLS);
  const results = await Promise.all(urls.map(checkWithRetry));
  const failures = results.filter(Boolean);
  if (failures.length === 0) return;

  const alert = await fetch(env.NTFY_URL, {
    method: "POST",
    headers: { Title: "Site down", Priority: "high" },
    body: failures.join("\n"),
  });
  throw new Error(`${failures.join("; ")} (ntfy ${alert.status})`);
}

export default {
  async scheduled(_event, env) {
    await run(env);
  },
};
