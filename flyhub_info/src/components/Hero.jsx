// Hero.jsx - Updated with feature highlights
import React from 'react';
import '../styles/hero.css';

const Hero = () => {
  return (
    <section className="hero" id="home">
      <div className="hero-container">
        <div className="hero-content">
          <div className="header-badge">
           
          </div>
          <h1>Flyhub Professional Drone Platform</h1>
          <p className="subtitle">
            Streamlined marketplace connecting drone buyers, sellers, and service providers
          </p>
          <p className="description">
            Enterprise-grade platform for commercial drone transactions, services, and networking. 
            Secure, verified, and built for professionals in the drone industry.
          </p>

          {/* Feature Highlights */}
          <div className="hero-features">
            <div className="feature-item">
              <div className="feature-icon">🛒</div>
              <div className="feature-text">
                <h3>Buy, Sell, or Rent Drones</h3>
                <p>Access thousands of verified drone listings and connect with sellers</p>
              </div>
            </div>
            <div className="feature-item">
              <div className="feature-icon">💼</div>
              <div className="feature-text">
                <h3>Find Drone Job Opportunities</h3>
                <p>Discover pilot roles, service gigs, and professional opportunities</p>
              </div>
            </div>
            <div className="feature-item">
              <div className="feature-icon">📋</div>
              <div className="feature-text">
                <h3>Stay Updated with Drone Rules</h3>
                <p>Get latest regulations, compliance updates, and industry guidelines</p>
              </div>
            </div>
          </div>

          {/* Tagline */}
          <div className="hero-tagline">
            <h2>Everything about drones, in one place.</h2>
          </div>
          </div>
        </div>
    </section>
  );
};

export default Hero;