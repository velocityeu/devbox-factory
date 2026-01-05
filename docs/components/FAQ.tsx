'use client'

import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'

const faqs = [
  {
    question: 'Is this really free?',
    answer: 'Yes, 100% free and open source. MIT licensed. Use it for personal projects, startups, enterprise—whatever you\'re building. No catch. No "upgrade to pro." Just tools that work.',
  },
  {
    question: 'Will this mess up my current setup?',
    answer: 'DevBox Factory is designed to be idempotent—safe to run multiple times. It checks what\'s already installed and only adds what\'s missing. For maximum safety, use the VM template feature to create isolated dev environments.',
  },
  {
    question: 'Does it work with Mac or Linux?',
    answer: 'Currently Windows-focused (Windows 11 and Server 2025). Why? Because Windows dev setup is notoriously the hardest to get right. Mac and Linux developers already have better tooling (homebrew, apt, etc.). We went where the pain is greatest.',
  },
  {
    question: 'What if I need different tool versions?',
    answer: 'Node.js is installed via NVM, so you can switch versions instantly. The interactive installer lets you customize what gets installed. And you can always modify the templates for your specific needs.',
  },
  {
    question: 'Can I use this for my team?',
    answer: 'Absolutely! That\'s one of the main use cases. Create a VM template once, then clone it for every team member. Everyone gets identical environments in 2-3 minutes. Onboarding new developers becomes trivial.',
  },
  {
    question: 'What about air-gapped or restricted networks?',
    answer: 'DevBox Factory supports offline installation. Pre-download all dependencies on a connected machine, transfer them, and install without internet. Perfect for enterprise environments with network restrictions.',
  },
]

export default function FAQ() {
  const [openIndex, setOpenIndex] = useState<number | null>(null)

  return (
    <section id="faq" className="py-24 md:py-32 px-5 bg-secondary">
      <div className="max-w-3xl mx-auto">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="text-center mb-12"
        >
          <span className="section-badge mb-4">Questions</span>
          <h2 className="text-display text-primary">
            Frequently asked <span className="gradient-text">questions</span>
          </h2>
        </motion.div>

        {/* FAQ Items */}
        <div className="space-y-1">
          {faqs.map((faq, index) => (
            <motion.div
              key={faq.question}
              initial={{ opacity: 0, y: 10 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.3, delay: index * 0.05 }}
              className="border-b border-[var(--color-border-light)]"
            >
              <button
                onClick={() => setOpenIndex(openIndex === index ? null : index)}
                className="w-full flex items-center justify-between py-5 text-left group"
              >
                <span className="text-base font-medium text-primary group-hover:text-accent transition-colors pr-4">
                  {faq.question}
                </span>
                <span
                  className={`w-6 h-6 flex items-center justify-center rounded-full bg-[var(--color-bg-secondary)] text-accent text-sm font-medium transition-transform duration-300 shrink-0 ${
                    openIndex === index ? 'rotate-45' : ''
                  }`}
                >
                  +
                </span>
              </button>
              <AnimatePresence>
                {openIndex === index && (
                  <motion.div
                    initial={{ height: 0, opacity: 0 }}
                    animate={{ height: 'auto', opacity: 1 }}
                    exit={{ height: 0, opacity: 0 }}
                    transition={{ duration: 0.3 }}
                    className="overflow-hidden"
                  >
                    <p className="pb-5 text-secondary text-sm leading-relaxed">{faq.answer}</p>
                  </motion.div>
                )}
              </AnimatePresence>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  )
}
