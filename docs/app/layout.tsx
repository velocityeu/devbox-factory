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
          {/* Clean, minimal background */}
          <div className="fixed inset-0 -z-10 bg-[var(--color-bg)]" />
          {children}
        </ThemeProvider>
      </body>
    </html>
  )
}
