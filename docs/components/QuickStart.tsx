'use client'

import { motion } from 'framer-motion'
import Card from './ui/Card'
import CopyButton from './ui/CopyButton'

const installOptions = [
  {
    title: 'One-Line Install',
    description: 'Fastest way to get started. Run this in PowerShell as Admin:',
    command: 'irm https://raw.githubusercontent.com/velocityeu/devbox-factory/main/Install-DevBox.ps1 | iex',
    note: 'Installs tools directly on your current machine',
    noteIcon: '&#128161;',
    featured: true,
    badge: '&#9889; Recommended',
  },
  {
    title: 'Full Bootstrap',
    description: 'Includes VM creation capabilities for team environments:',
    command: 'irm https://raw.githubusercontent.com/velocityeu/devbox-factory/main/Initialize-DevBox.ps1 | iex',
    note: 'Creates reproducible VM templates for your team',
    noteIcon: '&#127970;',
  },
  {
    title: 'Clone & Explore',
    description: 'Want to see the code first? Totally fair:',
    command: 'git clone https://github.com/velocityeu/devbox-factory && cd devbox-factory && .\\devbox install',
    note: 'Full source code. MIT licensed. Star us while you\'re there!',
    noteIcon: '&#128064;',
  },
]

const requirements = [
  { icon: '&#128187;', text: 'Windows 11 (22H2+) or Server 2025' },
  { icon: '&#128081;', text: 'Administrator privileges' },
  { icon: '&#127760;', text: 'Internet connection' },
  { icon: '&#128190;', text: '~15GB free disk space' },
]

export default function QuickStart() {
  return (
    <section id="quickstart" className="py-20 md:py-32 px-4 bg-background-secondary/50">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="text-center mb-12 md:mb-16"
        >
          <span className="inline-block px-4 py-1.5 mb-4 bg-white/5 border border-white/10 rounded-full text-sm text-accent-primary">
            Let&apos;s Go
          </span>
          <h2 className="text-2xl sm:text-3xl md:text-4xl font-extrabold mb-4">
            Ready in <span className="gradient-text">60 Seconds</span>
          </h2>
          <p className="text-zinc-400 max-w-xl mx-auto">
            No signup. No credit card. No BS. Just copy and paste.
          </p>
        </motion.div>

        {/* Install Options */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 md:gap-6 mb-12">
          {installOptions.map((option, index) => (
            <Card
              key={option.title}
              delay={index * 0.1}
              className={`${option.featured ? 'border-accent-primary bg-gradient-to-br from-accent-primary/10 to-transparent' : ''}`}
            >
              {option.badge && (
                <div
                  className="inline-block px-3 py-1 mb-4 bg-gradient-primary rounded-full text-xs font-bold"
                  dangerouslySetInnerHTML={{ __html: option.badge }}
                />
              )}
              <h3 className="text-lg font-bold mb-2">{option.title}</h3>
              <p className="text-zinc-400 text-sm mb-4">{option.description}</p>

              {/* Code Block */}
              <div className="flex items-center gap-2 p-3 bg-background rounded-xl border border-white/10 mb-4 overflow-hidden">
                <code className="flex-1 text-xs text-accent-cyan font-mono overflow-x-auto whitespace-nowrap">
                  {option.command}
                </code>
                <CopyButton text={option.command} />
              </div>

              <div className="flex items-center gap-2 text-sm text-zinc-500">
                <span dangerouslySetInnerHTML={{ __html: option.noteIcon }} />
                <span>{option.note}</span>
              </div>
            </Card>
          ))}
        </div>

        {/* Requirements */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="glass-card p-6 md:p-8"
        >
          <h4 className="text-lg font-bold mb-6">&#128203; System Requirements</h4>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {requirements.map((req) => (
              <div key={req.text} className="flex items-center gap-3 text-zinc-400">
                <span className="text-xl" dangerouslySetInnerHTML={{ __html: req.icon }} />
                <span className="text-sm">{req.text}</span>
              </div>
            ))}
          </div>
        </motion.div>
      </div>
    </section>
  )
}
