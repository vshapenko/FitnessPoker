// Main JavaScript for FitnessPoker Website

// Screenshot Carousel
document.addEventListener('DOMContentLoaded', function() {
    const screenshots = document.querySelectorAll('.screenshot');
    const screenshotBtns = document.querySelectorAll('.screenshot-btn');
    const captions = document.querySelectorAll('.caption');
    let currentIndex = 0;
    let intervalId;

    function showScreenshot(index) {
        // Hide all screenshots
        screenshots.forEach(s => s.classList.remove('active'));
        screenshotBtns.forEach(b => b.classList.remove('active'));
        captions.forEach(c => c.classList.remove('active'));

        // Show selected screenshot
        screenshots[index].classList.add('active');
        screenshotBtns[index].classList.add('active');
        captions[index].classList.add('active');

        currentIndex = index;
    }

    // Button click handlers
    screenshotBtns.forEach((btn, index) => {
        btn.addEventListener('click', () => {
            showScreenshot(index);
            // Reset auto-play timer
            clearInterval(intervalId);
            startAutoPlay();
        });
    });

    // Auto-play carousel
    function startAutoPlay() {
        intervalId = setInterval(() => {
            const nextIndex = (currentIndex + 1) % screenshots.length;
            showScreenshot(nextIndex);
        }, 4000);
    }

    // Start auto-play
    startAutoPlay();

    // Pause on hover
    const carouselContainer = document.querySelector('.screenshot-carousel');
    if (carouselContainer) {
        carouselContainer.addEventListener('mouseenter', () => clearInterval(intervalId));
        carouselContainer.addEventListener('mouseleave', () => startAutoPlay());
    }
});

// Smooth Scrolling
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function(e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            const navHeight = document.querySelector('.navbar').offsetHeight;
            const targetPosition = target.offsetTop - navHeight;
            window.scrollTo({
                top: targetPosition,
                behavior: 'smooth'
            });
        }
    });
});

// Mobile Menu Toggle
const mobileMenuToggle = document.querySelector('.mobile-menu-toggle');
const navLinks = document.querySelector('.nav-links');

if (mobileMenuToggle) {
    mobileMenuToggle.addEventListener('click', function() {
        navLinks.classList.toggle('mobile-active');
        this.classList.toggle('active');
    });
}

// Navbar Scroll Effect
let lastScrollTop = 0;
const navbar = document.querySelector('.navbar');

window.addEventListener('scroll', function() {
    const scrollTop = window.pageYOffset || document.documentElement.scrollTop;

    if (scrollTop > lastScrollTop && scrollTop > 100) {
        // Scrolling down
        navbar.style.transform = 'translateY(-100%)';
    } else {
        // Scrolling up
        navbar.style.transform = 'translateY(0)';
    }

    // Add shadow on scroll
    if (scrollTop > 10) {
        navbar.style.boxShadow = '0 4px 20px rgba(0, 0, 0, 0.1)';
    } else {
        navbar.style.boxShadow = '0 2px 10px rgba(0, 0, 0, 0.08)';
    }

    lastScrollTop = scrollTop <= 0 ? 0 : scrollTop;
});

// Hero Image Animation
const heroImage = document.querySelector('.phone-mockup img');
if (heroImage) {
    window.addEventListener('scroll', function() {
        const scrolled = window.pageYOffset;
        const parallaxSpeed = 0.5;
        heroImage.style.transform = `translateY(${scrolled * parallaxSpeed}px)`;
    });
}

// Intersection Observer for Fade In Animations
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver(function(entries) {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.classList.add('fade-in');
            observer.unobserve(entry.target);
        }
    });
}, observerOptions);

// Observe all feature cards and steps
document.querySelectorAll('.feature-card, .step').forEach(el => {
    el.style.opacity = '0';
    el.style.transform = 'translateY(20px)';
    el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
    observer.observe(el);
});

// Add fade-in class styles
const style = document.createElement('style');
style.textContent = `
    .fade-in {
        opacity: 1 !important;
        transform: translateY(0) !important;
    }

    .nav-links.mobile-active {
        display: flex;
        position: fixed;
        top: 70px;
        left: 0;
        right: 0;
        background: white;
        flex-direction: column;
        padding: 2rem;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
        animation: slideDown 0.3s ease;
    }

    @keyframes slideDown {
        from {
            opacity: 0;
            transform: translateY(-20px);
        }
        to {
            opacity: 1;
            transform: translateY(0);
        }
    }

    .mobile-menu-toggle.active span:nth-child(1) {
        transform: rotate(45deg) translate(5px, 5px);
    }

    .mobile-menu-toggle.active span:nth-child(2) {
        opacity: 0;
    }

    .mobile-menu-toggle.active span:nth-child(3) {
        transform: rotate(-45deg) translate(7px, -6px);
    }
`;
document.head.appendChild(style);

// Preload Images
function preloadImages() {
    const imageUrls = [
        'assets/images/01_Welcome_Setup_Screen.png',
        'assets/images/02_Player_Configuration_Screen.png',
        'assets/images/03_Active_Gameplay_Screen.png',
        'assets/images/04_Exercise_Customization_Screen.png',
        'assets/images/05_Game_Statistics_Screen.png'
    ];

    imageUrls.forEach(url => {
        const img = new Image();
        img.src = url;
    });
}

// Preload images when page loads
window.addEventListener('load', preloadImages);

// Analytics Event Tracking (placeholder for future implementation)
function trackEvent(category, action, label) {
    // Add Google Analytics or other tracking here
    console.log(`Event: ${category} - ${action} - ${label}`);
}

// Track download button clicks
document.querySelectorAll('.btn-primary, .app-store-badge').forEach(btn => {
    btn.addEventListener('click', function() {
        trackEvent('Download', 'Click', 'App Store');
    });
});

// Add loading animation
window.addEventListener('load', function() {
    document.body.classList.add('loaded');
});

// Performance optimization: Lazy load images
if ('IntersectionObserver' in window) {
    const imageObserver = new IntersectionObserver(function(entries, observer) {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                const img = entry.target;
                img.src = img.dataset.src;
                img.classList.add('loaded');
                imageObserver.unobserve(img);
            }
        });
    });

    // Apply to images with data-src attribute
    document.querySelectorAll('img[data-src]').forEach(img => {
        imageObserver.observe(img);
    });
}