'use client'

import { motion } from 'framer-motion'
import Card from './ui/Card'

const profiles = [
  {
    id: 'ai',
    icon: '&#129302;',
    title: 'AI Coder',
    description: 'For vibe coders using Claude, Cursor, and AI-powered development',
    tools: ['Claude Code CLI', 'Cursor IDE', 'VS Code + AI Extensions', 'Node.js & Python', 'Git & Terminal'],
    time: '~15 min install',
    badge: '&#128293; Most Popular',
    featured: true,
  },
  {
    id: 'web',
    icon: '&#127760;',
    title: 'Web Developer',
    description: 'Full-stack web development with modern tooling',
    tools: ['Node.js & multiple package managers', 'Python 3.12', 'Docker Desktop', 'PostgreSQL, MongoDB, Redis', 'VS Code configured'],
    time: '~25 min install',
  },
  {
    id: 'azure',
    icon: '&#9729;&#65039;',
    title: 'Azure Developer',
    description: 'Cloud-native development on Microsoft Azure',
    tools: ['Azure CLI & Functions', '.NET SDK 8', 'Terraform & Bicep', 'Azure Data Studio', 'Storage Explorer'],
    time: '~20 min install',
  },
  {
    id: 'full',
    icon: '&#128640;',
    title: 'Full Stack',
    description: 'Everything included. The ultimate dev environment.',
    tools: ['All AI coding tools', 'All runtimes & databases', 'Docker & containers', 'Azure & cloud tools', 'Every extension'],
    time: '~45 min install',
    badge: '&#128170; Complete',
  },
  {
    id: 'minimal',
    icon: '&#127919;',
    title: 'Minimal',
    description: 'Just the essentials. Light and fast.',
    tools: ['Git', 'Windows Terminal', 'VS Code', 'PowerShell 7', "That's it!"],
    time: '~5 min install',
  },
]

export default function Profiles() {
  return (
    <section id="profiles" className="py-20 md:py-32 px-4 bg-background-secondary/50">
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
            Choose Your Path
          </span>
          <h2 className="text-2xl sm:text-3xl md:text-4xl font-extrabold mb-4">
            Profiles for Every <span className="gradient-text">Type of Builder</span>
          </h2>
          <p className="text-zinc-400 max-w-xl mx-auto">
            Not everyone needs everything. Pick the profile that matches your vibe.
          </p>
        </motion.div>

        {/* Profiles Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 md:gap-6">
          {profiles.map((profile, index) => (
            <Card
              key={profile.id}
              delay={index * 0.1}
              className={`relative text-center ${
                profile.featured ? 'border-accent-primary/50 bg-gradient-to-br from-accent-primary/10 to-transparent' : ''
              }`}
            >
              {profile.badge && (
                <div
                  className={`absolute -top-3 left-1/2 -translate-x-1/2 px-3 py-1 rounded-full text-xs font-bold whitespace-nowrap ${
                    profile.featured
                      ? 'bg-gradient-to-r from-orange-500 to-red-500'
                      : 'bg-gradient-primary'
                  }`}
                  dangerouslySetInnerHTML={{ __html: profile.badge }}
                />
              )}

              <div
                className="text-4xl md:text-5xl mb-4"
                dangerouslySetInnerHTML={{ __html: profile.icon }}
              />
              <h3 className="text-xl font-bold mb-2">{profile.title}</h3>
              <p className="text-zinc-400 text-sm mb-5">{profile.description}</p>

              <ul className="text-left space-y-2 mb-5">
                {profile.tools.map((tool) => (
                  <li key={tool} className="flex items-center gap-2 text-sm text-zinc-400">
                    <span className="text-accent-primary">&#8226;</span>
                    {tool}
                  </li>
                ))}
              </ul>

              <div className="flex items-center justify-center gap-2 pt-4 border-t border-white/10 text-zinc-500 text-sm">
                <span>&#9201;&#65039;</span>
                <span>{profile.time}</span>
              </div>
            </Card>
          ))}
        </div>
      </div>
    </section>
  )
}
