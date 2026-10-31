"use client";

import Link from "next/link";
import { ArrowLeft, Globe2, PlusCircle, Users } from "lucide-react";
import { sounds } from "@/lib/audio/soundEffects";

export default function ModePage() {
  return (
    <div className="mx-auto max-w-xl w-full px-4 sm:px-6 py-12 flex-1 flex flex-col justify-center">
      <Link
        href="/"
        onClick={() => sounds.playTick()}
        className="inline-flex items-center gap-2 text-sm font-semibold text-mute hover:text-bone transition-colors mb-8"
      >
        <ArrowLeft className="w-4 h-4" />
        <span>Back to Home</span>
      </Link>

      <div className="mb-8">
        <h1 className="text-3xl sm:text-4xl font-black text-white tracking-tight mb-2">
          Pick how to play
        </h1>
        <p className="text-mute text-base">
          Choose between online multiplayer across devices or pass-and-play on this screen.
        </p>
      </div>

      <div className="space-y-4">
        {/* Card 1: Join Game */}
        <Link
          href="/play/rooms"
          onClick={() => sounds.playTick()}
          className="group block rounded-2xl bg-panel p-6 border-2 border-line hover:border-crimson hover:bg-panel-dark transition-all duration-200 button-press shadow-lg shadow-black/40"
        >
          <div className="flex items-start gap-4">
            <div className="h-12 w-12 rounded-xl bg-crimson/15 border border-crimson/30 flex items-center justify-center group-hover:bg-crimson group-hover:text-white text-crimson-bright transition-all">
              <Globe2 className="w-6 h-6" />
            </div>
            <div className="flex-1">
              <h3 className="text-xl font-bold text-bone group-hover:text-white transition-colors">
                Join a game
              </h3>
              <p className="text-sm text-mute mt-1 leading-relaxed">
                Browse open multiplayer rooms and enter with a 4-digit PIN.
              </p>
            </div>
          </div>
        </Link>

        {/* Card 2: Create Game */}
        <Link
          href="/play/create"
          onClick={() => sounds.playTick()}
          className="group block rounded-2xl bg-panel p-6 border-2 border-line hover:border-crimson hover:bg-panel-dark transition-all duration-200 button-press shadow-lg shadow-black/40"
        >
          <div className="flex items-start gap-4">
            <div className="h-12 w-12 rounded-xl bg-crimson/15 border border-crimson/30 flex items-center justify-center group-hover:bg-crimson group-hover:text-white text-crimson-bright transition-all">
              <PlusCircle className="w-6 h-6" />
            </div>
            <div className="flex-1">
              <h3 className="text-xl font-bold text-bone group-hover:text-white transition-colors">
                Create a game
              </h3>
              <p className="text-sm text-mute mt-1 leading-relaxed">
                Configure imposters, discussion rounds, categories, and invite friends with your PIN.
              </p>
            </div>
          </div>
        </Link>

        {/* Card 3: Local Pass and Play */}
        <Link
          href="/play/local"
          onClick={() => sounds.playTick()}
          className="group block rounded-2xl bg-panel p-6 border-2 border-line hover:border-crimson hover:bg-panel-dark transition-all duration-200 button-press shadow-lg shadow-black/40"
        >
          <div className="flex items-start gap-4">
            <div className="h-12 w-12 rounded-xl bg-white/5 border border-white/10 flex items-center justify-center group-hover:bg-panel text-bone transition-all">
              <Users className="w-6 h-6" />
            </div>
            <div className="flex-1">
              <h3 className="text-xl font-bold text-bone group-hover:text-white transition-colors">
                Local Pass & Play
              </h3>
              <p className="text-sm text-mute mt-1 leading-relaxed">
                Play on this single screen with friends in the same room. Completely offline.
              </p>
            </div>
          </div>
        </Link>
      </div>
    </div>
  );
}
