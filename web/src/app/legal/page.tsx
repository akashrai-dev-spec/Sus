import Link from "next/link";
import { ArrowLeft, BookOpen, FileText } from "lucide-react";

export default function LegalNoticePage() {
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
        <h1 className="text-4xl font-black text-white tracking-tight mb-2">
          Legal Notice & Impressum
        </h1>
        <p className="text-sm text-mute">Information pursuant to digital media regulations</p>
      </div>

      <div className="space-y-8 text-sm leading-relaxed text-bone/90">
        <section className="rounded-2xl bg-panel p-6 border border-line">
          <h2 className="text-lg font-bold text-white mb-2">Project Authorship & Maintainers</h2>
          <p className="text-mute mb-3">
            <b>Sus</b> is an independent software project created and maintained by:
          </p>
          <div className="rounded-xl bg-ink-deep p-4 border border-line text-xs space-y-1 text-bone">
            <p><b>Lead Developer & Architecture:</b> Akash Rai (akashrai.dev)</p>
            <p><b>Principal Engineer & Design:</b> Aaryan Banskota</p>
            <p><b>Repository:</b> github.com/akashrai-dev-spec/Sus</p>
          </div>
        </section>

        <section className="rounded-2xl bg-panel p-6 border border-line">
          <h2 className="text-lg font-bold text-white mb-2">Trademark Disclaimers</h2>
          <p className="text-mute leading-relaxed">
            &quot;Sus&quot; is an original turn-based deduction party game inspired by traditional parlor
            games (such as Spyfall, Undercover, and Chameleon). It is an independent creation and
            is not affiliated with, endorsed by, or sponsored by Innersloth LLC (&quot;Among Us&quot;) or any
            other video game franchise. All trademarks mentioned in the word bank are the property of
            their respective owners and are utilized strictly for descriptive trivia purposes under
            fair use.
          </p>
        </section>

        <section className="rounded-2xl bg-panel p-6 border border-line">
          <h2 className="text-lg font-bold text-white mb-2">Open Source License (MIT)</h2>
          <div className="rounded-xl bg-ink-deep p-4 border border-line font-mono text-xs text-mute/80 space-y-2">
            <p>Copyright (c) 2026 akashrai.dev &amp; Aaryan Banskota</p>
            <p>
              Permission is hereby granted, free of charge, to any person obtaining a copy of this
              software and associated documentation files (the &quot;Software&quot;), to deal in the Software
              without restriction, including without limitation the rights to use, copy, modify,
              merge, publish, distribute, sublicense, and/or sell copies of the Software.
            </p>
          </div>
        </section>
      </div>
    </div>
  );
}
