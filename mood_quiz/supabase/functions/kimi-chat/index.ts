import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "jsr:@supabase/server@^1";

type Message = { role: "user" | "assistant"; content: string };

const treeHolePrompt =
  "You are the AI Tree Hole inside Haze, a gentle emotional-wellbeing app. " +
  "Reply in the same language as the user. Use 2-4 short, warm sentences. " +
  "First validate the emotion, then offer one gentle CBT-informed reframe or " +
  "one tiny grounding suggestion. Never diagnose or provide medical advice. " +
  "If the user mentions self-harm, suicide, or immediate danger, encourage " +
  "them to contact local emergency services, a crisis line, or a trusted person now.";

function counselingPrompt(name: string) {
  return `You are ${name}, an AI emotional-support companion in Haze. ` +
    "Reply in the same language as the user. Sound calm, attentive, and professional, " +
    "but clearly do not claim to be a licensed human therapist. Ask at most one useful " +
    "follow-up question per reply. Use brief CBT-informed reflection and practical next " +
    "steps. Never diagnose or provide medical advice. If the user mentions self-harm, " +
    "suicide, or immediate danger, encourage them to contact local emergency services, " +
    "a crisis line, or a trusted person now.";
}

export default {
  fetch: withSupabase({ auth: ["publishable"] }, async (request) => {
    if (request.method !== "POST") {
      return Response.json({ error: "Method not allowed" }, { status: 405 });
    }

    try {
      const body = await request.json();
      const mode = body.mode === "counseling" ? "counseling" : "tree_hole";
      const rawMessages = Array.isArray(body.messages) ? body.messages : [];
      const messages: Message[] = rawMessages
        .slice(-20)
        .filter((message: unknown): message is Message => {
          if (!message || typeof message !== "object") return false;
          const item = message as Record<string, unknown>;
          return (item.role === "user" || item.role === "assistant") &&
            typeof item.content === "string" && item.content.trim().length > 0;
        })
        .map((message) => ({
          role: message.role,
          content: message.content.trim().slice(0, 4000),
        }));

      if (!messages.length || messages[messages.length - 1].role !== "user") {
        return Response.json(
          { error: "A user message is required" },
          { status: 400 },
        );
      }

      const apiKey = Deno.env.get("KIMI_API_KEY")?.trim();
      if (!apiKey) {
        return Response.json(
          { error: "AI service is not configured" },
          { status: 503 },
        );
      }

      const therapistName = typeof body.therapistName === "string"
        ? body.therapistName.trim().slice(0, 40)
        : "Haze Guide";
      const systemPrompt = mode === "counseling"
        ? counselingPrompt(therapistName || "Haze Guide")
        : treeHolePrompt;

      // The short Moonshot model is a better fit for this chat: it responds
      // faster and consistently returns the answer in `message.content`.
      // If a custom Kimi model is configured but returns an empty/transient
      // response, retry once with the stable short-chat model.
      const configuredModel = Deno.env.get("KIMI_MODEL")?.trim() ||
        "moonshot-v1-8k";
      const models = configuredModel === "moonshot-v1-8k"
        ? [configuredModel, configuredModel]
        : [configuredModel, "moonshot-v1-8k"];

      for (let attempt = 0; attempt < models.length; attempt++) {
        const model = models[attempt];
        const controller = new AbortController();
        const timeout = setTimeout(
          () => controller.abort(),
          attempt === 0 ? 18000 : 14000,
        );
        try {
          const upstream = await fetch(
            "https://api.moonshot.cn/v1/chat/completions",
            {
              method: "POST",
              signal: controller.signal,
              headers: {
                Authorization: `Bearer ${apiKey}`,
                "Content-Type": "application/json",
              },
              body: JSON.stringify({
                model,
                messages: [
                  { role: "system", content: systemPrompt },
                  ...messages,
                ],
                max_tokens: 512,
                temperature: 0.7,
                ...(model.startsWith("kimi-")
                  ? { thinking: { type: "disabled" } }
                  : {}),
              }),
            },
          );

          if (!upstream.ok) {
            const detail = (await upstream.text()).slice(0, 300);
            console.error("Kimi API error", model, upstream.status, detail);
            if (upstream.status < 500 && upstream.status !== 429) break;
          } else {
            const data = await upstream.json();
            const content = data?.choices?.[0]?.message?.content;
            if (typeof content === "string" && content.trim()) {
              return Response.json({ content: content.trim() });
            }
            console.error(
              "Kimi API returned empty content",
              model,
              data?.choices?.[0]?.finish_reason,
            );
          }
        } catch (error) {
          console.error("Kimi request failed", model, error);
        } finally {
          clearTimeout(timeout);
        }

        if (attempt === 0) {
          await new Promise((resolve) => setTimeout(resolve, 250));
        }
      }

      return Response.json(
        { error: "AI provider is temporarily unavailable" },
        { status: 502 },
      );
    } catch (error) {
      console.error(error);
      return Response.json({ error: "Unexpected server error" }, { status: 500 });
    }
  }),
};
