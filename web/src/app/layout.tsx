import type { Metadata } from "next";
import { Inter } from "next/font/google";
import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import "./globals.css";

const inter = Inter({
  subsets: ["latin"],
  variable: "--font-inter",
  display: "swap",
});

export const metadata: Metadata = {
  title: "Sus — One word. One imposter.",
  description:
    "A tense, dark minimalist social deduction party game for 3 to 12 players. One secret word. One imposter trying to blend in.",
  keywords: [
    "social deduction",
    "party game",
    "imposter",
    "word game",
    "multiplayer",
    "online board game",
    "pass and play",
  ],
  authors: [{ name: "Akash Rai" }, { name: "Aaryan Banskota" }],
  icons: {
    icon: "/mask.svg",
    apple: "/mask.svg",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className={inter.variable}>
      <body className="min-h-screen bg-ink-deep text-bone flex flex-col antialiased selection:bg-crimson selection:text-white">
        <Navbar />
        <main className="flex-1 flex flex-col">{children}</main>
        <Footer />
      </body>
    </html>
  );
}
