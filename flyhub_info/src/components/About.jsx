import React from 'react';
import { FaGooglePlay } from 'react-icons/fa';
import '../styles/About.css';

const ecosystemImage = "https://images.unsplash.com/photo-1473968512647-3e447244af8f?w=800&auto=format&fit=crop&q=80" 
const jobImage = "https://images.unsplash.com/photo-1552664730-d307ca884978?w=600&auto=format&fit=crop&q=80";
const communityImage = "https://plus.unsplash.com/premium_photo-1681505195930-388c317b7a76?w=1000&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8Y29tbXVuaXR5fGVufDB8fDB8fHww"

const About = () => {
  return (
    <main className="about-container">
      
      <header className="hero-section">
        <div className="hero-content">
          <h1>The Future of Drone is Here</h1>
          <p className="hero-subtitle">
            Flyhub is the world's leading all-in-one drone ecosystem connecting 50,000+ pilots, businesses, 
            and enthusiasts. Buy, sell, rent, service drones, find jobs, and access professional training—all in one trusted platform.
          </p>
          <div className="playstore-hero-container">
            <a href="https://play.google.com/store/apps" target="_blank" rel="noopener noreferrer" className="playstore-button">
              <FaGooglePlay className="playstore-icon" />
              <div className="playstore-text">
                <span>Get it on</span>
                <strong>Google Play</strong>
              </div>
              <span className="playstore-download">Download Now</span>
            </a>
          </div>
        </div>
      </header>

      <section className="ecosystem-section">
        <div className="ecosystem-content">
          <div className="ecosystem-text">
            <h2>The Ultimate Drone Ecosystem</h2>
            <p>
              Flyhub consolidates the entire drone industry into one powerful platform. From consumer hobbyists 
              to enterprise operators, we've built the infrastructure for drone commerce, services, and careers.
            </p>
            <ul className="ecosystem-list">
              <li><span className="checkmark">✓</span> <strong>Marketplace:</strong> 10,000+ new & used drones, parts, and accessories from verified sellers</li>
              <li><span className="checkmark">✓</span> <strong>Rentals:</strong> Short-term equipment rentals with nationwide delivery</li>
              <li><span className="checkmark">✓</span> <strong>Services:</strong> 5,000+ certified pilots for aerial photography, surveying, inspections</li>
              <li><span className="checkmark">✓</span> <strong>Job Portal:</strong> 500+ active drone pilot positions from top companies</li>
              <li><span className="checkmark">✓</span> <strong>Training:</strong> FAA-approved courses with hands-on flight training</li>
              <li><span className="checkmark">✓</span> <strong>Community:</strong> Forums, events, and networking for 50K+ members</li>
            </ul>
          </div>
          <div className="ecosystem-image">
            <img src={ecosystemImage} alt="Complete Flyhub drone ecosystem" />
          </div>
        </div>
      </section>

      <section className="dark-theme">
        <div className="content-wrapper">
          
          <div className="trust-block">
            <h2 className="section-title">Built on Trust & Security</h2>
            <p className="trust-subtitle">
              50,000+ users trust Flyhub with $10M+ in annual transactions. Your safety is our priority.
            </p>
            <div className="trust-grid">
              <div className="trust-item">
                <div className="trust-icon">🛡️</div>
                <h3>Verified Network</h3>
                <p>Every seller, pilot, and service provider undergoes identity verification and background checks</p>
              </div>
              <div className="trust-item">
                <div className="trust-icon">🔒</div>
                <h3>Secure Payments</h3>
                <p>Bank-grade encryption, escrow protection, and fraud monitoring on every transaction</p>
              </div>
              <div className="trust-item">
                <div className="trust-icon">📊</div>
                <h3>Proven Scale</h3>
                <p>$10M+ processed, 50K+ users, 25K+ listings, 99.9% uptime guarantee</p>
              </div>
            </div>
          </div>

          <hr className="section-separator" />

          <div className="how-it-works-block">
            <h2 className="section-title">Simple 3-Step Process</h2>
            <div className="steps-grid">
              <div className="step">
                <div className="step-number">1</div>
                <h3>Create Your Profile</h3>
                <p>Sign up in 2 minutes. Verify your identity and tell us about your drone experience and needs.</p>
              </div>
              <div className="step">
                <div className="step-number">2</div>
                <h3>Explore & Connect</h3>
                <p>Browse 10K+ listings, services, jobs. Use advanced filters and AI recommendations to find exactly what you need.</p>
              </div>
              <div className="step">
                <div className="step-number">3</div>
                <h3>Complete Securely</h3>
                <p>Protected payments, verified delivery, escrow protection. Build your reputation with every transaction.</p>
              </div>
            </div>
          </div>

        </div>
      </section>

      {/* ======== INDUSTRY IMPACT SECTION ======== */}
      <section className="industry-section">
        <div className="industry-content">
          <div className="industry-stats">
            <div className="stat-item">
              <div className="stat-number">Free Shipping</div>
              <div className="stat-label">On Orders Over $500</div>
            </div>
            <div className="stat-item">
              <div className="stat-number">Easy Returns</div>
              <div className="stat-label">30-Day Policy</div>
            </div>
            <div className="stat-item">
              <div className="stat-number">Refund Policy</div>
              <div className="stat-label">8-14 Days</div>
            </div>
            <div className="stat-item">
              <div className="stat-number">Secure Payment</div>
              <div className="stat-label">100% Protected</div>
            </div>
          </div>
          <div className="industry-text">
            <h2>Serving Every Industry</h2>
            <p>
              Agriculture, real estate, filmmaking, construction, inspections, surveying—Flyhub powers drone 
              operations across every sector with specialized tools, certified professionals, and industry-specific solutions.
            </p>
          </div>
        </div>
      </section>

     {/* ======== MORE THAN MARKETPLACE - REDESIGNED ======== */}
<section className="more-section">
  <h2 className="section-title">More Than Just a Marketplace</h2>
  <p className="more-section-subtitle">
    Discover the complete drone ecosystem designed to elevate your aerial experience
  </p>
  <div className="more-grid">
    <div className="more-card">
      <div className="more-card-image">
        <img src={communityImage} alt="Drone pilot community" />
        <div className="more-card-badge">Community</div>
      </div>
      <div className="more-card-content">
        <h3>Thrive in Community</h3>
        <p>
          Join the largest drone community with forums, local meetups, skill-sharing groups, and collaboration 
          opportunities. Network with industry leaders and find flight partners for your next big project.
        </p>
        <ul className="more-card-features">
          <li>Active forums with 50K+ members</li>
          <li>Local meetups and events</li>
          <li>Skill-sharing workshops</li>
        </ul>
      </div>
    </div>
    <div className="more-card">
      <div className="more-card-image">
        <img src={jobImage} alt="Drone pilot career opportunities" />
        <div className="more-card-badge">Careers</div>
      </div>
      <div className="more-card-content">
        <h3>Launch Your Career</h3>
        <p>
          #1 platform for drone jobs. Businesses post full-time, freelance, and contract positions. 
          Certified pilots get matched with opportunities in film, agriculture, infrastructure, and more.
        </p>
        <ul className="more-card-features">
          <li>500+ active job postings</li>
          <li>Career development resources</li>
          <li>Direct employer connections</li>
        </ul>
      </div>
    </div>
  </div>
</section>

    </main>
  );
};

export default About;