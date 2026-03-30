import { httpRouter } from "convex/server";
import { httpAction } from "./_generated/server";
import { api } from "./_generated/api";
import { Id } from "./_generated/dataModel";

const http = httpRouter();

// CORS headers for all responses
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

// Handle OPTIONS requests for CORS
http.route({
  path: "/registerDeviceToken",
  method: "OPTIONS",
  handler: httpAction(async () => {
    return new Response(null, { status: 204, headers: corsHeaders });
  }),
});

http.route({
  path: "/removeDeviceToken",
  method: "OPTIONS",
  handler: httpAction(async () => {
    return new Response(null, { status: 204, headers: corsHeaders });
  }),
});

// Register device token for push notifications
http.route({
  path: "/registerDeviceToken",
  method: "POST",
  handler: httpAction(async (ctx, request) => {
    try {
      const body = await request.json();
      const { user_id, token, platform, app_version, device_model, os_version } = body;

      if (!user_id || !token || !platform) {
        return new Response(
          JSON.stringify({ error: "user_id, token, and platform are required" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      await ctx.runMutation(api.deviceTokens.register, {
        userId: user_id as Id<"users">,
        token,
        platform,
        appVersion: app_version,
        deviceModel: device_model,
        osVersion: os_version,
      });

      return new Response(
        JSON.stringify({ success: true }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    } catch (error) {
      console.error("Error registering device token:", error);
      return new Response(
        JSON.stringify({ error: "Failed to register device token" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
  }),
});

// Remove device token
http.route({
  path: "/removeDeviceToken",
  method: "POST",
  handler: httpAction(async (ctx, request) => {
    try {
      const body = await request.json();
      const { token } = body;

      if (!token) {
        return new Response(
          JSON.stringify({ error: "token is required" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      await ctx.runMutation(api.deviceTokens.remove, { token });

      return new Response(
        JSON.stringify({ success: true }),
        { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    } catch (error) {
      console.error("Error removing device token:", error);
      return new Response(
        JSON.stringify({ error: "Failed to remove device token" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
  }),
});

// Get user by Clerk ID (for iOS app)
http.route({
  path: "/getUserByClerkId",
  method: "GET",
  handler: httpAction(async (ctx, request) => {
    try {
      const url = new URL(request.url);
      const clerkId = url.searchParams.get("clerk_id");

      if (!clerkId) {
        return new Response(
          JSON.stringify({ error: "clerk_id is required" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const user = await ctx.runQuery(api.users.getByClerkId, { clerkId });

      if (!user) {
        return new Response("null", {
          status: 200,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      // Convert Convex ID format to match iOS expectations
      const response = {
        _id: user._id,
        clerk_id: user.clerkId,
        email: user.email,
        name: user.name,
        headline: user.headline,
        looking_for: user.lookingFor,
        avatar_url: user.avatarUrl,
        interests: user.interests,
        role: user.role,
        onboarding_completed_at: user.isOnboarded ? user.updatedAt : null,
        created_at: user.createdAt,
        updated_at: user.updatedAt,
      };

      return new Response(JSON.stringify(response), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    } catch (error) {
      console.error("Error fetching user:", error);
      return new Response(
        JSON.stringify({ error: "Failed to fetch user" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
  }),
});

// Get all users
http.route({
  path: "/getUsers",
  method: "GET",
  handler: httpAction(async (ctx) => {
    try {
      const users = await ctx.runQuery(api.users.list, {});

      // Convert to iOS format
      const response = users.map((user) => ({
        _id: user._id,
        clerk_id: user.clerkId,
        email: user.email,
        name: user.name,
        headline: user.headline,
        looking_for: user.lookingFor,
        avatar_url: user.avatarUrl,
        interests: user.interests,
        role: user.role,
        onboarding_completed_at: user.isOnboarded ? user.updatedAt : null,
        created_at: user.createdAt,
        updated_at: user.updatedAt,
      }));

      return new Response(JSON.stringify(response), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    } catch (error) {
      console.error("Error fetching users:", error);
      return new Response(
        JSON.stringify({ error: "Failed to fetch users" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
  }),
});

// Resolve invite link by code
http.route({
  path: "/invite",
  method: "GET",
  handler: httpAction(async (ctx, request) => {
    try {
      const url = new URL(request.url);
      const code = url.searchParams.get("code");

      if (!code) {
        return new Response(
          JSON.stringify({ error: "code parameter is required" }),
          { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      const result = await ctx.runQuery(api.inviteLinks.getByCode, { code });

      if (!result) {
        return new Response(
          JSON.stringify({ error: "Invalid or expired invite link" }),
          { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
      }

      return new Response(JSON.stringify(result), {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    } catch (error) {
      console.error("Error resolving invite:", error);
      return new Response(
        JSON.stringify({ error: "Failed to resolve invite link" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }
  }),
});

http.route({
  path: "/invite",
  method: "OPTIONS",
  handler: httpAction(async () => {
    return new Response(null, { status: 204, headers: corsHeaders });
  }),
});

export default http;
