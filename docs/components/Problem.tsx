'use client'

import { motion } from 'framer-motion'
import Card from './ui/Card'

const problems = [
  {
    num: '01',
    title: 'Tutorial Hell',
    description: '"Just follow these 47 steps..." Three hours later, you\'re debugging why npm won\'t work.',
  },
  {
    num: '02',
    title: 'Conflicting Advice',
    description: 'NVM? Volta? Direct install? Every guide says something different. All outdated.',
  },
  {
    num: '03',
    title: 'Works on My Machine',
    description: 'Your teammate\'s code runs perfectly. On your machine? Cryptic errors everywhere.',
  },
  {
    num: '04',
    title: 'Time Vampire',
    description: 'You wanted to build something cool. Instead, you spent 6 hours on WSL2 config.',
  },
  {
    num: '05',
    title: 'Missing Context',
    description: 'Every tutorial assumes you know that ONE thing they didn\'t mention.',
  },
  {
    num: '06',
    title: 'Motivation Killer',
    description: 'You were excited to build. Now you\'re questioning life choices.',
  },
]

export default function Problem() {
  return (
    <section id="problem" className="py-24 md:py-32 px-5">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="text-center mb-16"
        >
          <span className="section-badge mb-4">The Reality</span>
          <h2 className="text-display text-primary mb-4">
            We&apos;ve all been there. <span className="gradient-text">It sucks.</span>
          </h2>
        </motion.div>

        {/* Problem Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-16">
          {problems.map((problem, index) => (
            <Card key={problem.title} delay={index * 0.05}>
              <span className="text-xs font-mono text-tertiary mb-3 block">{problem.num}</span>
              <h3 className="text-lg font-semibold text-primary mb-2">{problem.title}</h3>
              <p className="text-secondary text-sm leading-relaxed">{problem.description}</p>
            </Card>
          ))}
        </div>

        {/* Quote */}
        <motion.blockquote
          initial={{ opacity: 0, y: 16 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="max-w-2xl mx-auto card p-8 text-center border-l-4 border-l-[var(--color-accent)]"
        >
          <p className="text-lg md:text-xl text-primary italic mb-3">
            &ldquo;I just wanted to try Claude Code. Two days later, I&apos;ve reinstalled Windows twice.&rdquo;
          </p>
          <cite className="text-tertiary text-sm not-italic">— Every developer at some point</cite>
        </motion.blockquote>
      </div>
    </section>
  )
}
