'use client'

import { motion } from 'framer-motion'
import Card from './ui/Card'
import Button from './ui/Button'

const testimonials = [
  {
    quote: 'Finally, a tool that understands the pain of environment setup. Saved me hours on my new laptop setup.',
    initials: 'VC',
    name: 'Vibe Coder',
    role: 'Building with Claude Code',
  },
  {
    quote: 'Our team of 12 developers now has identical environments. No more "works on my machine" excuses in PRs.',
    initials: 'TL',
    name: 'Tech Lead',
    role: 'Enterprise Team',
  },
  {
    quote: 'I went from "what\'s a PATH variable" to shipping my first Claude Code project in one afternoon. This is how it should be.',
    initials: 'ND',
    name: 'New Developer',
    role: 'Learning AI Development',
  },
]

export default function Testimonials() {
  return (
    <section className="py-24 md:py-32 px-5">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="text-center mb-16"
        >
          <span className="section-badge mb-4">Join the Movement</span>
          <h2 className="text-display text-primary mb-4">
            Built by developers, <span className="gradient-text">for developers</span>
          </h2>
          <p className="text-secondary max-w-xl mx-auto">
            See what others are saying about their experience with DevBox Factory.
          </p>
        </motion.div>

        {/* Testimonials Grid */}
        <div className="grid md:grid-cols-3 gap-4 mb-16">
          {testimonials.map((testimonial, index) => (
            <Card key={testimonial.name} delay={index * 0.1} padding="lg">
              <div className="flex flex-col h-full">
                <p className="text-secondary text-sm leading-relaxed mb-6 flex-1">
                  &ldquo;{testimonial.quote}&rdquo;
                </p>
                <div className="flex items-center gap-3 pt-4 border-t border-[var(--color-border-light)]">
                  <span className="w-10 h-10 flex items-center justify-center bg-[var(--color-bg-secondary)] border border-[var(--color-border-light)] rounded-full text-sm font-medium text-secondary">
                    {testimonial.initials}
                  </span>
                  <div>
                    <span className="block font-medium text-primary text-sm">{testimonial.name}</span>
                    <span className="text-xs text-tertiary">{testimonial.role}</span>
                  </div>
                </div>
              </div>
            </Card>
          ))}
        </div>

        {/* CTA Banner */}
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="card p-8 md:p-12 border-[var(--color-accent)]/20"
        >
          <div className="flex flex-col md:flex-row items-center justify-between gap-6">
            <div className="text-center md:text-left">
              <h3 className="text-title text-primary mb-2">Ready to skip the setup drama?</h3>
              <p className="text-secondary">Join developers who chose productivity over frustration.</p>
            </div>
            <Button href="#quickstart" variant="primary" size="lg">
              Get Started Now
            </Button>
          </div>
        </motion.div>
      </div>
    </section>
  )
}
