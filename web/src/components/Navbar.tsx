"use client";

import Link from "next/link";
import Image from "next/image";
import { usePathname } from "next/navigation";
import { ShieldAlert, BookOpen, Smartphone, PlayCircle } from "lucide-react";

export function Navbar() {
  const pathname = usePathname();

  const navLinks = [
    { href: "/play/mode", label: "Play Game", icon: PlayCircle },
    { href: "/rules", label: "How to Play", icon: BookOpen },
    { href: "/download", label: "App & APK", icon: Smartphone },
  ];

  return (
    <header className="sticky top-0 z-50 w-full border-b border-line/60 bg-ink-deep/80 backdrop-blur-xl">
      <div className="mx-auto flex h-16 max-w-6xl items-center justify-between px-4 sm:px-6">
        {/* Brand logo & tagline */}
        <Link href="/" className="group flex items-center gap-3">
          <div className="relative flex h-10 w-10 items-center justify-center rounded-xl bg-crimson/15 border border-crimson/30 transition-all duration-300 group-hover:scale-105 group-hover:border-crimson group-hover:shadow-[0_0_15px_rgba(225,29,72,0.4)]">
            <Image
              src="/mask.svg"
              alt="Sus Oni Mask Logo"
              width={26}
              height={26}
              className="transition-transform group-hover:rotate-3"
            />
          </div>
          <div className="flex flex-col">
            <span className="font-extrabold tracking-wider text-bone text-lg leading-tight group-hover:text-white">
              SUS
            </span>
            <span className="text-[10px] font-semibold text-mute tracking-widest uppercase">
              One word. One imposter.
            </span>
          </div>
        </Link>

        {/* Center navigation links */}
        <nav className="hidden md:flex items-center gap-1">
          {navLinks.map((item) => {
            const Icon = item.icon;
            const isActive = pathname.startsWith(item.href);
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`flex items-center gap-2 px-3.5 py-2 rounded-lg text-sm font-semibold transition-all duration-150 ${
                  isActive
                    ? "bg-crimson/20 text-crimson-bright border border-crimson/30 shadow-sm"
                    : "text-mute hover:text-bone hover:bg-panel/60"
                }`}
              >
                <Icon className="w-4 h-4" />
                {item.label}
              </Link>
            );
          })}
        </nav>

        {/* Action button */}
        <div className="flex items-center gap-3">
          <Link
            href="/play/mode"
            className="flex items-center gap-2 rounded-xl bg-crimson px-4 py-2 text-sm font-bold text-white shadow-md shadow-crimson/30 transition-all hover:bg-crimson-bright hover:shadow-crimson/50 button-press"
          >
            <ShieldAlert className="w-4 h-4" />
            <span>Play Now</span>
          </Link>
        </div>
      </div>
    </header>
  );
}
