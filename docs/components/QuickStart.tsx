'use client'

import { motion } from 'framer-motion'
import Card from './ui/Card'
import CopyButton from './ui/CopyButton'

const options = [
  {
    title: 'One-Line Install',
    desc: 'Run in PowerShell as Admin:',
    cmd: 'irm https://raw.githubusercontent.com/velocityeu/devbox-factory/main/Install-DevBox.ps1 | iex',
    note: 'Installs on current machine',
    featured: true,
  },
  {
    title: 'Full Bootstrap',
    desc: 'With VM template creation:',
    cmd: 'irm https://raw.githubusercontent.com/velocityeu/devbox-factory/main/Initialize-DevBox.ps1 | iex',
    note: 'For team environments',
  },
  {
    title: 'Clone & Explore',
    desc: 'See the code first:',
    cmd: 'git clone https://github.com/velocityeu/devbox-factory && cd devbox-factory && .\\devbox install',
    note: 'MIT licensed',
  },
]

export default function QuickStart() {
  return (
    <section id="quickstart" className="py-24 md:py-32 px-5 bg-secondary">
      <div className="max-w-5xl mx-auto">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="text-center mb-16"
        >
          <span className="section-badge mb-4">Get Started</span>
          <h2 className="text-display text-primary mb-4">
            Ready in <span className="gradient-text">60 seconds</span>
          </h2>
          <p className="text-secondary">No signup. No credit card. Just copy and paste.</p>
        </motion.div>

        {/* Options */}
        <div className="grid md:grid-cols-3 gap-4 mb-12">
          {options.map((opt, i) => (
            <Card
              key={opt.title}
              delay={i * 0.1}
              padding="lg"
              className={opt.featured ? 'border-[var(--color-accent)]/30 ring-1 ring-[var(--color-accent)]/10' : ''}
            >
              {opt.featured && (
                <span className="inline-block px-2 py-1 mb-3 bg-[var(--color-accent)] text-white text-xs font-medium rounded">
                  Recommended
                </span>
              )}
              <h3 className="font-semibold text-primary mb-1">{opt.title}</h3>
              <p className="text-tertiary text-sm mb-4">{opt.desc}</p>

              <div className="flex items-center gap-2 p-3 bg-gray-900 rounded-lg mb-3">
                <code className="flex-1 text-xs text-[var(--color-accent)] font-mono overflow-x-auto whitespace-nowrap">
                  {opt.cmd}
                </code>
                <CopyButton text={opt.cmd} />
              </div>

              <p className="text-xs text-tertiary">{opt.note}</p>
            </Card>
          ))}
        </div>

        {/* Requirements */}
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="card p-6"
        >
          <h4 className="font-semibold text-primary mb-4">Requirements</h4>
          <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {[
              { text: 'Windows 11 or Server 2025' },
              { text: 'Admin privileges' },
              { text: 'Internet connection' },
              { text: '~15GB free space' },
            ].map((req) => (
              <div key={req.text} className="flex items-center gap-3 text-secondary text-sm">
                <svg className="w-4 h-4 text-emerald-500 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                </svg>
                <span>{req.text}</span>
              </div>
            ))}
          </div>
        </motion.div>
      </div>
    </section>
  )
}
