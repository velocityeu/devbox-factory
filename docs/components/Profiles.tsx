'use client'

import { motion } from 'framer-motion'
import Card from './ui/Card'

const profiles = [
  {
    title: 'AI Coder',
    desc: 'Claude, Cursor, AI-powered dev',
    tools: ['Claude Code CLI', 'Cursor IDE', 'VS Code + AI', 'Node.js & Python'],
    time: '~15 min',
    featured: true,
  },
  {
    title: 'Web Developer',
    desc: 'Full-stack web development',
    tools: ['Node.js & package managers', 'Python 3.12', 'Docker Desktop', 'Databases'],
    time: '~25 min',
  },
  {
    title: 'Azure Developer',
    desc: 'Cloud-native on Azure',
    tools: ['Azure CLI & Functions', '.NET SDK 8', 'Terraform & Bicep', 'Azure Data Studio'],
    time: '~20 min',
  },
  {
    title: 'Full Stack',
    desc: 'Everything included',
    tools: ['All AI tools', 'All runtimes', 'Docker & DBs', 'Cloud tools'],
    time: '~45 min',
  },
  {
    title: 'Minimal',
    desc: 'Just the essentials',
    tools: ['Git', 'Terminal', 'VS Code', 'PowerShell 7'],
    time: '~5 min',
  },
]

export default function Profiles() {
  return (
    <section id="profiles" className="py-24 md:py-32 px-5 bg-secondary">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="text-center mb-16"
        >
          <span className="section-badge mb-4">Choose Your Path</span>
          <h2 className="text-display text-primary mb-4">
            Profiles for every <span className="gradient-text">builder</span>
          </h2>
          <p className="text-secondary max-w-xl mx-auto">
            Not everyone needs everything. Pick the profile that matches your work.
          </p>
        </motion.div>

        {/* Profiles Grid */}
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-4">
          {profiles.map((profile, index) => (
            <Card
              key={profile.title}
              delay={index * 0.05}
              className={`text-center ${profile.featured ? 'border-[var(--color-accent)]/30 ring-1 ring-[var(--color-accent)]/10' : ''}`}
            >
              {profile.featured && (
                <span className="inline-block px-3 py-1 mb-3 bg-[var(--color-accent)] text-white text-xs font-medium rounded-full">
                  Popular
                </span>
              )}
              <h3 className="font-semibold text-primary mb-1">{profile.title}</h3>
              <p className="text-tertiary text-xs mb-4">{profile.desc}</p>
              <ul className="text-left space-y-1.5 mb-4">
                {profile.tools.map((tool) => (
                  <li key={tool} className="flex items-center gap-2 text-xs text-secondary">
                    <span className="w-1 h-1 rounded-full bg-[var(--color-accent)]" />
                    {tool}
                  </li>
                ))}
              </ul>
              <div className="pt-3 border-t border-[var(--color-border-light)] text-xs text-tertiary">
                {profile.time}
              </div>
            </Card>
          ))}
        </div>
      </div>
    </section>
  )
}
