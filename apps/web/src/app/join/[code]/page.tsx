import type { Metadata } from "next";

const CONVEX_SITE_URL = "https://avid-chicken-478.convex.site";

// TODO: Replace with actual App Store URL once live
const APP_STORE_URL = "https://apps.apple.com/app/junto";

interface InviteData {
  _id: string;
  code: string;
  universityId: string;
  universityName: string;
  universityShortName: string | null;
  universityCity: string;
  universityState: string;
  universityLogoUrl: string | null;
  program: string | null;
  role: string | null;
  label: string | null;
}

async function getInviteData(code: string): Promise<InviteData | null> {
  try {
    const res = await fetch(
      `${CONVEX_SITE_URL}/invite?code=${encodeURIComponent(code)}`,
      { next: { revalidate: 60 } }
    );
    if (!res.ok) return null;
    return await res.json();
  } catch {
    return null;
  }
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ code: string }>;
}): Promise<Metadata> {
  const { code } = await params;
  const invite = await getInviteData(code);

  if (!invite) {
    return {
      title: "Junto — Join your campus",
      description: "Find your people. Build together.",
    };
  }

  const title = invite.program
    ? `Join ${invite.universityShortName ?? invite.universityName} — ${invite.program} on Junto`
    : `Join ${invite.universityShortName ?? invite.universityName} on Junto`;

  const description = invite.program
    ? `You've been invited to join ${invite.program} at ${invite.universityName} on Junto. Find your people. Build together.`
    : `You've been invited to join ${invite.universityName} on Junto. Find your people. Build together.`;

  return {
    title,
    description,
    openGraph: {
      title,
      description,
      type: "website",
      url: `https://onjunto.com/join/${code}`,
      siteName: "Junto",
      ...(invite.universityLogoUrl && {
        images: [{ url: invite.universityLogoUrl, width: 200, height: 200 }],
      }),
    },
    twitter: {
      card: "summary",
      title,
      description,
    },
  };
}

export default async function JoinPage({
  params,
}: {
  params: Promise<{ code: string }>;
}) {
  const { code } = await params;
  const invite = await getInviteData(code);

  if (!invite) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-[#0a0a0a]">
        <div className="w-full max-w-md px-6 text-center">
          <h1 className="text-2xl font-bold tracking-tight text-white">
            Invite not found
          </h1>
          <p className="mt-3 text-[15px] text-[#888]">
            This invite link is invalid or has expired.
          </p>
        </div>
      </div>
    );
  }

  const deepLink = `junto://join/${code}`;

  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-[#0a0a0a] px-6">
      <div className="w-full max-w-sm text-center">
        {/* Logo */}
        {invite.universityLogoUrl && (
          <img
            src={invite.universityLogoUrl}
            alt={invite.universityName}
            className="mx-auto mb-8 h-20 w-20 rounded-2xl object-contain"
          />
        )}

        {/* Heading */}
        <h1 className="text-[28px] font-bold leading-tight tracking-tight text-white">
          {"You're invited to join"}
        </h1>
        <h2 className="mt-1 text-[28px] font-bold leading-tight tracking-tight text-[#32FF99]">
          {invite.universityShortName ?? invite.universityName}
        </h2>

        {invite.program && (
          <p className="mt-3 text-[17px] font-medium text-[#ccc]">
            {invite.program}
          </p>
        )}

        <p className="mt-2 text-[15px] text-[#888]">
          {invite.universityCity}, {invite.universityState}
        </p>

        {/* CTA */}
        <div className="mt-10 space-y-3">
          {/* Try deep link first (opens app if installed) */}
          <a
            href={deepLink}
            className="block w-full rounded-xl bg-white py-3.5 text-center text-[16px] font-semibold text-[#0a0a0a] transition-opacity hover:opacity-90"
          >
            Open in Junto
          </a>

          {/* App Store fallback */}
          <a
            href={APP_STORE_URL}
            className="block w-full rounded-xl border border-[#333] py-3.5 text-center text-[16px] font-semibold text-white transition-opacity hover:opacity-80"
          >
            Download Junto
          </a>
        </div>

        {/* Branding */}
        <div className="mt-12">
          <p className="text-[13px] font-medium tracking-wide text-[#555]">
            JUNTO
          </p>
          <p className="mt-1 text-[13px] text-[#444]">
            Find your people. Build together.
          </p>
        </div>
      </div>
    </div>
  );
}
