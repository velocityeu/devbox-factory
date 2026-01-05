'use client'

import { motion } from 'framer-motion'
import Card from './ui/Card'

const features = [
  {
    icon: '&#129302;',
    title: 'AI Coding Tools',
    items: ['Claude Code CLI (fully configured)', 'Cursor IDE', 'GitHub Copilot', 'Continue & Cline extensions', 'VS Code AI workspace ready'],
  },
  {
    icon: '&#9881;&#65039;',
    title: 'Dev Essentials',
    items: ['Git (configured correctly)', 'Windows Terminal', 'PowerShell 7', 'VS Code + extensions', 'SSH keys ready'],
  },
  {
    icon: '&#128230;',
    title: 'Runtimes & Package Managers',
    items: ['Node.js via NVM (multiple versions)', 'Python 3.12', 'npm, pnpm, yarn, bun', '.NET SDK 8', 'All PATH issues solved'],
  },
  {
    icon: '&#128051;',
    title: 'Containers & Databases',
    items: ['WSL2 (properly configured)', 'Docker Desktop', 'PostgreSQL 16', 'MongoDB & Redis', 'Everything networked correctly'],
  },
  {
    icon: '&#9729;&#65039;',
    title: 'Cloud & DevOps',
    items: ['Azure CLI & Functions', 'Terraform & Bicep', 'Azure Data Studio', 'Storage Explorer', 'Ready for deployment'],
  },
  {
    icon: '&#127899;&#65039;',
    title: 'Windows Optimized',
    items: ['Bloatware removed', 'Privacy optimized', 'Dev-focused settings', 'Performance tuned', 'Clean, fast environment'],
  },
]

export default function Features() {
  return (
    <section id="features" className="py-20 md:py-32 px-4">
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
            Everything You Need
          </span>
          <h2 className="text-2xl sm:text-3xl md:text-4xl font-extrabold mb-4">
            Built for <span className="gradient-text">AI-Powered Development</span>
          </h2>
          <p className="text-zinc-400 max-w-xl mx-auto">
            Every tool, extension, and configuration that modern vibe coders actually use.
            Pre-installed. Pre-configured. Pre-tested together.
          </p>
        </motion.div>

        {/* Features Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 md:gap-6 mb-12">
          {features.map((feature, index) => (
            <Card key={feature.title} delay={index * 0.1}>
              <div
                className="text-3xl md:text-4xl mb-4"
                dangerouslySetInnerHTML={{ __html: feature.icon }}
              />
              <h3 className="text-lg font-bold mb-4">{feature.title}</h3>
              <ul className="space-y-2">
                {feature.items.map((item) => (
                  <li key={item} className="flex items-start gap-2 text-sm text-zinc-400">
                    <span className="text-green-400 mt-0.5">&#10003;</span>
                    <span>{item}</span>
                  </li>
                ))}
              </ul>
            </Card>
          ))}
        </div>

        {/* Template Highlight */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="glass-card p-6 md:p-10 text-center bg-gradient-to-br from-accent-primary/10 to-accent-cyan/10 border-accent-primary/30"
        >
          <h3 className="text-xl md:text-2xl font-bold mb-4">
            &#127919; The Secret Sauce: Template-Based Cloning
          </h3>
          <p className="text-zinc-400 max-w-2xl mx-auto mb-8">
            Create a perfect template once (~60 min). Clone identical VMs in 2-3 minutes, forever.
            Every team member gets <em className="text-accent-cyan not-italic font-semibold">exactly</em> the same environment. No drift. No surprises. No &quot;works on my machine.&quot;
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4 sm:gap-8">
            <div className="text-center">
              <span className="block text-3xl md:text-4xl font-extrabold gradient-text">1x</span>
              <span className="text-sm text-zinc-500">Template creation</span>
            </div>
            <span className="text-2xl text-accent-primary hidden sm:block">&#8594;</span>
            <span className="text-2xl text-accent-primary sm:hidden">&#8595;</span>
            <div className="text-center">
              <span className="block text-3xl md:text-4xl font-extrabold gradient-text">&#8734;</span>
              <span className="text-sm text-zinc-500">Identical VMs</span>
            </div>
            <span className="text-2xl text-accent-primary hidden sm:block">&#8594;</span>
            <span className="text-2xl text-accent-primary sm:hidden">&#8595;</span>
            <div className="text-center">
              <span className="block text-3xl md:text-4xl font-extrabold gradient-text">0</span>
              <span className="text-sm text-zinc-500">Setup headaches</span>
            </div>
          </div>
        </motion.div>
      </div>
    </section>
  )
}
