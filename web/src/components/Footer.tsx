import Link from "next/link";
import Image from "next/image";
import { ShieldCheck, Heart } from "lucide-react";

export function Footer() {
  return (
    <footer className="w-full border-t border-line/50 bg-ink-deep/90 py-12 px-4 sm:px-6">
      <div className="mx-auto max-w-6xl">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8 mb-10">
          {/* Brand Column */}
          <div className="md:col-span-2 flex flex-col gap-3">
            <div className="flex items-center gap-3">
              <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-crimson/20 border border-crimson/40">
                <Image src="/mask.svg" alt="Sus Logo" width={22} height={22} />
              </div>
              <span className="font-extrabold text-xl tracking-wider text-bone">SUS</span>
            </div>
            <p className="text-sm text-mute max-w-sm leading-relaxed">
              A tense, dark minimalist social deduction party game for 3 to 12 players.
              One secret word. One imposter trying to blend in. Available as a cross-platform mobile app,
              Linux desktop binary, and full web application.
            </p>
            <div className="flex items-center gap-2 text-xs text-mute mt-2">
              <ShieldCheck className="w-4 h-4 text-emerald-500" />
              <span>Zero tracking cookies • Ephemeral in-memory rooms • MIT License</span>
            </div>
          </div>

          {/* Game Modes */}
          <div className="flex flex-col gap-2.5">
            <h4 className="text-sm font-bold uppercase tracking-wider text-bone">Play</h4>
            <Link href="/play/mode" className="text-sm text-mute hover:text-bone transition-colors">
              Pick Game Mode
            </Link>
            <Link href="/play/rooms" className="text-sm text-mute hover:text-bone transition-colors">
              Browse Online Rooms
            </Link>
            <Link href="/play/local" className="text-sm text-mute hover:text-bone transition-colors">
              Local Pass & Play
            </Link>
            <Link href="/rules" className="text-sm text-mute hover:text-bone transition-colors">
              Rules & Strategy
            </Link>
            <Link href="/download" className="text-sm text-mute hover:text-bone transition-colors">
              Download Android APK
            </Link>
          </div>

          {/* Legal Compliance */}
          <div className="flex flex-col gap-2.5">
            <h4 className="text-sm font-bold uppercase tracking-wider text-bone">Legal & Info</h4>
            <Link href="/terms" className="text-sm text-mute hover:text-bone transition-colors">
              Terms of Service
            </Link>
            <Link href="/privacy" className="text-sm text-mute hover:text-bone transition-colors">
              Privacy Policy
            </Link>
            <Link href="/legal" className="text-sm text-mute hover:text-bone transition-colors">
              Legal Notice & Impressum
            </Link>
            <a
              href="https://github.com/akashrai-dev-spec/Sus"
              target="_blank"
              rel="noreferrer"
              className="text-sm text-mute hover:text-bone transition-colors"
            >
              GitHub Repository
            </a>
          </div>
        </div>

        {/* Bottom Bar */}
        <div className="border-t border-line/40 pt-6 flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-mute">
          <p>© {new Date().getFullYear()} akashrai.dev & Aaryan Banskota. Released under the MIT License.</p>
          <p className="flex items-center gap-1">
            Built for game nights with friends <Heart className="w-3.5 h-3.5 text-crimson fill-crimson" />
          </p>
        </div>
      </div>
    </footer>
  );
}
