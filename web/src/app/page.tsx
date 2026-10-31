import Link from "next/link";
import Image from "next/image";
import {
  PlayCircle,
  Users,
  Shield,
  Smartphone,
  Eye,
  Award,
  Zap,
  Globe2,
  Lock,
  ArrowRight,
  HelpCircle,
} from "lucide-react";

export default function HomePage() {
  return (
    <div className="relative overflow-hidden w-full">
      {/* Background radial ambient lights */}
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[800px] h-[550px] ambient-glow pointer-events-none -z-10" />

      {/* Hero Section */}
      <section className="relative px-4 sm:px-6 pt-16 pb-24 md:pt-24 md:pb-32 max-w-6xl mx-auto flex flex-col items-center text-center">
        {/* Floating Oni Mask */}
        <div className="relative mb-8 group cursor-pointer">
          <div className="absolute -inset-4 rounded-full bg-crimson/20 blur-xl group-hover:bg-crimson/30 transition-all duration-500 animate-pulse-slow" />
          <div className="relative flex h-36 w-36 sm:h-44 sm:w-44 items-center justify-center rounded-3xl bg-panel border-2 border-crimson/40 shadow-2xl shadow-crimson/20 animate-float">
            <Image
              src="/mask.svg"
              alt="Sus Mask Logo"
              width={100}
              height={100}
              className="drop-shadow-[0_0_20px_rgba(225,29,72,0.6)] sm:w-[120px] sm:h-[120px]"
              priority
            />
          </div>
        </div>

        {/* Tagline Badge */}
        <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-crimson/15 border border-crimson/40 text-xs sm:text-sm font-bold tracking-widest text-crimson-bright uppercase mb-6">
          <Zap className="w-4 h-4" />
          <span>Social Deduction Party Game</span>
        </div>

        {/* Big Headline */}
        <h1 className="text-5xl sm:text-7xl md:text-8xl font-black tracking-tight text-white max-w-4xl leading-[1.05] mb-6">
          One word. <br />
          <span className="text-transparent bg-clip-text bg-gradient-to-r from-crimson-bright via-crimson to-crimson-glow">
            One imposter.
          </span>
        </h1>

        {/* Subtitle */}
        <p className="text-lg sm:text-xl md:text-2xl text-mute max-w-2xl font-normal leading-relaxed mb-10">
          A tense, dark minimalist party game for 3 to 12 players. Everyone knows the secret word
          except the imposter. Bluff, accuse, and deduce before the imposter guesses the word.
        </p>

        {/* Action Buttons */}
        <div className="flex flex-col sm:flex-row items-center gap-4 w-full sm:w-auto">
          <Link
            href="/play/mode"
            className="w-full sm:w-auto flex items-center justify-center gap-3 rounded-2xl bg-crimson px-8 py-4 text-lg font-extrabold text-white shadow-xl shadow-crimson/30 transition-all hover:bg-crimson-bright hover:shadow-crimson/50 hover:scale-[1.02] button-press"
          >
            <PlayCircle className="w-6 h-6" />
            <span>Play in Browser</span>
            <ArrowRight className="w-5 h-5 ml-1" />
          </Link>
          <Link
            href="/play/local"
            className="w-full sm:w-auto flex items-center justify-center gap-2.5 rounded-2xl bg-panel border-1.5 border-line px-7 py-4 text-lg font-bold text-bone hover:border-crimson hover:bg-panel-dark transition-all button-press"
          >
            <Users className="w-5 h-5 text-mute" />
            <span>Pass & Play (Offline)</span>
          </Link>
        </div>

        {/* Features highlight pills */}
        <div className="mt-14 flex flex-wrap items-center justify-center gap-6 sm:gap-8 text-xs sm:text-sm text-mute">
          <span className="flex items-center gap-2">
            <Globe2 className="w-4 h-4 text-crimson-bright" /> No App Store Required
          </span>
          <span className="flex items-center gap-2">
            <Lock className="w-4 h-4 text-crimson-bright" /> 4-Digit Locked Rooms
          </span>
          <span className="flex items-center gap-2">
            <Smartphone className="w-4 h-4 text-crimson-bright" /> Mobile & Desktop Optimized
          </span>
        </div>
      </section>

      {/* Secret Role Card Comparison Showcase */}
      <section className="relative px-4 sm:px-6 py-16 bg-ink/70 border-y border-line/60">
        <div className="max-w-6xl mx-auto">
          <div className="text-center max-w-2xl mx-auto mb-14">
            <h2 className="text-3xl sm:text-4xl font-extrabold text-white mb-3">
              The Asymmetric Bluff
            </h2>
            <p className="text-mute text-base sm:text-lg">
              Every round starts in secret. Hold your card to privately reveal your identity.
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-8 max-w-4xl mx-auto">
            {/* Normal Player Card */}
            <div className="relative rounded-2xl bg-panel p-8 border border-white/10 shadow-xl overflow-hidden group hover:border-white/20 transition-all">
              <div className="absolute top-4 right-4 px-3 py-1 rounded-full bg-emerald-950/60 border border-emerald-500/30 text-emerald-400 text-xs font-bold uppercase tracking-wider">
                Normal Role
              </div>
              <div className="flex items-center gap-3 mb-6">
                <div className="h-10 w-10 rounded-xl bg-white/10 flex items-center justify-center">
                  <Eye className="w-5 h-5 text-bone" />
                </div>
                <div>
                  <h3 className="font-extrabold text-lg text-bone">Normal Player</h3>
                  <p className="text-xs text-mute">Category: Mountains</p>
                </div>
              </div>
              <div className="rounded-xl bg-ink-deep/90 p-5 border border-line text-center my-4">
                <span className="text-xs uppercase tracking-widest text-mute block mb-1">Secret Word</span>
                <span className="text-3xl font-black text-white tracking-wide">EVEREST</span>
              </div>
              <p className="text-sm text-mute leading-relaxed">
                Give subtle clues that prove you know the word without revealing it to the imposter.
                Never say the word directly!
              </p>
            </div>

            {/* Imposter Card */}
            <div className="relative rounded-2xl bg-panel-dark p-8 border border-crimson/50 shadow-2xl shadow-crimson/10 overflow-hidden group hover:border-crimson transition-all">
              <div className="absolute top-4 right-4 px-3 py-1 rounded-full bg-crimson/30 border border-crimson text-crimson-bright text-xs font-bold uppercase tracking-wider">
                Imposter Role
              </div>
              <div className="flex items-center gap-3 mb-6">
                <div className="h-10 w-10 rounded-xl bg-crimson/20 flex items-center justify-center">
                  <Shield className="w-5 h-5 text-crimson-bright" />
                </div>
                <div>
                  <h3 className="font-extrabold text-lg text-white">The Imposter</h3>
                  <p className="text-xs text-mute">Category: Mountains</p>
                </div>
              </div>
              <div className="rounded-xl bg-crimson/20 p-5 border border-crimson/50 text-center my-4">
                <span className="text-xs uppercase tracking-widest text-crimson-bright block mb-1">
                  You are the
                </span>
                <span className="text-3xl font-black text-white tracking-wide">IMPOSTER</span>
              </div>
              <p className="text-sm text-mute leading-relaxed">
                You do NOT know the secret word. Listen to clues, bluff your turn to blend in, and
                guess the secret word for an instant victory!
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* Rules / Game Loop Section */}
      <section className="px-4 sm:px-6 py-20 max-w-6xl mx-auto">
        <div className="text-center max-w-2xl mx-auto mb-16">
          <h2 className="text-3xl sm:text-4xl font-extrabold text-white mb-3">
            How Sus Works
          </h2>
          <p className="text-mute text-base sm:text-lg">
            Four simple phases make every round unforgettable.
          </p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          {[
            {
              num: "01",
              title: "Secret Assignment",
              desc: "1 to 3 imposters are chosen randomly. Normal players see the secret word; imposters only see the category.",
            },
            {
              num: "02",
              title: "Clue Round-Robin",
              desc: "Players take turns in a random speaking order giving one clue about the word. Imposters must bluff convincingly.",
            },
            {
              num: "03",
              title: "Instant Accusation",
              desc: "Anyone can press Accuse at any time. Catch the imposter to eliminate them. Accuse wrong, and you lose your accusation!",
            },
            {
              num: "04",
              title: "Imposter Guess",
              desc: "At any moment, an imposter can attempt to guess the secret word. A correct guess secures an instant imposter victory.",
            },
          ].map((item) => (
            <div
              key={item.num}
              className="rounded-2xl bg-panel/70 p-6 border border-line/80 flex flex-col justify-between hover:border-crimson/60 transition-colors"
            >
              <div>
                <span className="text-3xl font-black text-crimson/60 block mb-3">{item.num}</span>
                <h3 className="font-extrabold text-lg text-bone mb-2">{item.title}</h3>
                <p className="text-sm text-mute leading-relaxed">{item.desc}</p>
              </div>
            </div>
          ))}
        </div>

        <div className="mt-12 text-center">
          <Link
            href="/rules"
            className="inline-flex items-center gap-2 text-sm font-bold text-crimson-bright hover:text-white transition-colors"
          >
            <HelpCircle className="w-4 h-4" />
            <span>Read full game rules, voting rules and scoring strategy →</span>
          </Link>
        </div>
      </section>

      {/* Cross-Platform CTA Section */}
      <section className="px-4 sm:px-6 py-20 bg-panel-dark/80 border-t border-line/60">
        <div className="max-w-4xl mx-auto rounded-3xl bg-gradient-to-b from-panel to-ink p-8 sm:p-14 border border-line flex flex-col md:flex-row items-center justify-between gap-8 text-center md:text-left">
          <div className="max-w-md">
            <h2 className="text-3xl font-black text-white mb-3">
              Play on your phone, laptop, or browser
            </h2>
            <p className="text-mute text-sm sm:text-base leading-relaxed">
              Play online with friends anywhere in the world, or pass a single device around the room
              offline. Download the Android APK or launch right here.
            </p>
          </div>
          <div className="flex flex-col sm:flex-row gap-3 w-full md:w-auto">
            <Link
              href="/play/mode"
              className="flex items-center justify-center gap-2 rounded-xl bg-crimson px-6 py-3.5 font-bold text-white shadow-lg shadow-crimson/30 hover:bg-crimson-bright transition-all button-press"
            >
              <PlayCircle className="w-5 h-5" />
              <span>Launch Web Game</span>
            </Link>
            <Link
              href="/download"
              className="flex items-center justify-center gap-2 rounded-xl bg-panel border border-line px-5 py-3.5 font-bold text-bone hover:border-crimson transition-all button-press"
            >
              <Smartphone className="w-5 h-5 text-mute" />
              <span>Download APK</span>
            </Link>
          </div>
        </div>
      </section>
    </div>
  );
}
