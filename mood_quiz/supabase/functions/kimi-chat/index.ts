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

      const upstream = await fetch(
      "https://api.moonshot.cn/v1/chat/completions",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${apiKey}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            model: Deno.env.get("KIMI_MODEL") || "kimi-k2.6",
            messages: [{ role: "system", content: systemPrompt }, ...messages],
            max_tokens: 500,
            temperature: 1,
          }),
        },
      );

      if (!upstream.ok) {
        const detail = (await upstream.text()).slice(0, 300);
        console.error("Kimi API error", upstream.status, detail);
        return Response.json(
          {
            error: "AI provider request failed",
            providerStatus: upstream.status,
          },
          { status: 502 },
        );
      }

      const data = await upstream.json();
      const content = data?.choices?.[0]?.message?.content;
      if (typeof content !== "string" || !content.trim()) {
        return Response.json(
          { error: "AI provider returned no content" },
          { status: 502 },
        );
      }
      return Response.json({ content: content.trim() });
    } catch (error) {
      console.error(error);
      return Response.json({ error: "Unexpected server error" }, { status: 500 });
    }
  }),
};
