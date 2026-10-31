import Link from "next/link";
import { ArrowLeft, ShieldCheck, Lock, EyeOff } from "lucide-react";

export default function PrivacyPage() {
  return (
    <div className="mx-auto max-w-3xl w-full px-4 sm:px-6 py-12 flex-1">
      <Link
        href="/"
        className="inline-flex items-center gap-2 text-sm font-semibold text-mute hover:text-bone mb-8"
      >
        <ArrowLeft className="w-4 h-4" />
        <span>Back to Home</span>
      </Link>

      <div className="mb-10">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-950/60 border border-emerald-500/40 text-xs font-bold text-emerald-400 uppercase mb-3">
          <ShieldCheck className="w-3.5 h-3.5" />
          <span>Privacy-First Architecture</span>
        </div>
        <h1 className="text-4xl font-black text-white tracking-tight mb-2">Privacy Policy</h1>
        <p className="text-sm text-mute">Effective Date: October 2026 • Zero Telemetry Standard</p>
      </div>

      <div className="space-y-8 text-sm leading-relaxed text-bone/90">
        <section className="rounded-2xl bg-panel p-6 border border-line">
          <h2 className="text-lg font-bold text-white mb-2">1. No Personal Data Collection</h2>
          <p className="text-mute">
            Sus is built with an unwavering commitment to player privacy. We do <b>NOT</b> require
            user accounts, passwords, email addresses, phone numbers, or credit cards. You can play
            instantly without giving up any identity.
          </p>
        </section>

        <section className="rounded-2xl bg-panel p-6 border border-line">
          <h2 className="text-lg font-bold text-white mb-2">2. Local Storage on Your Device</h2>
          <p className="text-mute">
            Your custom display nickname, avatar color, and local pass-and-play rosters are
            persisted solely within your device&apos;s sandboxed browser storage (<code>localStorage</code>)
            or mobile preferences. This data remains on your physical hardware and is never synced to
            central databases.
          </p>
        </section>

        <section className="rounded-2xl bg-panel p-6 border border-line">
          <h2 className="text-lg font-bold text-white mb-2">3. Ephemeral Server Sessions</h2>
          <p className="text-mute mb-2">
            When you create or join an online multiplayer room:
          </p>
          <ul className="list-disc pl-5 space-y-1.5 text-mute">
            <li>Rooms are held purely in transient memory on the server.</li>
            <li>4-digit room access PINs are cryptographically hashed using Argon2.</li>
            <li>All room records, player handles, and clue logs are permanently wiped 2 minutes after a match ends.</li>
          </ul>
        </section>

        <section className="rounded-2xl bg-panel p-6 border border-line">
          <h2 className="text-lg font-bold text-white mb-2">4. Zero Third-Party Trackers or Cookies</h2>
          <p className="text-mute">
            Sus contains no Google Analytics, no Facebook Pixels, no advertising networks, and no
            third-party tracking cookies. The bundled fonts (Inter) and SVG graphics are served
            statically to protect your IP address from third-party CDNs.
          </p>
        </section>

        <section className="rounded-2xl bg-panel p-6 border border-line">
          <h2 className="text-lg font-bold text-white mb-2">5. Compliance & Inquiries</h2>
          <p className="text-mute">
            This policy satisfies the requirements of the EU General Data Protection Regulation
            (GDPR) and the California Consumer Privacy Act (CCPA). For audit requests or self-hosting
            inquiries, view our public source code on GitHub.
          </p>
        </section>
      </div>
    </div>
  );
}
