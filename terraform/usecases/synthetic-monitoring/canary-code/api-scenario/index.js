// CloudWatch Synthetics Playwright runtime
//
// API canary: ヘルスチェックエンドポイントの疎通を確認する。
//
// Environment variables (injected by Canary run_config):
//   API_ENDPOINT    - API のベース URL
//   API_HEALTH_PATH - ヘルスチェックパス（デフォルト: /health）
const { synthetics } = require("@aws/synthetics-playwright");

const handler = async () => {
  const browser = await synthetics.launch();
  const context = await browser.newContext();

  const healthPath = process.env.API_HEALTH_PATH || "/health";

  try {
    await synthetics.executeStep("healthCheck", async () => {
      const response = await context.request.get(
        `${process.env.API_ENDPOINT}${healthPath}`,
      );
      if (response.status() !== 200) {
        throw new Error(
          `Health check failed with status: ${response.status()}`,
        );
      }
    });
  } finally {
    await synthetics.close();
  }
};

exports.handler = async () => {
  return await handler();
};
