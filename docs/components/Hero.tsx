'use client'

import { motion } from 'framer-motion'
import Button from './ui/Button'
import Terminal, { TerminalLine, TerminalOutput } from './ui/Terminal'

export default function Hero() {
  return (
    <header className="min-h-screen flex flex-col justify-center items-center px-5 pt-24 pb-20">
      <div className="max-w-4xl mx-auto text-center">
        {/* Badge */}
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="section-badge mb-6"
        >
          <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
          <span>Built for AI-powered development</span>
        </motion.div>

        {/* Title */}
        <motion.h1
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.1 }}
          className="text-display-lg md:text-display-xl text-primary mb-6"
        >
          Stop watching tutorials.
          <br />
          <span className="gradient-text">Start shipping code.</span>
        </motion.h1>

        {/* Subtitle */}
        <motion.p
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.2 }}
          className="text-lg md:text-xl text-secondary max-w-2xl mx-auto mb-4 leading-relaxed"
        >
          You&apos;ve spent days configuring your dev environment.
          Reading conflicting guides. Debugging PATH issues.
          <strong className="text-primary font-medium"> Sound familiar?</strong>
        </motion.p>

        {/* Highlight */}
        <motion.p
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.3 }}
          className="text-lg text-accent font-medium mb-10"
        >
          One command. 2 minutes. Perfect dev environment.
          <em className="not-italic text-primary"> Every time.</em>
        </motion.p>

        {/* CTA Buttons */}
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.4 }}
          className="flex flex-col sm:flex-row gap-4 justify-center mb-16"
        >
          <Button href="#quickstart" variant="primary" size="lg">
            Get Started
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M13 7l5 5m0 0l-5 5m5-5H6" />
            </svg>
          </Button>
          <Button href="#demo" variant="secondary" size="lg">
            See how it works
          </Button>
        </motion.div>

        {/* Stats */}
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.5 }}
          className="flex flex-col sm:flex-row items-center justify-center gap-8 sm:gap-12 mb-16"
        >
          {[
            { value: '2-3', label: 'Minutes to code' },
            { value: '20+', label: 'Tools configured' },
            { value: '100%', label: 'Reproducible' },
          ].map((stat, i) => (
            <div key={stat.label} className="text-center">
              <span className="block text-4xl md:text-5xl font-semibold text-primary tracking-tight">
                {stat.value}
              </span>
              <span className="text-sm text-tertiary">{stat.label}</span>
              {i < 2 && <div className="hidden sm:block absolute right-0 top-1/2 -translate-y-1/2 w-px h-8 bg-[var(--color-border-light)]" />}
            </div>
          ))}
        </motion.div>
      </div>

      {/* Terminal */}
      <motion.div
        initial={{ opacity: 0, y: 24 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.5 }}
        className="w-full max-w-2xl mx-auto"
      >
        <Terminal title="PowerShell">
          <TerminalLine command="irm devbox.run | iex" />
          <TerminalOutput
            lines={[
              { text: 'Checking system requirements...', type: 'success', icon: '✓' },
              { text: 'Downloading DevBox Factory v3.5...', type: 'success', icon: '✓' },
              { text: 'Installing Claude Code CLI...', type: 'success', icon: '✓' },
              { text: 'Configuring VS Code + extensions...', type: 'success', icon: '✓' },
              { text: 'Setting up Node.js, Python, Docker...', type: 'success', icon: '✓' },
              { text: 'Ready to vibe code in 2 minutes!', type: 'highlight' },
            ]}
          />
        </Terminal>
      </motion.div>

      {/* Scroll indicator */}
      <motion.a
        href="#problem"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.5, delay: 1.2 }}
        className="mt-16 flex flex-col items-center gap-2 text-tertiary text-sm hover:text-secondary transition-colors"
      >
        <span>Learn more</span>
        <motion.div
          animate={{ y: [0, 6, 0] }}
          transition={{ duration: 1.5, repeat: Infinity, ease: 'easeInOut' }}
        >
          <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M19 14l-7 7m0 0l-7-7m7 7V3" />
          </svg>
        </motion.div>
      </motion.a>
    </header>
  )
}
