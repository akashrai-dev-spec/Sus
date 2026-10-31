import Link from "next/link";
import { ArrowLeft, Smartphone, Monitor, Download, ExternalLink, ShieldCheck } from "lucide-react";

export default function DownloadPage() {
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
        <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight mb-3">
          Get Sus for Any Device
        </h1>
        <p className="text-mute text-base sm:text-lg">
          Play in your browser with zero installation, or download standalone native binaries for
          Android and Linux desktop.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mb-12">
        {/* Android Card */}
        <div className="rounded-3xl bg-panel p-8 border border-line flex flex-col justify-between hover:border-crimson/50 transition-all">
          <div>
            <div className="h-12 w-12 rounded-2xl bg-crimson/15 border border-crimson/30 flex items-center justify-center text-crimson-bright mb-6">
              <Smartphone className="w-6 h-6" />
            </div>
            <h2 className="text-2xl font-black text-white mb-2">Android APK</h2>
            <p className="text-sm text-mute leading-relaxed mb-6">
              Install directly on any Android phone or tablet. Includes full tactile haptic feedback,
              offline pass-and-play, and seamless online multiplayer.
            </p>
            <div className="space-y-2 text-xs text-mute mb-8">
              <p>• Architecture: Universal ARM64 / ARMv7 / x86_64</p>
              <p>• Size: ~18MB (optimized split APK)</p>
              <p>• Android Version: 5.0 (Lollipop) or newer</p>
            </div>
          </div>

          <a
            href="https://github.com/akashrai-dev-spec/Sus/releases"
            target="_blank"
            rel="noreferrer"
            className="w-full py-4 rounded-xl bg-crimson hover:bg-crimson-bright text-white font-extrabold text-sm text-center shadow-lg shadow-crimson/30 flex items-center justify-center gap-2 transition-all button-press"
          >
            <Download className="w-4 h-4" />
            <span>Download Android APK</span>
          </a>
        </div>

        {/* Linux Desktop Card */}
        <div className="rounded-3xl bg-panel p-8 border border-line flex flex-col justify-between hover:border-crimson/50 transition-all">
          <div>
            <div className="h-12 w-12 rounded-2xl bg-white/5 border border-white/10 flex items-center justify-center text-bone mb-6">
              <Monitor className="w-6 h-6" />
            </div>
            <h2 className="text-2xl font-black text-white mb-2">Linux Desktop</h2>
            <p className="text-sm text-mute leading-relaxed mb-6">
              Optimized 64-bit native executable for Ubuntu, Debian, Arch, and Fedora. Bundles static
              Inter fonts and runs zero external network telemetry.
            </p>
            <div className="space-y-2 text-xs text-mute mb-8">
              <p>• Platform: Linux x86_64 (GTK3)</p>
              <p>• Release: Standalone executable bundle</p>
              <p>• Self-Hostable: Connects to any custom Socket.IO URL</p>
            </div>
          </div>

          <a
            href="https://github.com/akashrai-dev-spec/Sus/releases"
            target="_blank"
            rel="noreferrer"
            className="w-full py-4 rounded-xl bg-panel-dark border border-line hover:border-crimson text-bone font-extrabold text-sm text-center flex items-center justify-center gap-2 transition-all button-press"
          >
            <ExternalLink className="w-4 h-4 text-mute" />
            <span>View GitHub Releases</span>
          </a>
        </div>
      </div>

      <div className="rounded-2xl bg-ink-deep p-6 border border-line text-center max-w-xl mx-auto text-xs text-mute">
        <ShieldCheck className="w-5 h-5 text-emerald-400 mx-auto mb-2" />
        All releases are signed and built directly from our open-source GitHub monorepo.
      </div>
    </div>
  );
}
