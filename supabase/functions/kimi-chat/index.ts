// Supabase Edge Function: kimi-chat
// AI Tree Hole 的 Kimi(Moonshot) 代理：
//  - Kimi key 只存服务端 secret（前端永不接触）
//  - 服务端→Kimi 是 server-to-server，没有浏览器 CORS 问题
//  - 默认要求调用者带合法的 Supabase JWT（verify_jwt=true），只有登录用户能调
//
// 部署：见仓库根 README / 对话里的步骤。前端用 supabase.functions.invoke('kimi-chat')。

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// 国内站用 api.moonshot.cn；海外站用 api.moonshot.ai。可用 env 覆盖。
const KIMI_URL =
  Deno.env.get("KIMI_URL") ?? "https://api.moonshot.cn/v1/chat/completions";
const KIMI_MODEL = Deno.env.get("KIMI_MODEL") ?? "moonshot-v1-8k";

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const apiKey = Deno.env.get("KIMI_API_KEY");
  if (!apiKey) {
    return json({ error: "KIMI_API_KEY secret is not set" }, 500);
  }

  let messages: unknown;
  try {
    const body = await req.json();
    messages = body.messages;
    if (!Array.isArray(messages)) throw new Error("messages must be an array");
  } catch (_) {
    return json({ error: "Invalid request body" }, 400);
  }

  let resp: Response;
  try {
    resp = await fetch(KIMI_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: KIMI_MODEL,
        messages,
        temperature: 0.6,
      }),
    });
  } catch (e) {
    return json({ error: `Upstream fetch failed: ${e}` }, 502);
  }

  const data = await resp.json().catch(() => null);
  if (!resp.ok) {
    return json({ error: data ?? "Kimi error", status: resp.status }, resp.status);
  }

  const content = data?.choices?.[0]?.message?.content ?? "";
  return json({ content });
});
