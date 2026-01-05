'use client'

import { motion } from 'framer-motion'
import Card from './ui/Card'

const beforeItems = [
  '2+ days wrestling with setup',
  'Hours debugging PATH issues',
  'Endless Stack Overflow tabs',
  '3 attempts to get Docker running',
  'Frustration and lost motivation',
]

const afterItems = [
  '2 minutes to start coding',
  'Zero configuration needed',
  'One command, everything works',
  'Pre-tested tool combinations',
  'Excitement preserved',
]

export default function Solution() {
  return (
    <section id="solution" className="py-24 md:py-32 px-5 bg-secondary">
      <div className="max-w-6xl mx-auto">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="text-center mb-16"
        >
          <span className="section-badge mb-4">The Solution</span>
          <h2 className="text-display text-primary mb-4">
            What if setup just <span className="gradient-text">worked?</span>
          </h2>
          <p className="text-secondary max-w-xl mx-auto">
            DevBox Factory gives you a battle-tested, production-ready dev environment
            with everything pre-configured correctly.
          </p>
        </motion.div>

        {/* Comparison */}
        <div className="grid lg:grid-cols-[1fr_auto_1fr] gap-6 items-stretch mb-16">
          {/* Before */}
          <Card hover={false} className="border-red-500/20 dark:border-red-500/30">
            <div className="flex items-center gap-3 mb-6">
              <span className="w-10 h-10 flex items-center justify-center rounded-full bg-red-500/10 text-red-500 text-lg">✗</span>
              <h3 className="text-lg font-semibold text-primary">Without DevBox Factory</h3>
            </div>
            <ul className="space-y-3 mb-6">
              {beforeItems.map((item) => (
                <li key={item} className="flex items-center gap-3 text-secondary text-sm py-2 border-b border-[var(--color-border-light)] last:border-0">
                  <span className="w-1.5 h-1.5 rounded-full bg-red-500 shrink-0" />
                  {item}
                </li>
              ))}
            </ul>
            <div className="flex items-center gap-3 p-4 rounded-xl bg-red-500/5 border border-red-500/10">
              <span className="text-xl">😩</span>
              <span className="text-sm font-medium text-primary">Still debugging at midnight</span>
            </div>
          </Card>

          {/* VS */}
          <div className="hidden lg:flex items-center justify-center">
            <span className="px-4 py-2 rounded-full bg-[var(--color-bg-secondary)] text-tertiary text-sm font-medium border border-[var(--color-border)]">
              vs
            </span>
          </div>
          <div className="lg:hidden flex justify-center -my-2">
            <span className="px-4 py-2 rounded-full bg-[var(--color-bg-secondary)] text-tertiary text-sm font-medium border border-[var(--color-border)]">
              vs
            </span>
          </div>

          {/* After */}
          <Card hover={false} className="border-emerald-500/20 dark:border-emerald-500/30">
            <div className="flex items-center gap-3 mb-6">
              <span className="w-10 h-10 flex items-center justify-center rounded-full bg-emerald-500/10 text-emerald-500 text-lg">✓</span>
              <h3 className="text-lg font-semibold text-primary">With DevBox Factory</h3>
            </div>
            <ul className="space-y-3 mb-6">
              {afterItems.map((item) => (
                <li key={item} className="flex items-center gap-3 text-secondary text-sm py-2 border-b border-[var(--color-border-light)] last:border-0">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 shrink-0" />
                  {item}
                </li>
              ))}
            </ul>
            <div className="flex items-center gap-3 p-4 rounded-xl bg-emerald-500/5 border border-emerald-500/10">
              <span className="text-xl">🚀</span>
              <span className="text-sm font-medium text-primary">Already shipping features</span>
            </div>
          </Card>
        </div>

        {/* Value Props */}
        <div className="grid md:grid-cols-3 gap-4">
          {[
            { icon: '💰', title: 'Save $500+ Per Developer', desc: '2 days of setup = real money.' },
            { icon: '🧠', title: 'Preserve Your Energy', desc: 'Build, don\'t battle tools.' },
            { icon: '⚡', title: 'Immediate Productivity', desc: 'Zero to coding in 2 minutes.' },
          ].map((prop, i) => (
            <Card key={prop.title} delay={i * 0.1} className="text-center">
              <span className="text-3xl mb-3 block">{prop.icon}</span>
              <h4 className="font-semibold text-primary mb-1">{prop.title}</h4>
              <p className="text-secondary text-sm">{prop.desc}</p>
            </Card>
          ))}
        </div>
      </div>
    </section>
  )
}
