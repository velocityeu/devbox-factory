import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'
import { ThemeProvider } from '@/components/ThemeProvider'

const inter = Inter({
  subsets: ['latin'],
  variable: '--font-inter',
  display: 'swap',
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
    <html lang="en" className={inter.variable} suppressHydrationWarning>
      <head>
        {/* Prevent flash of wrong theme */}
        <script
          dangerouslySetInnerHTML={{
            __html: `
              (function() {
                try {
                  var theme = localStorage.getItem('theme');
                  if (theme === 'dark' || (!theme && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
                    document.documentElement.classList.add('dark');
                  }
                } catch (e) {}
              })();
            `,
          }}
        />
      </head>
      <body className="font-sans antialiased">
        <ThemeProvider>
          {/* Subtle background gradient */}
          <div className="fixed inset-0 -z-10 bg-secondary" />
          <div className="fixed inset-0 -z-10 bg-gradient-to-b from-transparent via-transparent to-[var(--color-bg-secondary)] opacity-50" />

          {/* Subtle animated orbs - only in dark mode */}
          <div className="fixed -z-10 w-[500px] h-[500px] -top-32 -right-32 rounded-full bg-primary-500/5 dark:bg-primary-500/10 blur-3xl animate-float pointer-events-none" />
          <div className="fixed -z-10 w-[400px] h-[400px] top-1/2 -left-32 rounded-full bg-purple-500/5 dark:bg-purple-500/10 blur-3xl animate-float pointer-events-none" style={{ animationDelay: '-10s' }} />

          {children}
        </ThemeProvider>
      </body>
    </html>
  )
}
