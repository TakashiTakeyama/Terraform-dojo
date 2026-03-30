// CloudWatch Synthetics Playwright runtime
//
// Web (browser) canary: ページ読み込みを検証する。
// Secrets Manager からサインイン情報を取得し、ログインフォームの存在を確認する。
//
// Environment variables (injected by Canary run_config):
//   TARGET_URL           - 検証対象のWeb URL
//   WEB_SIGNIN_SECRET_ID - Secrets Manager シークレットの ARN
const { synthetics } = require("@aws/synthetics-playwright");
const {
  GetSecretValueCommand,
  SecretsManagerClient,
} = require("@aws-sdk/client-secrets-manager");

const secretsManagerClient = new SecretsManagerClient({});

const getSigninCredentials = async () => {
  const response = await secretsManagerClient.send(
    new GetSecretValueCommand({
      SecretId: process.env.WEB_SIGNIN_SECRET_ID,
    }),
  );

  if (!response.SecretString) {
    throw new Error("Signin secret string is empty");
  }

  const secret = JSON.parse(response.SecretString);
  if (!secret.email) {
    throw new Error("Signin secret must contain 'email' field");
  }

  return secret;
};

const handler = async () => {
  const browser = await synthetics.launch();
  const context = await browser.newContext({
    viewport: { width: 1280, height: 720 },
  });
  const page = await synthetics.newPage(context);
  const credentials = await getSigninCredentials();

  try {
    await synthetics.executeStep("openPage", async () => {
      const response = await page.goto(process.env.TARGET_URL, {
        waitUntil: "load",
        timeout: 30000,
      });
      if (response && response.status() !== 200) {
        throw new Error(`Unexpected status code: ${response.status()}`);
      }
    });

    await synthetics.executeStep("verifyLoginForm", async () => {
      await page.waitForSelector('input[type="email"]', { timeout: 10000 });

      const emailInput = page.locator('input[type="email"]').first();
      await emailInput.fill(credentials.email);
    });
  } finally {
    await synthetics.close();
  }
};

exports.handler = async () => {
  return await handler();
};
