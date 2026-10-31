import { NextResponse } from "next/server";

export const dynamic = "force-dynamic";

export async function GET() {
  const targetUrl =
    process.env.SERVER_URL ||
    process.env.NEXT_PUBLIC_SERVER_URL ||
    (process.env.NODE_ENV === "production"
      ? "https://sus-server-t5te.onrender.com"
      : "http://localhost:3000");

  try {
    const res = await fetch(new URL("/health", targetUrl), {
      cache: "no-store",
    });

    if (!res.ok) {
      return NextResponse.json(
        {
          status: "error",
          message: `Backend server returned status ${res.status}`,
        },
        { status: 502 },
      );
    }

    const data = await res.json();
    return NextResponse.json({
      status: "ok",
      web: "healthy",
      server: data,
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : "Unknown error";
    return NextResponse.json(
      {
        status: "degraded",
        web: "healthy",
        server: null,
        error: message,
      },
      { status: 503 },
    );
  }
}
