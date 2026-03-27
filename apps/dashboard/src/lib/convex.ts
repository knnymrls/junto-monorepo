import { ConvexHttpClient } from "convex/browser";
import { makeFunctionReference } from "convex/server";

export const convex = new ConvexHttpClient(
  process.env.NEXT_PUBLIC_CONVEX_URL!
);

// Helper to query the mkrs-world Convex deployment from a separate repo
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export async function queryDashboard<T = any>(
  functionName: string,
  args: Record<string, unknown> = {}
): Promise<T> {
  const ref = makeFunctionReference<"query">(functionName);
  return convex.query(ref, args) as Promise<T>;
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export async function mutateDashboard<T = any>(
  functionName: string,
  args: Record<string, unknown> = {}
): Promise<T> {
  const ref = makeFunctionReference<"mutation">(functionName);
  return convex.mutation(ref, args) as Promise<T>;
}

// Upload a file to Convex storage and return the public URL
export async function uploadToConvex(file: File): Promise<string> {
  // 1. Get an upload URL from the backend
  const uploadUrl = await mutateDashboard<string>("storage:generateUploadUrl");

  // 2. Upload the file directly to Convex storage
  const result = await fetch(uploadUrl, {
    method: "POST",
    headers: { "Content-Type": file.type },
    body: file,
  });
  const { storageId } = await result.json();

  // 3. Get the public URL for the stored file
  const url = await queryDashboard<string>("storage:getUrl", { storageId });
  return url;
}
