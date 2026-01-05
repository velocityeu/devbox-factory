'use client'

import { motion } from 'framer-motion'
import Card from './ui/Card'
import Button from './ui/Button'

const testimonials = [
  {
    quote: 'Finally, a tool that understands the pain of environment setup. Saved me hours on my new laptop setup.',
    avatar: '&#128104;&#8205;&#128187;',
    name: 'Vibe Coder',
    role: 'Building with Claude Code',
  },
  {
    quote: 'Our team of 12 developers now has identical environments. No more "works on my machine" excuses in PRs.',
    avatar: '&#128105;&#8205;&#128188;',
    name: 'Tech Lead',
    role: 'Enterprise Team',
  },
  {
    quote: 'I went from "what\'s a PATH variable" to shipping my first Claude Code project in one afternoon. This is how it should be.',
    avatar: '&#129489;&#8205;&#127891;',
    name: 'New Developer',
    role: 'Learning AI Development',
  },
]

export default function Testimonials() {
  return (
    <section className="py-20 md:py-32 px-4">
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
            Join the Movement
          </span>
          <h2 className="text-2xl sm:text-3xl md:text-4xl font-extrabold">
            Built by Developers, <span className="gradient-text">For Developers</span>
          </h2>
        </motion.div>

        {/* Testimonials Grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 md:gap-6 mb-12">
          {testimonials.map((testimonial, index) => (
            <Card key={testimonial.name} delay={index * 0.1}>
              <p className="text-base italic mb-6 leading-relaxed">&ldquo;{testimonial.quote}&rdquo;</p>
              <div className="flex items-center gap-3">
                <span
                  className="w-12 h-12 flex items-center justify-center bg-gradient-primary rounded-full text-2xl"
                  dangerouslySetInnerHTML={{ __html: testimonial.avatar }}
                />
                <div>
                  <span className="block font-semibold text-sm">{testimonial.name}</span>
                  <span className="text-xs text-zinc-500">{testimonial.role}</span>
                </div>
              </div>
            </Card>
          ))}
        </div>

        {/* CTA Banner */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="glass-card p-6 md:p-10 bg-gradient-to-br from-accent-primary/10 to-accent-secondary/10 border-accent-primary/30 flex flex-col md:flex-row items-center justify-between gap-6"
        >
          <div className="text-center md:text-left">
            <h3 className="text-xl md:text-2xl font-bold mb-2">Ready to Skip the Setup Drama?</h3>
            <p className="text-zinc-400">Join developers who chose productivity over frustration.</p>
          </div>
          <Button href="#quickstart" variant="primary" size="large" glow>
            <span>&#128640;</span>
            Get Started Now
          </Button>
        </motion.div>
      </div>
    </section>
  )
}
