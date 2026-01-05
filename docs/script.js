/**
 * DevBox Factory - Landing Page JavaScript
 * Handles animations, interactions, and dynamic content
 */

// ==========================================================================
// DOM Ready
// ==========================================================================
document.addEventListener('DOMContentLoaded', () => {
    initNavbar();
    initMobileMenu();
    initScrollAnimations();
    initTerminalAnimation();
    initCopyButtons();
    initFAQ();
    initDemoSteps();
    initSmoothScroll();
});

// ==========================================================================
// Navbar Scroll Effect
// ==========================================================================
function initNavbar() {
    const navbar = document.getElementById('navbar');
    let lastScroll = 0;

    window.addEventListener('scroll', () => {
        const currentScroll = window.pageYOffset;

        // Add scrolled class when past hero
        if (currentScroll > 100) {
            navbar.classList.add('scrolled');
        } else {
            navbar.classList.remove('scrolled');
        }

        lastScroll = currentScroll;
    });
}

// ==========================================================================
// Mobile Menu Toggle
// ==========================================================================
function initMobileMenu() {
    const toggle = document.getElementById('nav-toggle');
    const navLinks = document.getElementById('nav-links');

    if (!toggle || !navLinks) return;

    toggle.addEventListener('click', () => {
        toggle.classList.toggle('active');
        navLinks.classList.toggle('active');
        document.body.style.overflow = navLinks.classList.contains('active') ? 'hidden' : '';
    });

    // Close menu when clicking a link
    navLinks.querySelectorAll('.nav-link').forEach(link => {
        link.addEventListener('click', () => {
            toggle.classList.remove('active');
            navLinks.classList.remove('active');
            document.body.style.overflow = '';
        });
    });

    // Close menu when clicking outside
    document.addEventListener('click', (e) => {
        if (!navLinks.contains(e.target) && !toggle.contains(e.target)) {
            toggle.classList.remove('active');
            navLinks.classList.remove('active');
            document.body.style.overflow = '';
        }
    });
}

// ==========================================================================
// Scroll Reveal Animations
// ==========================================================================
function initScrollAnimations() {
    const elements = document.querySelectorAll('.animate-on-scroll');

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('visible');
                // Stagger child animations
                const children = entry.target.querySelectorAll('.glass-card, .profile-card, .quickstart-card, .social-card, .faq-item');
                children.forEach((child, index) => {
                    setTimeout(() => {
                        child.classList.add('visible');
                    }, index * 100);
                });
            }
        });
    }, {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    });

    elements.forEach(el => observer.observe(el));
}

// ==========================================================================
// Hero Terminal Animation
// ==========================================================================
function initTerminalAnimation() {
    const output = document.getElementById('terminal-output');
    if (!output) return;

    const lines = output.querySelectorAll('.output-line');

    // Hide all lines initially
    lines.forEach(line => {
        line.style.opacity = '0';
        line.style.transform = 'translateY(10px)';
    });

    // Animate lines sequentially after command typing
    setTimeout(() => {
        lines.forEach((line, index) => {
            setTimeout(() => {
                line.style.transition = 'opacity 0.3s ease, transform 0.3s ease';
                line.style.opacity = '1';
                line.style.transform = 'translateY(0)';
            }, index * 300);
        });
    }, 1500);
}

// ==========================================================================
// Copy to Clipboard
// ==========================================================================
function initCopyButtons() {
    const copyButtons = document.querySelectorAll('.copy-btn');

    copyButtons.forEach(button => {
        button.addEventListener('click', async () => {
            const targetId = button.getAttribute('data-clipboard');
            const codeElement = document.getElementById(targetId);

            if (!codeElement) return;

            try {
                await navigator.clipboard.writeText(codeElement.textContent);

                // Visual feedback
                const originalText = button.querySelector('.copy-text').textContent;
                button.classList.add('copied');
                button.querySelector('.copy-icon').textContent = '✓';
                button.querySelector('.copy-text').textContent = 'Copied!';

                setTimeout(() => {
                    button.classList.remove('copied');
                    button.querySelector('.copy-icon').textContent = '📋';
                    button.querySelector('.copy-text').textContent = originalText;
                }, 2000);
            } catch (err) {
                console.error('Failed to copy:', err);

                // Fallback for older browsers
                const textArea = document.createElement('textarea');
                textArea.value = codeElement.textContent;
                textArea.style.position = 'fixed';
                textArea.style.opacity = '0';
                document.body.appendChild(textArea);
                textArea.select();

                try {
                    document.execCommand('copy');
                    button.querySelector('.copy-text').textContent = 'Copied!';
                    setTimeout(() => {
                        button.querySelector('.copy-text').textContent = 'Copy';
                    }, 2000);
                } catch (e) {
                    button.querySelector('.copy-text').textContent = 'Error';
                }

                document.body.removeChild(textArea);
            }
        });
    });
}

// ==========================================================================
// FAQ Accordion
// ==========================================================================
function initFAQ() {
    const faqItems = document.querySelectorAll('.faq-item');

    faqItems.forEach(item => {
        const question = item.querySelector('.faq-question');

        question.addEventListener('click', () => {
            const isActive = item.classList.contains('active');

            // Close all other items
            faqItems.forEach(other => {
                if (other !== item) {
                    other.classList.remove('active');
                }
            });

            // Toggle current item
            item.classList.toggle('active', !isActive);
        });
    });
}

// ==========================================================================
// Demo Steps Interactive
// ==========================================================================
function initDemoSteps() {
    const steps = document.querySelectorAll('.demo-step');
    const terminalBody = document.getElementById('demo-terminal-body');

    if (!steps.length || !terminalBody) return;

    const terminalContent = {
        1: `<pre class="demo-output">
<span style="color: var(--accent-cyan)">PS C:\\></span> irm devbox.run | iex

Downloading DevBox Factory...
████████████████████████████████ 100%

<span style="color: var(--success)">✓</span> Downloaded successfully!
<span style="color: var(--success)">✓</span> Verifying checksums...
<span style="color: var(--success)">✓</span> Extracting files...

Starting interactive installer...
</pre>`,
        2: `<pre class="demo-output">
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║     ⚡ DevBox Factory v3.5.2                                     ║
║     One command. Perfect dev environment. Every time.            ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝

<span style="color: var(--accent-cyan)">?</span> Select installation profile:

  <span style="color: var(--accent-primary)">❯ 🤖 AI Coder      - Claude Code, Cursor, VS Code + AI extensions</span>
    🌐 Web Developer - Node.js, Python, Docker, Databases
    ☁️  Azure Developer - Azure CLI, .NET, Terraform
    🚀 Full Stack    - Everything included
    🎯 Minimal       - Git, Terminal, VS Code only

  ↑/↓: Navigate  Enter: Select  Esc: Cancel
</pre>`,
        3: `<pre class="demo-output">
<span style="color: var(--accent-cyan)">Installing AI Coder profile...</span>

<span style="color: var(--success)">✓</span> Installing Git for Windows...
<span style="color: var(--success)">✓</span> Installing Windows Terminal...
<span style="color: var(--success)">✓</span> Installing VS Code...
<span style="color: var(--accent-primary)">→</span> Installing Claude Code CLI...
  ████████████████████░░░░░░░░░░░░ 65%

<span style="color: var(--text-tertiary)">Estimated time remaining: 8 minutes</span>
<span style="color: var(--text-tertiary)">☕ Perfect time for that coffee...</span>
</pre>`,
        4: `<pre class="demo-output">
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║     <span style="color: var(--success)">✨ Installation Complete!</span>                                  ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝

<span style="color: var(--success)">✓</span> Git configured and ready
<span style="color: var(--success)">✓</span> Claude Code CLI installed (claude --version: 1.0.17)
<span style="color: var(--success)">✓</span> Cursor IDE installed
<span style="color: var(--success)">✓</span> VS Code + AI extensions configured
<span style="color: var(--success)">✓</span> Node.js 22 (via NVM) ready
<span style="color: var(--success)">✓</span> Python 3.12 installed

<span style="color: var(--accent-primary)">→</span> Run <span style="color: var(--accent-cyan)">claude</span> to start vibe coding!

<span style="color: var(--text-tertiary)">Total time: 14 minutes 32 seconds</span>
</pre>`
    };

    steps.forEach(step => {
        step.addEventListener('click', () => {
            const stepNum = step.getAttribute('data-step');

            // Update active state
            steps.forEach(s => s.classList.remove('active'));
            step.classList.add('active');

            // Update terminal content
            if (terminalContent[stepNum]) {
                terminalBody.innerHTML = terminalContent[stepNum];
            }
        });
    });

    // Auto-cycle through steps
    let currentStep = 1;
    const autoPlay = setInterval(() => {
        currentStep = currentStep >= 4 ? 1 : currentStep + 1;
        const stepElement = document.querySelector(`.demo-step[data-step="${currentStep}"]`);
        if (stepElement) {
            stepElement.click();
        }
    }, 5000);

    // Stop auto-play on user interaction
    steps.forEach(step => {
        step.addEventListener('click', () => {
            clearInterval(autoPlay);
        });
    });
}

// ==========================================================================
// Smooth Scroll for Anchor Links
// ==========================================================================
function initSmoothScroll() {
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const targetId = this.getAttribute('href');

            if (targetId === '#') return;

            const target = document.querySelector(targetId);
            if (target) {
                const navHeight = document.getElementById('navbar').offsetHeight;
                const targetPosition = target.getBoundingClientRect().top + window.pageYOffset - navHeight - 20;

                window.scrollTo({
                    top: targetPosition,
                    behavior: 'smooth'
                });
            }
        });
    });
}

// ==========================================================================
// Typing Effect Utility (for future use)
// ==========================================================================
function typeWriter(element, text, speed = 50, callback) {
    let i = 0;
    element.textContent = '';

    function type() {
        if (i < text.length) {
            element.textContent += text.charAt(i);
            i++;
            setTimeout(type, speed);
        } else if (callback) {
            callback();
        }
    }

    type();
}

// ==========================================================================
// Particle Background Effect (Optional Enhancement)
// ==========================================================================
function initParticles() {
    const canvas = document.createElement('canvas');
    canvas.id = 'particles';
    canvas.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        pointer-events: none;
        z-index: -1;
    `;
    document.body.appendChild(canvas);

    const ctx = canvas.getContext('2d');
    let particles = [];
    const particleCount = 50;

    function resize() {
        canvas.width = window.innerWidth;
        canvas.height = window.innerHeight;
    }

    function createParticle() {
        return {
            x: Math.random() * canvas.width,
            y: Math.random() * canvas.height,
            size: Math.random() * 2 + 1,
            speedX: (Math.random() - 0.5) * 0.5,
            speedY: (Math.random() - 0.5) * 0.5,
            opacity: Math.random() * 0.5 + 0.1
        };
    }

    function init() {
        resize();
        particles = [];
        for (let i = 0; i < particleCount; i++) {
            particles.push(createParticle());
        }
    }

    function animate() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);

        particles.forEach(p => {
            p.x += p.speedX;
            p.y += p.speedY;

            if (p.x < 0 || p.x > canvas.width) p.speedX *= -1;
            if (p.y < 0 || p.y > canvas.height) p.speedY *= -1;

            ctx.beginPath();
            ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
            ctx.fillStyle = `rgba(99, 102, 241, ${p.opacity})`;
            ctx.fill();
        });

        requestAnimationFrame(animate);
    }

    window.addEventListener('resize', resize);
    init();
    animate();
}

// Uncomment to enable particles:
// initParticles();

// ==========================================================================
// Performance: Debounce & Throttle Utilities
// ==========================================================================
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}

function throttle(func, limit) {
    let inThrottle;
    return function executedFunction(...args) {
        if (!inThrottle) {
            func(...args);
            inThrottle = true;
            setTimeout(() => inThrottle = false, limit);
        }
    };
}

// ==========================================================================
// Analytics Events (placeholder for future implementation)
// ==========================================================================
function trackEvent(action, category, label) {
    // Placeholder for analytics implementation
    // Example: gtag('event', action, { event_category: category, event_label: label });
    console.log(`[Analytics] ${category}: ${action} - ${label}`);
}

// Track CTA clicks
document.querySelectorAll('.btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const text = btn.textContent.trim();
        trackEvent('click', 'CTA', text);
    });
});

// Track copy events
document.querySelectorAll('.copy-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        const targetId = btn.getAttribute('data-clipboard');
        trackEvent('copy', 'Code', targetId);
    });
});
