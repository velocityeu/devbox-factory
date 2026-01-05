'use client'

import { motion } from 'framer-motion'
import Button from './ui/Button'
import Link from 'next/link'

const resources = [
  { label: 'GitHub', href: 'https://github.com/velocityeu/devbox-factory' },
  { label: 'Report Issues', href: 'https://github.com/velocityeu/devbox-factory/issues' },
  { label: 'Documentation', href: 'https://github.com/velocityeu/devbox-factory/blob/main/README.md' },
]

const related = [
  { label: 'Claude Code Docs', href: 'https://docs.anthropic.com/en/docs/claude-code' },
  { label: 'Cursor IDE', href: 'https://cursor.com' },
  { label: 'WSL Documentation', href: 'https://learn.microsoft.com/en-us/windows/wsl/' },
]

export default function Footer() {
  return (
    <>
      {/* Final CTA */}
      <section className="py-24 md:py-32 px-5">
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="max-w-3xl mx-auto text-center"
        >
          <h2 className="text-display text-primary mb-6">
            Stop fighting your tools.
            <br />
            <span className="gradient-text">Start building something amazing.</span>
          </h2>
          <p className="text-secondary text-lg mb-10 max-w-xl mx-auto">
            Life&apos;s too short for environment setup. One command. Two minutes.
            Perfect dev environment. Every time.
          </p>
          <div className="flex flex-col sm:flex-row gap-3 justify-center">
            <Button href="#quickstart" variant="primary" size="lg">
              Get DevBox Factory
            </Button>
            <Button
              href="https://github.com/velocityeu/devbox-factory"
              variant="secondary"
              size="lg"
            >
              Star on GitHub
            </Button>
          </div>
        </motion.div>
      </section>

      {/* Footer */}
      <footer className="border-t border-[var(--color-border)] py-12 px-5">
        <div className="max-w-6xl mx-auto">
          <div className="flex flex-col md:flex-row justify-between gap-10 mb-10">
            {/* Brand */}
            <div className="md:max-w-xs">
              <Link href="#" className="flex items-center gap-2 text-lg font-semibold text-primary mb-3">
                <span className="text-xl">⚡</span>
                <span>DevBox<span className="text-accent">Factory</span></span>
              </Link>
              <p className="text-sm text-tertiary">One command. Perfect dev environment. Every time.</p>
            </div>

            {/* Links */}
            <div className="flex gap-16 flex-wrap">
              <div>
                <h4 className="text-xs font-semibold text-primary uppercase tracking-wider mb-4">Resources</h4>
                <ul className="space-y-3">
                  {resources.map((link) => (
                    <li key={link.label}>
                      <a
                        href={link.href}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-sm text-secondary hover:text-accent transition-colors"
                      >
                        {link.label}
                      </a>
                    </li>
                  ))}
                </ul>
              </div>
              <div>
                <h4 className="text-xs font-semibold text-primary uppercase tracking-wider mb-4">Related</h4>
                <ul className="space-y-3">
                  {related.map((link) => (
                    <li key={link.label}>
                      <a
                        href={link.href}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="text-sm text-secondary hover:text-accent transition-colors"
                      >
                        {link.label}
                      </a>
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          </div>

          {/* Bottom */}
          <div className="pt-8 border-t border-[var(--color-border-light)] text-center">
            <p className="text-sm text-tertiary mb-1">
              Made with ⚡ by{' '}
              <a
                href="https://github.com/velocityeu"
                target="_blank"
                rel="noopener noreferrer"
                className="text-accent hover:underline"
              >
                Velocity EU
              </a>
            </p>
            <p className="text-xs text-tertiary/60">MIT License &bull; Open Source &bull; Free Forever</p>
          </div>
        </div>
      </footer>
    </>
  )
}
