// supabase/functions/send-reminder/index.ts
// Secure FCM Push Notification Sender — SP3A
//
// Sends payment reminders to customers.
// Uses RS256 signing of a JWT for OAuth2 to authenticate with FCM HTTP v1 REST API.
// Automatically runs in Simulation Mode if FIREBASE_SERVICE_ACCOUNT secret is missing.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// ── CORS Helper ────────────────────────────────────────────────────────────────
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

// ══════════════════════════════════════════════════════════════════════════════
// Deno Serve router
// ══════════════════════════════════════════════════════════════════════════════
Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return errorResponse("Method not allowed. Use POST.", 405);
  }

  try {
    const { pelanggan_id, periode } = await req.json();

    console.log(`[send-reminder] Received request: pelanggan_id="${pelanggan_id}", periode="${periode}"`);

    if (!pelanggan_id || !periode) {
      return errorResponse("Missing required fields: pelanggan_id, periode");
    }

    // 1. Initialize Supabase Admin Client
    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error("SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY is not configured.");
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    // 2. Fetch User Profile to get fcm_token
    console.log(`[send-reminder] Fetching user profile from DB...`);
    const { data: user, error: userError } = await supabase
      .from("users")
      .select("fcm_token, nama_lengkap")
      .eq("id", pelanggan_id)
      .single();

    if (userError || !user) {
      return errorResponse(`Customer profile not found in database: ${userError?.message || "unknown"}`);
    }

    const fcmToken = user.fcm_token;
    if (!fcmToken) {
      return errorResponse(`Pelanggan "${user.nama_lengkap}" does not have an FCM token registered on their device.`);
    }

    console.log(`[send-reminder] Customer fcm_token found: "${fcmToken.substring(0, 15)}..."`);

    // 3. Authenticate with Firebase & send push notification
    const firebaseCredentialsJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    
    if (!firebaseCredentialsJson || firebaseCredentialsJson.trim() === "") {
      console.warn("FIREBASE_SERVICE_ACCOUNT environment variable is not set. Executing in Simulation Mode.");
      return jsonResponse({
        success: true,
        message: `Remind notification sent successfully (SIMULATED: Device Token identified for user "${user.nama_lengkap}").`,
      });
    }

    let serviceAccount: {
      project_id?: string;
      client_email?: string;
      private_key?: string;
    };

    try {
      serviceAccount = JSON.parse(firebaseCredentialsJson);
    } catch (parseErr) {
      throw new Error(`Failed to parse FIREBASE_SERVICE_ACCOUNT: ${parseErr.message}`);
    }

    if (!serviceAccount.project_id || !serviceAccount.client_email || !serviceAccount.private_key) {
      throw new Error("FIREBASE_SERVICE_ACCOUNT missing required fields (project_id, client_email, private_key).");
    }

    console.log(`[send-reminder] Authenticating with Google OAuth...`);
    const accessToken = await getAccessToken(serviceAccount);

    console.log(`[send-reminder] Dispatching push notification via FCM REST v1 API...`);
    const fcmEndpoint = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`;
    
    const fcmResponse = await fetch(fcmEndpoint, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token: fcmToken,
          notification: {
            title: "Peringatan Tagihan SP3A",
            body: `Anda memiliki tagihan air untuk periode ${periode} yang belum dibayar. Mohon segera lunasi.`,
          },
        },
      }),
    });

    const fcmResult = await fcmResponse.json();
    console.log(`[send-reminder] FCM server response status: ${fcmResponse.status}`);
    console.log(`[send-reminder] FCM server response body:`, JSON.stringify(fcmResult));

    if (!fcmResponse.ok) {
      throw new Error(`FCM REST API returned error: ${JSON.stringify(fcmResult)}`);
    }

    return jsonResponse({
      success: true,
      message: `Remind notification sent successfully to user "${user.nama_lengkap}".`,
      data: fcmResult,
    });
  } catch (error) {
    console.error(`[send-reminder] Exception caught:`, error);
    return jsonResponse({ error: error.message }, 500);
  }
});

// ===============================================================================
// OAuth2 JWT Token Signer & Exchange Helper
// ===============================================================================
async function getAccessToken(serviceAccount: any): Promise<string> {
  const iat = Math.floor(Date.now() / 1000);
  const exp = iat + 3600;

  const header = { alg: "RS256", typ: "JWT" };
  const claimSet = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp,
    iat,
  };

  const encodedHeader = b64(JSON.stringify(header));
  const encodedPayload = b64(JSON.stringify(claimSet));
  const signatureInput = `${encodedHeader}.${encodedPayload}`;

  const privateKeyPem = serviceAccount.private_key;
  const privateKey = await importPrivateKey(privateKeyPem);

  const signatureBuffer = await crypto.subtle.sign(
    { name: "RSASSA-PKCS1-v1_5" },
    privateKey,
    new TextEncoder().encode(signatureInput)
  );

  const signature = b64Url(new Uint8Array(signatureBuffer));
  const jwt = `${signatureInput}.${signature}`;

  // Exchange JWT for access token
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });

  const data = await response.json();
  if (data.error) {
    throw new Error(`Google Token exchange failed: ${data.error_description || data.error}`);
  }
  return data.access_token;
}

function b64(str: string): string {
  return btoa(str).replace(/=/g, "").replace(/\+/g, "-").replace(/\//g, "_");
}

function b64Url(buf: Uint8Array): string {
  return btoa(String.fromCharCode(...buf))
    .replace(/=/g, "")
    .replace(/\+/g, "-")
    .replace(/\//g, "_");
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const pemHeader = "-----BEGIN PRIVATE KEY-----";
  const pemFooter = "-----END PRIVATE KEY-----";
  const pemContents = pem
    .replace(pemHeader, "")
    .replace(pemFooter, "")
    .replace(/\s/g, "");

  const binaryDerString = atob(pemContents);
  const binaryDer = new Uint8Array(binaryDerString.length);
  for (let i = 0; i < binaryDerString.length; i++) {
    binaryDer[i] = binaryDerString.charCodeAt(i);
  }

  return await crypto.subtle.importKey(
    "pkcs8",
    binaryDer.buffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );
}
