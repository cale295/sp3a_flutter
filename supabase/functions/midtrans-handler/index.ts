// supabase/functions/midtrans-handler/index.ts
// Midtrans Payment Gateway Handler — SP3A
// Handles two POST actions:
//   A. "create-transaction" → calls Midtrans Snap API, returns redirect_url
//   B. "webhook"            → receives Midtrans notification, updates tagihan to 'lunas'
//
// FIX 1: order_id is now `${tagihan_id}-${timestamp}` to prevent "Duplicate Order ID" errors.
// FIX 2: Webhook splits order_id on '-' to recover the original tagihan_id.
// FIX 3: Supabase client always uses SUPABASE_SERVICE_ROLE_KEY to bypass RLS.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
// Note: `Deno.serve` is built-in since Deno 1.35 — no import needed.

// ── Secrets (injected via `supabase secrets set` — NEVER hardcoded) ────────────
const MIDTRANS_SERVER_KEY = Deno.env.get("MIDTRANS_SERVER_KEY") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const MIDTRANS_SNAP_URL = "https://app.sandbox.midtrans.com/snap/v1/transactions";

// ── CORS Headers ───────────────────────────────────────────────────────────────
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// ── Helpers ────────────────────────────────────────────────────────────────────
function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function errorResponse(message: string, status = 400): Response {
  console.error(`[error] HTTP ${status}: ${message}`);
  return jsonResponse({ error: message }, status);
}

// ── Helper: Create a Supabase admin client (Service Role Key — bypasses RLS) ──
function createAdminClient() {
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    throw new Error(
      "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY is not configured. " +
      "Run: supabase secrets set SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=..."
    );
  }
  return createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: {
      // Edge Functions are stateless — never persist sessions or auto-refresh tokens.
      autoRefreshToken: false,
      persistSession: false,
    },
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// ROUTE A: create-transaction
// ══════════════════════════════════════════════════════════════════════════════
async function handleCreateTransaction(
  body: Record<string, unknown>
): Promise<Response> {
  const { tagihan_id, tagihan_ids, jumlah_bayar, pelanggan_name } = body;

  // Resolve array of tagihan IDs
  let resolvedTagihanIds: number[] = [];
  if (Array.isArray(tagihan_ids)) {
    resolvedTagihanIds = tagihan_ids.map(Number);
  } else if (tagihan_id) {
    resolvedTagihanIds = [Number(tagihan_id)];
  }

  console.log(
    `[create-transaction] ▶ Received request — ` +
    `tagihan_ids=${JSON.stringify(resolvedTagihanIds)}, jumlah_bayar=${jumlah_bayar}, pelanggan_name=${pelanggan_name}`
  );

  // ── Validate inputs ────────────────────────────────────────────────────────
  if (resolvedTagihanIds.length === 0 || !jumlah_bayar || !pelanggan_name) {
    return errorResponse(
      "Missing required fields: tagihan_ids/tagihan_id, jumlah_bayar, pelanggan_name"
    );
  }
  if (typeof jumlah_bayar !== "number" || jumlah_bayar <= 0) {
    return errorResponse("jumlah_bayar must be a positive number");
  }
  if (!MIDTRANS_SERVER_KEY) {
    return errorResponse("MIDTRANS_SERVER_KEY is not configured on the server", 500);
  }

  // Generate unique order ID. For bulk checkout, prefix with BULK
  const orderId = resolvedTagihanIds.length > 1
    ? `BULK-${Date.now()}`
    : `${resolvedTagihanIds[0]}-${Date.now()}`;

  console.log(
    `[create-transaction] ✔ Generated unique order_id="${orderId}" ` +
    `for tagihan_ids=${JSON.stringify(resolvedTagihanIds)}`
  );

  // ── Build Midtrans Snap payload ────────────────────────────────────────────
  const grossAmount = Math.round(jumlah_bayar as number); // Must be integer IDR
  const snapPayload = {
    transaction_details: {
      order_id: orderId,
      gross_amount: grossAmount,
    },
    customer_details: {
      first_name: String(pelanggan_name),
    },
    // Stringify array of tagihan IDs into custom_field1
    custom_field1: JSON.stringify(resolvedTagihanIds),
    // Restrict payment methods to QRIS and Bank Transfer ONLY
    enabled_payments: ["other_qris", "bank_transfer"],
  };

  console.log(
    `[create-transaction] ▶ Sending to Midtrans Snap API — ` +
    `order_id="${orderId}", gross_amount=${grossAmount}`
  );

  // ── Call Midtrans ──────────────────────────────────────────────────────────
  const authToken = btoa(`${MIDTRANS_SERVER_KEY}:`);

  let midtransResponse: Response;
  try {
    midtransResponse = await fetch(MIDTRANS_SNAP_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        Authorization: `Basic ${authToken}`,
      },
      body: JSON.stringify(snapPayload),
    });
  } catch (networkError) {
    console.error("[create-transaction] ✖ Network error reaching Midtrans:", networkError);
    return errorResponse("Failed to reach Midtrans API. Please try again.", 502);
  }

  const midtransData = await midtransResponse.json();
  console.log(
    `[create-transaction] Midtrans responded with HTTP ${midtransResponse.status}:`,
    JSON.stringify(midtransData)
  );

  if (!midtransResponse.ok) {
    const midtransMessage =
      (midtransData?.error_messages as string[] | undefined)?.join(", ") ??
      (midtransData?.status_message as string | undefined) ??
      "Unknown Midtrans error";
    return errorResponse(`Midtrans error: ${midtransMessage}`, 502);
  }

  const redirectUrl = midtransData.redirect_url as string | undefined;
  if (!redirectUrl) {
    console.error(
      "[create-transaction] ✖ Midtrans returned no redirect_url. Full response:",
      JSON.stringify(midtransData)
    );
    return errorResponse("Midtrans did not return a redirect_url", 502);
  }

  console.log(`[create-transaction] ✔ Success — redirect_url=${redirectUrl}`);
  return jsonResponse({ redirect_url: redirectUrl });
}

// ══════════════════════════════════════════════════════════════════════════════
// ROUTE B: webhook (Midtrans payment notification)
// ══════════════════════════════════════════════════════════════════════════════
async function handleWebhook(
  body: Record<string, unknown>
): Promise<Response> {
  // ── Step 1: Log the raw payload exactly as Midtrans sent it ───────────────
  console.log("=".repeat(60));
  console.log("[webhook] ▶ RAW PAYLOAD RECEIVED:");
  console.log(JSON.stringify(body, null, 2));
  console.log("=".repeat(60));

  const {
    order_id,
    transaction_status,
    fraud_status,
    status_code,
    gross_amount,
    signature_key,
  } = body;

  console.log(
    `[webhook] ▶ Parsed fields — ` +
    `order_id="${order_id}", transaction_status="${transaction_status}", ` +
    `fraud_status="${fraud_status}", status_code="${status_code}", ` +
    `gross_amount="${gross_amount}"`
  );

  // ── Step 2: Validate required fields ──────────────────────────────────────
  if (!order_id || !transaction_status) {
    return errorResponse(
      "Invalid webhook payload: missing order_id or transaction_status"
    );
  }

  // ── Step 3: Signature verification ────────────────────────────────────────
  // Formula: SHA512(order_id + status_code + gross_amount + server_key)
  if (signature_key && MIDTRANS_SERVER_KEY) {
    console.log(`[webhook] ▶ Verifying signature for order_id="${order_id}"...`);

    const dataToHash = `${order_id}${status_code}${gross_amount}${MIDTRANS_SERVER_KEY}`;
    const encoder = new TextEncoder();
    const hashBuffer = await crypto.subtle.digest(
      "SHA-512",
      encoder.encode(dataToHash)
    );
    const expectedSignature = Array.from(new Uint8Array(hashBuffer))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");

    if (signature_key !== expectedSignature) {
      console.error(
        `[webhook] ✖ SIGNATURE MISMATCH for order_id="${order_id}".` +
        ` Received="${signature_key}", Expected="${expectedSignature}". ` +
        `Rejecting as potential spoofed request.`
      );
      return errorResponse("Invalid signature", 403);
    }
    console.log(`[webhook] ✔ Signature verified successfully.`);
  } else {
    console.warn(
      "[webhook] ⚠ No signature_key in payload or MIDTRANS_SERVER_KEY not set. " +
      "Skipping signature verification (acceptable in Sandbox mode)."
    );
  }

  // ── Step 4: Determine if this is a successful payment ─────────────────────
  // "settlement" = final confirmed payment (Bank Transfer, QRIS)
  // "capture"    = credit card captured (only valid if not flagged as fraud)
  const isSuccess =
    transaction_status === "settlement" ||
    (transaction_status === "capture" && fraud_status === "accept");

  console.log(
    `[webhook] ▶ Payment success check — ` +
    `transaction_status="${transaction_status}", fraud_status="${fraud_status}", ` +
    `isSuccess=${isSuccess}`
  );

  if (!isSuccess) {
    console.log(
      `[webhook] ℹ Transaction is NOT successful (status="${transaction_status}"). ` +
      "No database update needed. Returning 200 to prevent Midtrans retries."
    );
    return jsonResponse({ message: "Notification received. No action taken." });
  }

  // ── Step 5: Clean and Extract tagihan_ids ───────────────────────────────────
  // We check custom_field1 first for stringified tagihan_ids.
  // Fallback to parsing order_id if custom_field1 is missing.
  let tagihanIdsToUpdate: number[] = [];

  if (body.custom_field1) {
    try {
      const parsed = JSON.parse(body.custom_field1 as string);
      if (Array.isArray(parsed)) {
        tagihanIdsToUpdate = parsed.map(Number);
      } else if (!isNaN(Number(parsed))) {
        tagihanIdsToUpdate = [Number(parsed)];
      }
    } catch (parseError) {
      console.warn("[webhook] Failed to parse custom_field1:", parseError);
    }
  }

  const orderIdStr = String(order_id);
  if (tagihanIdsToUpdate.length === 0) {
    const lastDashIndex = orderIdStr.lastIndexOf("-");
    const cleanTagihanIdStr = lastDashIndex !== -1 ? orderIdStr.substring(0, lastDashIndex) : orderIdStr;
    const fallbackId = Number(cleanTagihanIdStr);
    if (!isNaN(fallbackId) && fallbackId > 0) {
      tagihanIdsToUpdate = [fallbackId];
    }
  }

  if (tagihanIdsToUpdate.length === 0) {
    console.error(`[webhook] ✖ FAILED to parse any tagihan_ids from order_id="${orderIdStr}" or custom_field1`);
    return errorResponse(`Cannot extract valid tagihan_ids from webhook payload`, 400);
  }

  console.log(`[webhook] ✔ Resolved tagihanIds to update: ${JSON.stringify(tagihanIdsToUpdate)}`);

  // ── Step 6: Create Supabase admin client with Service Role Key ─────────────
  let supabase;
  try {
    supabase = createAdminClient();
    console.log(`[webhook] ✔ Supabase admin client created successfully.`);
  } catch (clientError) {
    console.error("[webhook] ✖ Failed to create Supabase client:", clientError);
    return errorResponse(String(clientError), 500);
  }

  // ── Step 7: Update each tagihan and insert pembayaran record ───────────────
  const dbErrors: string[] = [];
  const processedIds: number[] = [];

  for (const tid of tagihanIdsToUpdate) {
    console.log(`[webhook] ▶ Processing tagihan_id=${tid}...`);

    const { data: updateData, error: updateError } = await supabase
      .from("tagihan")
      .update({ status_tagihan: "lunas" })
      .eq("id", tid)
      .select();

    if (updateError) {
      console.error(`[webhook] ✖ DATABASE UPDATE FAILED for tagihan id=${tid}:`, updateError);
      dbErrors.push(`update tagihan ${tid} failed: ${updateError.message}`);
      continue;
    }

    if (!updateData || updateData.length === 0) {
      console.error(`[webhook] ✖ NO ROWS UPDATED for tagihan id=${tid}`);
      dbErrors.push(`tagihan ${tid} not found`);
      continue;
    }

    processedIds.push(tid);
    console.log(`[webhook] ✔ Updated status_tagihan='lunas' for tagihan id=${tid}`);

    // Generate custom pembayaran ID
    const random3Digits = Math.floor(100 + Math.random() * 900);
    const customPembayaranId = `SP3A-${tid}-${random3Digits}`;

    const billRecord = updateData[0];
    const billTotalAmount = (billRecord.total_tagihan as number) + (billRecord.total_denda as number);

    const paymentType = (body.payment_type as string) || "other";
    const waktuBayar = (body.transaction_time as string) || new Date().toISOString();

    const pembayaranPayload = {
      id: customPembayaranId,
      tagihan_id: tid,
      jumlah_bayar: billTotalAmount,
      metode_pembayaran: paymentType,
      status_pembayaran: "sukses",
      waktu_bayar: waktuBayar,
    };

    console.log(`[webhook] ▶ Inserting pembayaran for tagihan id=${tid}: custom_id="${customPembayaranId}"`);

    const { error: pembayaranError } = await supabase
      .from("pembayaran")
      .insert(pembayaranPayload);

    if (pembayaranError) {
      console.error(`[webhook] ✖ DATABASE INSERT PEMBAYARAN FAILED for tagihan id=${tid}:`, pembayaranError);
      dbErrors.push(`pembayaran insert for tagihan ${tid} failed: ${pembayaranError.message}`);
    } else {
      console.log(`[webhook] ✔ Inserted pembayaran record for tagihan id=${tid}`);
    }
  }

  if (dbErrors.length > 0 && processedIds.length === 0) {
    return errorResponse(`Database operations failed: ${dbErrors.join("; ")}`, 500);
  }

  console.log(`[webhook] ✔✔ Webhook processing completed. Processed: ${JSON.stringify(processedIds)}, Errors: ${JSON.stringify(dbErrors)}`);

  return jsonResponse({
    message: `Payment confirmed. Processed tagihan_ids: ${processedIds.join(", ")}.`,
    processed_ids: processedIds,
    errors: dbErrors.length > 0 ? dbErrors : undefined,
  });
}

// ══════════════════════════════════════════════════════════════════════════════
// MAIN ROUTER
// ══════════════════════════════════════════════════════════════════════════════
Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return errorResponse("Method not allowed. Use POST.", 405);
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return errorResponse("Invalid or empty JSON body");
  }

  const action = body.action as string | undefined;

  // Auto-detect raw Midtrans webhook POSTs.
  // Midtrans does NOT send an 'action' field — but it always sends 'transaction_status'.
  if (!action && body.transaction_status) {
    console.log(
      "[router] Detected raw Midtrans webhook (no 'action' field, has 'transaction_status'). " +
      "Routing to handleWebhook."
    );
    return await handleWebhook(body);
  }

  switch (action) {
    case "create-transaction":
      return await handleCreateTransaction(body);
    case "webhook":
      return await handleWebhook(body);
    default:
      return errorResponse(
        `Unknown action "${action ?? "(none)"}". ` +
        "Valid values: create-transaction, webhook"
      );
  }
});
