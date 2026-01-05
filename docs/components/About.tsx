'use client'

import { motion } from 'framer-motion'
import Card from './ui/Card'

const values = [
  {
    num: '01',
    title: 'Simplicity First',
    description: 'We believe the best tools get out of your way. No bloat, no complexity—just what you need to build.',
  },
  {
    num: '02',
    title: 'Developer Experience',
    description: 'Every decision we make is guided by one question: does this make developers more productive?',
  },
  {
    num: '03',
    title: 'Open Source',
    description: 'Transparency builds trust. Our code is open, our roadmap is public, and our community drives us forward.',
  },
]

const stats = [
  { value: '2019', label: 'Founded' },
  { value: '50K+', label: 'Developers' },
  { value: '12', label: 'Team members' },
  { value: '100%', label: 'Remote' },
]

export default function About() {
  return (
    <section id="about" className="py-24 md:py-32 px-5">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="text-center mb-16"
        >
          <span className="section-badge mb-4">About Us</span>
          <h2 className="text-display text-primary mb-4">
            Built by developers, <span className="gradient-text">for developers</span>
          </h2>
          <p className="text-secondary max-w-2xl mx-auto">
            We started DevBox Factory because we were tired of wasting days on environment setup.
            Now we help thousands of developers skip the frustration and get straight to building.
          </p>
        </motion.div>

        {/* Two Column Layout */}
        <div className="grid lg:grid-cols-2 gap-12 mb-16">
          {/* Story */}
          <motion.div
            initial={{ opacity: 0, y: 16 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5 }}
          >
            <h3 className="text-title text-primary mb-4">Our Story</h3>
            <div className="space-y-4 text-secondary">
              <p>
                It started with a simple frustration: why does setting up a development environment
                take longer than building the actual feature?
              </p>
              <p>
                After the third time reinstalling Windows and spending two days configuring tools,
                we decided enough was enough. We built DevBox Factory to solve our own problem.
              </p>
              <p>
                Today, teams around the world use DevBox Factory to onboard developers in minutes
                instead of days. What started as a personal tool has become a movement.
              </p>
            </div>
          </motion.div>

          {/* Stats */}
          <motion.div
            initial={{ opacity: 0, y: 16 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.5, delay: 0.1 }}
            className="card p-8"
          >
            <div className="grid grid-cols-2 gap-8">
              {stats.map((stat, index) => (
                <div key={stat.label} className="text-center">
                  <span className="block text-3xl md:text-4xl font-semibold text-primary mb-1">
                    {stat.value}
                  </span>
                  <span className="text-sm text-tertiary">{stat.label}</span>
                </div>
              ))}
            </div>
          </motion.div>
        </div>

        {/* Values */}
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="mb-8"
        >
          <h3 className="text-title text-primary text-center mb-8">What We Believe</h3>
        </motion.div>

        <div className="grid md:grid-cols-3 gap-4 mb-16">
          {values.map((value, index) => (
            <Card key={value.title} delay={index * 0.05}>
              <span className="text-xs font-mono text-tertiary mb-3 block">{value.num}</span>
              <h4 className="text-lg font-semibold text-primary mb-2">{value.title}</h4>
              <p className="text-secondary text-sm leading-relaxed">{value.description}</p>
            </Card>
          ))}
        </div>

        {/* Team CTA */}
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="card p-8 md:p-12 text-center border-[var(--color-accent)]/20"
        >
          <h3 className="text-title text-primary mb-4">Join Our Team</h3>
          <p className="text-secondary max-w-xl mx-auto mb-6">
            We're always looking for passionate developers who want to make a difference.
            Remote-first, async-friendly, and focused on impact.
          </p>
          <a
            href="https://github.com/velocityeu/devbox-factory"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 px-6 py-3 bg-[var(--color-accent)] text-white font-medium rounded-full hover:bg-[var(--color-accent-hover)] transition-colors"
          >
            View Open Positions
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M13 7l5 5m0 0l-5 5m5-5H6" />
            </svg>
          </a>
        </motion.div>
      </div>
    </section>
  )
}
