import Link from "next/link";
import { ArrowLeft, BookOpen, Eye, Shield, Users, HelpCircle, CheckCircle, Flame } from "lucide-react";

export default function RulesPage() {
  return (
    <div className="mx-auto max-w-4xl w-full px-4 sm:px-6 py-12 flex-1">
      <Link
        href="/"
        className="inline-flex items-center gap-2 text-sm font-semibold text-mute hover:text-bone mb-8"
      >
        <ArrowLeft className="w-4 h-4" />
        <span>Back to Home</span>
      </Link>

      <div className="mb-12 text-center max-w-2xl mx-auto">
        <div className="inline-flex items-center gap-2 px-3.5 py-1 rounded-full bg-crimson/15 border border-crimson/30 text-xs font-bold text-crimson-bright uppercase mb-3">
          <BookOpen className="w-3.5 h-3.5" />
          <span>Game Guide & Strategy</span>
        </div>
        <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight mb-3">
          How to Play Sus
        </h1>
        <p className="text-mute text-base sm:text-lg">
          Master the art of subtle clue giving, imposter bluffing, and decisive accusations.
        </p>
      </div>

      <div className="space-y-12">
        {/* Core Concept */}
        <section className="rounded-3xl bg-panel p-8 border border-line">
          <h2 className="text-2xl font-black text-white mb-4">The Objective</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="rounded-2xl bg-ink-deep p-6 border border-line">
              <div className="flex items-center gap-2 text-emerald-400 font-bold text-base mb-2">
                <CheckCircle className="w-5 h-5" />
                <span>Normal Players</span>
              </div>
              <p className="text-sm text-mute leading-relaxed">
                You know the secret word. Cooperate by giving clues that hint at the word without
                revealing it to the imposter. Unmask and eliminate every imposter to win!
              </p>
            </div>
            <div className="rounded-2xl bg-ink-deep p-6 border border-crimson/40">
              <div className="flex items-center gap-2 text-crimson-bright font-bold text-base mb-2">
                <Flame className="w-5 h-5" />
                <span>The Imposters</span>
              </div>
              <p className="text-sm text-mute leading-relaxed">
                You only see the category. Listen to other players&apos; clues, bluff your turn to blend in,
                and try to deduce the secret word. Guessing the word correctly wins you the game
                immediately!
              </p>
            </div>
          </div>
        </section>

        {/* 5 Stages */}
        <section>
          <h2 className="text-2xl font-black text-white mb-6">Match Progression</h2>
          <div className="space-y-4">
            {[
              {
                step: "Phase 1",
                title: "Secret Role Assignment",
                desc: "Every player secretly views their role card. Imposters are given only the category (e.g. 'Animals'), while normal players receive the exact secret word (e.g. 'Lion').",
              },
              {
                step: "Phase 2",
                title: "Round-Robin Discussion",
                desc: "Players take turns in a fixed random speaking order giving exactly one clue. You may never say the secret word or any direct variant. Normal players should be clever; imposters must bluff.",
              },
              {
                step: "Phase 3",
                title: "Instant Accusation",
                desc: "At any moment during discussion, any player can press Accuse. The accused player's true role is immediately revealed! If they are an imposter, they are eliminated. If they are innocent, the accuser loses their accusation privilege.",
              },
              {
                step: "Phase 4",
                title: "Imposter Guess",
                desc: "At any time, an imposter can spend one of their guess attempts to guess the secret word. If correct, the imposters achieve an instant victory!",
              },
              {
                step: "Phase 5",
                title: "The Final Vote",
                desc: "If all discussion rounds finish without catching all imposters, the survivors vote together on one final accusation. Guessing wrong grants the imposters an immediate win.",
              },
            ].map((s, idx) => (
              <div
                key={idx}
                className="flex items-start gap-4 p-5 rounded-2xl bg-panel border border-line"
              >
                <span className="text-xs font-black px-2.5 py-1 rounded-md bg-crimson/20 border border-crimson/40 text-crimson-bright shrink-0 mt-0.5">
                  {s.step}
                </span>
                <div>
                  <h3 className="font-bold text-bone text-base mb-1">{s.title}</h3>
                  <p className="text-sm text-mute leading-relaxed">{s.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </section>
      </div>
    </div>
  );
}
