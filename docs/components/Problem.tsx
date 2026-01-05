'use client'

import { motion } from 'framer-motion'
import Card from './ui/Card'

const problems = [
  {
    icon: '&#128548;',
    title: 'The Tutorial Hell Loop',
    description: '"Just follow these 47 simple steps..." Three hours later, you\'re debugging why Node.js won\'t recognize npm even though you swear you installed it correctly.',
  },
  {
    icon: '&#129327;',
    title: 'The Conflicting Advice Maze',
    description: 'One guide says use NVM. Another says use Volta. That Stack Overflow answer from 2019 says just install Node directly. Which one is right? Spoiler: They\'re all outdated.',
  },
  {
    icon: '&#128128;',
    title: 'The "Works on My Machine" Curse',
    description: 'Your teammate\'s code runs perfectly. On your machine? Cryptic errors. Different Python version. Missing environment variables. Welcome to dependency hell.',
  },
  {
    icon: '&#9200;',
    title: 'The Time Vampire',
    description: 'You wanted to learn Claude Code and ship something cool this weekend. Instead, you spent 6 hours configuring WSL2 and still can\'t get Docker to work.',
  },
  {
    icon: '&#128293;',
    title: 'The Missing 0.1%',
    description: 'Every tutorial assumes you already know the ONE crucial thing they didn\'t mention. That environment variable. That PATH entry. That config file that makes everything work.',
  },
  {
    icon: '&#128557;',
    title: 'The Motivation Killer',
    description: 'You were hyped to vibe code with AI. Now you\'re questioning your life choices while reading error messages about missing DLLs. The excitement is gone.',
  },
]

export default function Problem() {
  return (
    <section id="problem" className="py-20 md:py-32 px-4">
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
            The Reality Check
          </span>
          <h2 className="text-2xl sm:text-3xl md:text-4xl font-extrabold mb-4">
            We&apos;ve All Been There. <span className="gradient-text">It Sucks.</span>
          </h2>
        </motion.div>

        {/* Problem Cards Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 md:gap-6 mb-12">
          {problems.map((problem, index) => (
            <Card key={problem.title} delay={index * 0.1} className="text-center">
              <div
                className="text-4xl md:text-5xl mb-4"
                dangerouslySetInnerHTML={{ __html: problem.icon }}
              />
              <h3 className="text-lg font-bold mb-3">{problem.title}</h3>
              <p className="text-zinc-400 text-sm leading-relaxed">{problem.description}</p>
            </Card>
          ))}
        </div>

        {/* Quote */}
        <motion.blockquote
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="max-w-2xl mx-auto glass-card p-6 md:p-8 border-l-4 border-accent-primary text-center"
        >
          <p className="text-lg md:text-xl italic mb-3">
            &ldquo;I just wanted to try Claude Code. Two days later, I&apos;ve reinstalled Windows twice.&rdquo;
          </p>
          <cite className="text-zinc-500 text-sm not-italic">— Every developer at least once</cite>
        </motion.blockquote>
      </div>
    </section>
  )
}
