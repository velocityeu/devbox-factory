'use client'

import { motion } from 'framer-motion'
import Card from './ui/Card'

const features = [
  {
    title: 'AI Coding Tools',
    items: ['Claude Code CLI', 'Cursor IDE', 'GitHub Copilot', 'VS Code AI extensions'],
  },
  {
    title: 'Dev Essentials',
    items: ['Git configured', 'Windows Terminal', 'PowerShell 7', 'SSH keys ready'],
  },
  {
    title: 'Runtimes',
    items: ['Node.js via NVM', 'Python 3.12', 'npm, pnpm, yarn', '.NET SDK 8'],
  },
  {
    title: 'Containers',
    items: ['WSL2 configured', 'Docker Desktop', 'PostgreSQL 16', 'MongoDB & Redis'],
  },
  {
    title: 'Cloud Tools',
    items: ['Azure CLI', 'Terraform', 'Azure Data Studio', 'Storage Explorer'],
  },
  {
    title: 'Windows Optimized',
    items: ['Bloatware removed', 'Privacy tuned', 'Performance optimized', 'Dev-focused'],
  },
]

export default function Features() {
  return (
    <section id="features" className="py-24 md:py-32 px-5">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="text-center mb-16"
        >
          <span className="section-badge mb-4">Everything Included</span>
          <h2 className="text-display text-primary mb-4">
            Built for <span className="gradient-text">modern development</span>
          </h2>
          <p className="text-secondary max-w-xl mx-auto">
            Every tool you need. Pre-installed. Pre-configured. Pre-tested together.
          </p>
        </motion.div>

        {/* Features Grid */}
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4 mb-16">
          {features.map((feature, index) => (
            <Card key={feature.title} delay={index * 0.05}>
              <h3 className="text-lg font-semibold text-primary mb-4">{feature.title}</h3>
              <ul className="space-y-2">
                {feature.items.map((item) => (
                  <li key={item} className="flex items-center gap-2 text-sm text-secondary">
                    <svg className="w-4 h-4 text-emerald-500 shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                      <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
                    </svg>
                    {item}
                  </li>
                ))}
              </ul>
            </Card>
          ))}
        </div>

        {/* Template Highlight */}
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="card p-8 md:p-12 text-center border-[var(--color-accent)]/20"
        >
          <h3 className="text-title text-primary mb-4">
            Template-Based Cloning
          </h3>
          <p className="text-secondary max-w-2xl mx-auto mb-8">
            Create a perfect template once. Clone identical environments in 2-3 minutes, forever.
            Every team member gets <span className="text-accent font-medium">exactly</span> the same setup.
          </p>
          <div className="flex flex-wrap items-center justify-center gap-6 md:gap-10">
            {[
              { value: '1x', label: 'Template creation' },
              { value: '∞', label: 'Identical clones' },
              { value: '0', label: 'Setup headaches' },
            ].map((stat, i) => (
              <div key={stat.label} className="flex items-center gap-4">
                <div className="text-center">
                  <span className="block text-3xl md:text-4xl font-semibold text-primary">{stat.value}</span>
                  <span className="text-xs text-tertiary">{stat.label}</span>
                </div>
                {i < 2 && <span className="text-tertiary hidden md:block">→</span>}
              </div>
            ))}
          </div>
        </motion.div>
      </div>
    </section>
  )
}
