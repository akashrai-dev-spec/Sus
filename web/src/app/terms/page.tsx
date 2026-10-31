import Link from "next/link";
import { ArrowLeft, ShieldCheck, Scale, AlertOctagon } from "lucide-react";

export default function TermsPage() {
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
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-crimson/15 border border-crimson/30 text-xs font-bold text-crimson-bright uppercase mb-3">
          <Scale className="w-3.5 h-3.5" />
          <span>Legal Agreement</span>
        </div>
        <h1 className="text-4xl font-black text-white tracking-tight mb-2">Terms of Service</h1>
        <p className="text-sm text-mute">Effective Date: October 2026 • Version 1.0.0</p>
      </div>

      <div className="space-y-8 text-sm leading-relaxed text-bone/90">
        <section className="rounded-2xl bg-panel p-6 border border-line">
          <h2 className="text-lg font-bold text-white mb-2">1. Acceptance of Terms</h2>
          <p className="text-mute">
            By downloading, installing, browsing, or playing <b>Sus</b> (the &quot;Game&quot;), whether
            via our official web client or native application binaries, you agree to comply with
            and be bound by these Terms of Service. If you do not accept these terms, you may not
            access or use the software.
          </p>
        </section>

        <section className="rounded-2xl bg-panel p-6 border border-line">
          <h2 className="text-lg font-bold text-white mb-2">2. Open Source License</h2>
          <p className="text-mute">
            The Sus software is distributed under the permissive <b>MIT License</b>. You are granted
            permission to inspect, compile, run, modify, and self-host the game for private and
            public enjoyment, provided that all copyright notices and warranty disclaimers remain
            intact.
          </p>
        </section>

        <section className="rounded-2xl bg-panel p-6 border border-line">
          <h2 className="text-lg font-bold text-white mb-2">3. Community Standards & Acceptable Use</h2>
          <p className="text-mute mb-3">
            Sus is built to bring friends and gaming communities together. You agree not to abuse
            the room creation or clue messaging features to post:
          </p>
          <ul className="list-disc pl-5 space-y-1.5 text-mute">
            <li>Defamatory, obscene, harassing, or sexually explicit text.</li>
            <li>Content that promotes violence, bigotry, or hatred against protected groups.</li>
            <li>Commercial advertisements, spam, or phishing links.</li>
          </ul>
        </section>

        <section className="rounded-2xl bg-panel p-6 border border-line">
          <h2 className="text-lg font-bold text-white mb-2">4. Multiplayer Anti-Cheat & Security</h2>
          <p className="text-mute">
            Online game rooms are protected by cryptographic Argon2 PIN hashes and rate-limiters.
            Any intentional attempts to overload server sockets, spoof authoritative game state, or
            bypass security measures are strictly prohibited and will result in IP-level connection
            revocation.
          </p>
        </section>

        <section className="rounded-2xl bg-panel p-6 border border-line">
          <h2 className="text-lg font-bold text-white mb-2">5. Disclaimer of Warranties</h2>
          <p className="text-mute">
            THE GAME IS PROVIDED &quot;AS IS&quot;, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
            INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
            PARTICULAR PURPOSE, AND NONINFRINGEMENT. UNDER NO CIRCUMSTANCES SHALL THE AUTHORS BE
            LIABLE FOR ANY CLAIM OR DAMAGES.
          </p>
        </section>
      </div>
    </div>
  );
}
