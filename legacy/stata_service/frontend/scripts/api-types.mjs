import { execFile } from "node:child_process";
import fs from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { promisify } from "node:util";

const execFileAsync = promisify(execFile);

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const frontendDir = path.resolve(__dirname, "..");
const repoRoot = path.resolve(frontendDir, "..");

const specPath = path.resolve(repoRoot, "contracts", "openapi.yaml");
const outPath = path.resolve(frontendDir, "src", "api", "__generated__", "types.ts");

const binName = process.platform === "win32" ? "openapi-typescript.cmd" : "openapi-typescript";
const binPath = path.resolve(frontendDir, "node_modules", ".bin", binName);

const shouldWrite = process.argv.includes("--write");

async function runOpenapiTypescript({ check }) {
  const exec = process.platform === "win32" ? "cmd.exe" : binPath;
  const baseArgs =
    process.platform === "win32"
      ? ["/c", binPath, specPath, "--output", outPath]
      : [specPath, "--output", outPath];
  const args = check ? [...baseArgs, "--check"] : baseArgs;
  await execFileAsync(exec, args, {
    cwd: frontendDir,
    maxBuffer: 1024 * 1024 * 50,
  });
}

async function main() {
  if (shouldWrite) {
    await runOpenapiTypescript({ check: false });
    console.log(`[api-types] wrote: ${path.relative(frontendDir, outPath)}`);
    return;
  }

  try {
    await runOpenapiTypescript({ check: true });
  } catch (err) {
    try {
      await fs.access(outPath);
    } catch {
      console.error(`[api-types] missing: ${path.relative(frontendDir, outPath)}`);
      console.error("[api-types] run: npm run generate:api-types");
      process.exit(1);
    }

    console.error("[api-types] out of date: generated output differs from committed file");
    console.error("[api-types] run: npm run generate:api-types");
    if (err?.stdout) console.error(String(err.stdout).trim());
    if (err?.stderr) console.error(String(err.stderr).trim());
    process.exit(1);
  }

  console.log("[api-types] OK: up-to-date");
}

main().catch((err) => {
  console.error("[api-types] failed:", err?.message || String(err));
  process.exit(1);
});
