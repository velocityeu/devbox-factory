'use client'

import { motion } from 'framer-motion'
import Button from './ui/Button'
import Terminal, { TerminalLine, TerminalOutput } from './ui/Terminal'

export default function Hero() {
  return (
    <header className="min-h-screen flex flex-col justify-center items-center px-4 pt-20 pb-16 md:pt-24">
      <div className="max-w-4xl mx-auto text-center">
        {/* Badge */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="inline-flex items-center gap-2 px-4 py-2 mb-6 bg-white/5 border border-white/10 rounded-full text-sm"
        >
          <span>&#128293;</span>
          <span className="text-zinc-400">Built for Vibe Coders</span>
          <span className="px-2 py-0.5 bg-gradient-primary rounded-full text-xs font-semibold">v3.5</span>
        </motion.div>

        {/* Title */}
        <motion.h1
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.1 }}
          className="text-3xl sm:text-4xl md:text-5xl lg:text-6xl font-extrabold leading-tight mb-6"
        >
          Stop Watching Tutorials.
          <br />
          <span className="gradient-text">Start Shipping Code.</span>
        </motion.h1>

        {/* Subtitle */}
        <motion.p
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.2 }}
          className="text-base md:text-lg text-zinc-400 max-w-2xl mx-auto mb-4"
        >
          You&apos;ve watched 47 YouTube videos on setting up Claude Code. Read 23 conflicting articles.
          Spent 3 days debugging PATH issues. <strong className="text-white">Sound familiar?</strong>
        </motion.p>

        {/* Highlight */}
        <motion.p
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.3 }}
          className="flex items-center justify-center gap-2 text-lg md:text-xl text-accent-cyan mb-8"
        >
          <span className="text-2xl">&#9889;</span>
          One command. 2 minutes. Perfect dev environment. <em className="not-italic font-semibold text-white">Every. Single. Time.</em>
        </motion.p>

        {/* CTA Buttons */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.4 }}
          className="flex flex-col sm:flex-row gap-4 justify-center mb-12"
        >
          <Button href="#quickstart" variant="primary" size="large" glow>
            <span>&#128640;</span>
            Get Started Now
          </Button>
          <Button href="#demo" variant="secondary" size="large">
            <span>&#9654;&#65039;</span>
            Watch Demo
          </Button>
        </motion.div>

        {/* Stats */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5, delay: 0.5 }}
          className="flex flex-col sm:flex-row items-center justify-center gap-6 sm:gap-8 mb-12"
        >
          <div className="text-center">
            <span className="block text-3xl md:text-4xl font-extrabold gradient-text">2-3</span>
            <span className="text-sm text-zinc-500">Minutes to code</span>
          </div>
          <div className="hidden sm:block w-px h-10 bg-white/10" />
          <div className="text-center">
            <span className="block text-3xl md:text-4xl font-extrabold gradient-text">20+</span>
            <span className="text-sm text-zinc-500">Tools pre-configured</span>
          </div>
          <div className="hidden sm:block w-px h-10 bg-white/10" />
          <div className="text-center">
            <span className="block text-3xl md:text-4xl font-extrabold gradient-text">100%</span>
            <span className="text-sm text-zinc-500">Reproducible</span>
          </div>
        </motion.div>
      </div>

      {/* Terminal */}
      <motion.div
        initial={{ opacity: 0, y: 30 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.6, delay: 0.5 }}
        className="w-full max-w-2xl mx-auto"
      >
        <Terminal>
          <TerminalLine command="irm devbox.run | iex" />
          <TerminalOutput
            lines={[
              { text: 'Checking system requirements...', type: 'success', icon: '✓' },
              { text: 'Downloading DevBox Factory v3.5...', type: 'success', icon: '✓' },
              { text: 'Installing Claude Code CLI...', type: 'success', icon: '✓' },
              { text: 'Configuring VS Code + AI extensions...', type: 'success', icon: '✓' },
              { text: 'Setting up Node.js, Python, Docker...', type: 'success', icon: '✓' },
              { text: '✨ Ready to vibe code in 2 minutes!', type: 'highlight' },
            ]}
          />
        </Terminal>
      </motion.div>

      {/* Scroll indicator */}
      <motion.a
        href="#problem"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.5, delay: 1 }}
        className="absolute bottom-8 left-1/2 -translate-x-1/2 flex flex-col items-center gap-2 text-zinc-500 text-sm hover:text-white transition-colors"
      >
        <span>Scroll to learn more</span>
        <motion.span
          animate={{ y: [0, 8, 0] }}
          transition={{ duration: 2, repeat: Infinity }}
          className="text-xl"
        >
          &#8595;
        </motion.span>
      </motion.a>
    </header>
  )
}
