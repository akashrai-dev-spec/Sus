import Link from "next/link";
import { ArrowLeft, BookOpen, CheckCircle, Flame, RefreshCw, ShieldAlert, Users } from "lucide-react";

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
          <span>Game Guide</span>
        </div>
        <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight mb-3">
          How to Play Sus
        </h1>
        <p className="text-mute text-base sm:text-lg">
          Give clues, spot fakes, and catch the imposter before they guess the word.
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
                You get the secret word and its category. Give clues that prove to other players
                you know the word, without giving it away to the imposter. Unmask the imposter to win.
              </p>
            </div>
            <div className="rounded-2xl bg-ink-deep p-6 border border-crimson/40">
              <div className="flex items-center gap-2 text-crimson-bright font-bold text-base mb-2">
                <Flame className="w-5 h-5" />
                <span>The Imposter</span>
              </div>
              <p className="text-sm text-mute leading-relaxed">
                You only see the category, not the secret word. Listen to everyone&apos;s clues, bluff
                when it is your turn, and try to guess the secret word. Guessing the word wins immediately.
              </p>
            </div>
          </div>
        </section>

        {/* 5 Stages */}
        <section>
          <h2 className="text-2xl font-black text-white mb-6">Round Progression</h2>
          <div className="space-y-4">
            {[
              {
                step: "Step 1",
                title: "Secret Role Assignment",
                desc: "Each player views their private role card. Normal players receive the exact secret word and category. The imposter sees only the category.",
              },
              {
                step: "Step 2",
                title: "Turn-by-Turn Clues",
                desc: "Players speak in order, giving one short clue each round. You cannot say the secret word or any direct form of it. Normal players stay subtle, while the imposter bluffs.",
              },
              {
                step: "Step 3",
                title: "Accusations",
                desc: "During discussion, any player can tap Accuse. The game reveals whether the accused player is innocent or the imposter. Catch the imposter and normal players win. Accuse an innocent player and you lose your accusation.",
              },
              {
                step: "Step 4",
                title: "Imposter Guess",
                desc: "The imposter can guess the secret word at any point during discussion. Guesses are flexible: capitalization, extra spaces, punctuation, and words like 'a', 'an', or 'the' do not matter. Guessing right wins on the spot.",
              },
              {
                step: "Step 5",
                title: "Final Vote",
                desc: "If all discussion rounds end and the imposter is still in the game, everyone votes on a final suspect. A wrong vote hands victory to the imposter.",
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

        {/* Special Rules */}
        <section className="space-y-6">
          <h2 className="text-2xl font-black text-white mb-4">Special Rules & Controls</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="rounded-2xl bg-panel p-6 border border-line">
              <div className="flex items-center gap-2 text-bone font-bold text-base mb-2">
                <RefreshCw className="w-5 h-5 text-crimson-bright" />
                <span>3-Player Role Reversal</span>
              </div>
              <p className="text-sm text-mute leading-relaxed">
                In 3-player games, if an innocent player is wrongly accused, they are not eliminated.
                Instead, roles reverse: the game chooses a new imposter and a new secret word.
                Every player gets a pop-up showing their new role, and discussion restarts from the player
                who made the accusation.
              </p>
            </div>

            <div className="rounded-2xl bg-panel p-6 border border-line">
              <div className="flex items-center gap-2 text-bone font-bold text-base mb-2">
                <Users className="w-5 h-5 text-emerald-400" />
                <span>Minimum Players & Fair Play</span>
              </div>
              <p className="text-sm text-mute leading-relaxed">
                A match requires at least 3 players. If someone disconnects or leaves mid-game and the group
                drops below 3, the match pauses and returns everyone to the lobby so another player can join.
                Room hosts also have buttons to kick or ban unwanted players from the lobby.
              </p>
            </div>
          </div>
        </section>
      </div>
    </div>
  );
}
