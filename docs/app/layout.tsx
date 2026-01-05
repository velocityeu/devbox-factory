import type { Metadata } from 'next'
import { Inter, JetBrains_Mono } from 'next/font/google'
import './globals.css'

const inter = Inter({
  subsets: ['latin'],
  variable: '--font-inter',
})

const jetbrainsMono = JetBrains_Mono({
  subsets: ['latin'],
  variable: '--font-mono',
})

export const metadata: Metadata = {
  title: 'DevBox Factory - Vibe Code in 2 Minutes, Not 2 Days',
  description: 'Stop wasting days on dev environment setup. Get identical, production-ready dev environments in 2 minutes. Perfect for Claude Code, Cursor, and AI-powered vibe coding.',
  keywords: 'vibe coding, Claude Code, Cursor IDE, AI coding, development environment, Windows dev setup, DevBox, automated setup',
  authors: [{ name: 'Velocity EU' }],
  openGraph: {
    type: 'website',
    title: 'DevBox Factory - Vibe Code in 2 Minutes, Not 2 Days',
    description: 'The missing piece every AI coder needs. One command. Perfect dev environment. Every time.',
    siteName: 'DevBox Factory',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'DevBox Factory - Vibe Code in 2 Minutes',
    description: 'Stop wrestling with environment setup. Start shipping code.',
  },
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en" className={`${inter.variable} ${jetbrainsMono.variable}`}>
      <body className="font-sans">
        {/* Background effects */}
        <div className="fixed inset-0 -z-30 bg-gradient-to-b from-background-secondary to-background" />
        <div className="fixed inset-0 -z-20 bg-grid opacity-50" />

        {/* Floating glow orbs */}
        <div className="fixed -z-10 w-[600px] h-[600px] -top-48 -right-24 rounded-full bg-accent-primary/20 blur-[100px] animate-float" />
        <div className="fixed -z-10 w-[400px] h-[400px] bottom-1/4 -left-24 rounded-full bg-accent-cyan/20 blur-[100px] animate-float" style={{ animationDelay: '-7s' }} />
        <div className="fixed -z-10 w-[500px] h-[500px] -bottom-48 right-1/4 rounded-full bg-accent-secondary/20 blur-[100px] animate-float" style={{ animationDelay: '-14s' }} />

        {children}
      </body>
    </html>
  )
}
