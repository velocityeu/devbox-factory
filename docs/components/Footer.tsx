'use client'

import { motion } from 'framer-motion'
import Button from './ui/Button'
import Link from 'next/link'

export default function Footer() {
  return (
    <>
      {/* Final CTA */}
      <section className="py-20 md:py-32 px-4">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5 }}
          className="max-w-3xl mx-auto text-center"
        >
          <h2 className="text-2xl sm:text-3xl md:text-4xl font-extrabold leading-tight mb-6">
            Stop Fighting Your Tools.
            <br />
            <span className="gradient-text">Start Building Something Amazing.</span>
          </h2>
          <p className="text-lg text-zinc-400 mb-10">
            Life&apos;s too short for environment setup. One command. Two minutes.
            Perfect dev environment. Every time.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <Button href="#quickstart" variant="primary" size="large" glow>
              <span>&#9889;</span>
              Get DevBox Factory
            </Button>
            <Button
              href="https://github.com/velocityeu/devbox-factory"
              variant="secondary"
              size="large"
            >
              <span>&#11088;</span>
              Star on GitHub
            </Button>
          </div>
        </motion.div>
      </section>

      {/* Footer */}
      <footer className="border-t border-white/10 py-12 px-4">
        <div className="max-w-6xl mx-auto">
          <div className="flex flex-col md:flex-row justify-between gap-10 mb-10">
            {/* Brand */}
            <div className="md:max-w-xs">
              <Link href="#" className="flex items-center gap-2 text-lg font-bold mb-3">
                <span className="text-xl">&#9889;</span>
                <span>DevBox<span className="gradient-text">Factory</span></span>
              </Link>
              <p className="text-sm text-zinc-500">One command. Perfect dev environment. Every time.</p>
            </div>

            {/* Links */}
            <div className="flex gap-16">
              <div>
                <h4 className="text-sm font-semibold mb-4">Resources</h4>
                <ul className="space-y-3">
                  <li>
                    <a href="https://github.com/velocityeu/devbox-factory" target="_blank" rel="noopener noreferrer" className="text-sm text-zinc-400 hover:text-accent-primary transition-colors">
                      GitHub
                    </a>
                  </li>
                  <li>
                    <a href="https://github.com/velocityeu/devbox-factory/issues" target="_blank" rel="noopener noreferrer" className="text-sm text-zinc-400 hover:text-accent-primary transition-colors">
                      Report Issues
                    </a>
                  </li>
                  <li>
                    <a href="https://github.com/velocityeu/devbox-factory/blob/main/README.md" target="_blank" rel="noopener noreferrer" className="text-sm text-zinc-400 hover:text-accent-primary transition-colors">
                      Documentation
                    </a>
                  </li>
                </ul>
              </div>
              <div>
                <h4 className="text-sm font-semibold mb-4">Related</h4>
                <ul className="space-y-3">
                  <li>
                    <a href="https://docs.anthropic.com/en/docs/claude-code" target="_blank" rel="noopener noreferrer" className="text-sm text-zinc-400 hover:text-accent-primary transition-colors">
                      Claude Code Docs
                    </a>
                  </li>
                  <li>
                    <a href="https://cursor.com" target="_blank" rel="noopener noreferrer" className="text-sm text-zinc-400 hover:text-accent-primary transition-colors">
                      Cursor IDE
                    </a>
                  </li>
                  <li>
                    <a href="https://learn.microsoft.com/en-us/windows/wsl/" target="_blank" rel="noopener noreferrer" className="text-sm text-zinc-400 hover:text-accent-primary transition-colors">
                      WSL Documentation
                    </a>
                  </li>
                </ul>
              </div>
            </div>
          </div>

          {/* Bottom */}
          <div className="pt-8 border-t border-white/10 text-center">
            <p className="text-sm text-zinc-500 mb-1">
              Made with &#9889; by{' '}
              <a href="https://github.com/velocityeu" target="_blank" rel="noopener noreferrer" className="text-accent-primary hover:underline">
                Velocity EU
              </a>
            </p>
            <p className="text-xs text-zinc-600">MIT License • Open Source • Free Forever</p>
          </div>
        </div>
      </footer>
    </>
  )
}
