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
  const { tagihan_id, jumlah_bayar, pelanggan_name } = body;

  console.log(
    `[create-transaction] ▶ Received request — ` +
    `tagihan_id=${tagihan_id}, jumlah_bayar=${jumlah_bayar}, pelanggan_name=${pelanggan_name}`
  );

  // ── Validate inputs ────────────────────────────────────────────────────────
  if (!tagihan_id || !jumlah_bayar || !pelanggan_name) {
    return errorResponse(
      "Missing required fields: tagihan_id, jumlah_bayar, pelanggan_name"
    );
  }
  if (typeof jumlah_bayar !== "number" || jumlah_bayar <= 0) {
    return errorResponse("jumlah_bayar must be a positive number");
  }
  if (!MIDTRANS_SERVER_KEY) {
    return errorResponse("MIDTRANS_SERVER_KEY is not configured on the server", 500);
  }

  // ── FIX 1: Append timestamp to order_id ───────────────────────────────────
  // Midtrans rejects any order_id that was used before (even cancelled payments).
  // By appending Date.now(), every attempt gets a unique ID.
  // Format: "42-1719559200000"  (tagihan_id + dash + unix ms timestamp)
  const orderId = `${tagihan_id}-${Date.now()}`;

  console.log(
    `[create-transaction] ✔ Generated unique order_id="${orderId}" ` +
    `(tagihan_id=${tagihan_id})`
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
    // Restrict payment methods to QRIS and Bank Transfer ONLY
    enabled_payments: ["other_qris", "bank_transfer"],
  };

  console.log(
    `[create-transaction] ▶ Sending to Midtrans Snap API — ` +
    `order_id="${orderId}", gross_amount=${grossAmount}`
  );

  // ── Call Midtrans ──────────────────────────────────────────────────────────
  // Basic Auth: Base64(ServerKey + ":")
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

  // ── Step 5: Clean and Extract tagihan_id ───────────────────────────────────
  // order_id is formatted as: "${tagihan_id}-${timestamp}" (e.g., "42-1719559200000" or "TG-001-1687001234").
  // We locate the last dash to remove only the appended timestamp.
  const orderIdStr = String(order_id);
  const lastDashIndex = orderIdStr.lastIndexOf("-");
  const cleanTagihanIdStr = lastDashIndex !== -1 ? orderIdStr.substring(0, lastDashIndex) : orderIdStr;

  console.log(
    `[webhook] ▶ Parsing order_id="${orderIdStr}": ` +
    `lastDashIndex=${lastDashIndex}, cleanTagihanIdStr="${cleanTagihanIdStr}"`
  );

  const cleanTagihanId = isNaN(Number(cleanTagihanIdStr))
    ? cleanTagihanIdStr
    : parseInt(cleanTagihanIdStr, 10);

  if (!cleanTagihanIdStr || (typeof cleanTagihanId === "number" && cleanTagihanId <= 0)) {
    console.error(
      `[webhook] ✖ FAILED to parse a valid tagihan_id from order_id="${orderIdStr}". ` +
      `Parsed value="${cleanTagihanIdStr}"`
    );
    return errorResponse(
      `Cannot extract valid tagihan_id from order_id="${orderIdStr}"`,
      400
    );
  }

  console.log(`[webhook] ✔ Extracted cleanTagihanId=${cleanTagihanId} from order_id="${orderIdStr}"`);

  // ── Step 6: Create Supabase admin client with Service Role Key ─────────────
  // The Service Role Key bypasses Row Level Security (RLS) policies.
  let supabase;
  try {
    supabase = createAdminClient();
    console.log(
      `[webhook] ✔ Supabase admin client created successfully ` +
      `(URL="${SUPABASE_URL}", using Service Role Key).`
    );
  } catch (clientError) {
    console.error("[webhook] ✖ Failed to create Supabase client:", clientError);
    return errorResponse(String(clientError), 500);
  }

  // ── Step 7: Update the tagihan record ─────────────────────────────────────
  console.log(
    `[webhook] ▶ Attempting to update tagihan where id=${cleanTagihanId} ` +
    `→ SET status_tagihan='lunas' ...`
  );

  const { data: updateData, error: updateError, count } = await supabase
    .from("tagihan")
    .update({ status_tagihan: "lunas" })
    .eq("id", cleanTagihanId)
    .select();

  // ── Step 8: Log the full DB result for debugging ──────────────────────────
  console.log("[webhook] ▶ Supabase update result:");
  console.log(`  → error  : ${updateError ? JSON.stringify(updateError) : "null (no error)"}`);
  console.log(`  → data   : ${JSON.stringify(updateData)}`);
  console.log(`  → count  : ${count}`);

  if (updateError) {
    console.error(
      `[webhook] ✖ DATABASE UPDATE FAILED for tagihan id=${cleanTagihanId}. ` +
      `Error code="${updateError.code}", message="${updateError.message}", ` +
      `details="${updateError.details}", hint="${updateError.hint}"`
    );
    return errorResponse(`DB update failed: ${updateError.message}`, 500);
  }

  if (!updateData || updateData.length === 0) {
    console.error(
      `[webhook] ✖ NO ROWS UPDATED — tagihan with id=${cleanTagihanId} was not found ` +
      `in the database. Check that the tagihan_id is correct and the record exists.`
    );
    return errorResponse(
      `No tagihan record found with id=${cleanTagihanId}`,
      404
    );
  }

  console.log(
    `[webhook] ✔✔ SUCCESS — tagihan id=${cleanTagihanId} updated to status_tagihan='lunas'. ` +
    `Updated row: ${JSON.stringify(updateData[0])}`
  );

  // ── Step 9: Insert record into pembayaran table ───────────────────────────
  // Generate a custom pembayaran ID: SP3A-[Clean_Tagihan_ID]-[Random_3_Digits]
  const random3Digits = Math.floor(100 + Math.random() * 900);
  const customPembayaranId = `SP3A-${cleanTagihanIdStr}-${random3Digits}`;

  const grossAmountVal = typeof gross_amount === "number"
    ? gross_amount
    : parseFloat(String(gross_amount || 0));
  const paymentType = (body.payment_type as string) || "other";
  const waktuBayar = (body.transaction_time as string) || new Date().toISOString();

  const pembayaranPayload = {
    id: customPembayaranId,
    tagihan_id: cleanTagihanId,
    jumlah_bayar: grossAmountVal,
    metode_pembayaran: paymentType,
    status_pembayaran: "sukses",
    waktu_bayar: waktuBayar,
  };

  console.log('Cleaned Tagihan ID:', cleanTagihanId);
  console.log(
    `[webhook] ▶ Attempting to insert pembayaran record with custom id="${customPembayaranId}":`,
    JSON.stringify(pembayaranPayload, null, 2)
  );

  const { data: pembayaranData, error: pembayaranError } = await supabase
    .from("pembayaran")
    .insert(pembayaranPayload)
    .select();

  console.log("[webhook] ▶ Supabase insert pembayaran result:");
  console.log(`  → error  : ${pembayaranError ? JSON.stringify(pembayaranError) : "null (no error)"}`);
  console.log(`  → data   : ${JSON.stringify(pembayaranData)}`);

  if (pembayaranError) {
    console.error(
      `[webhook] ✖ DATABASE INSERT PEMBAYARAN FAILED for tagihan id=${cleanTagihanId}. ` +
      `Error code="${pembayaranError.code}", message="${pembayaranError.message}", ` +
      `details="${pembayaranError.details}", hint="${pembayaranError.hint}"`
    );
    return errorResponse(`DB insert pembayaran failed: ${pembayaranError.message}`, 500);
  }

  console.log(`[webhook] ✔✔ SUCCESS — pembayaran record inserted successfully.`);

  return jsonResponse({
    message: `Payment confirmed. Tagihan id=${cleanTagihanId} updated to lunas, and pembayaran logged.`,
    tagihan_id: cleanTagihanId,
    order_id: orderIdStr,
    pembayaran_id: customPembayaranId,
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
