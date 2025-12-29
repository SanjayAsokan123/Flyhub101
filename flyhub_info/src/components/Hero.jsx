import React from 'react';
import '../styles/hero.css';

const Hero = () => {
  return (
    <section className="hero" id="home">
      <div className="hero__container">
        <div className="hero__content">
          <div className="hero__badge">
            {/* Add badge content here if needed */}
          </div>
          <h1 className="hero__title">Flyhub Professional Drone Platform</h1>
          <p className="hero__subtitle">
            Streamlined marketplace connecting drone buyers, sellers, and service providers
          </p>
          {/* Buy, Sell, or Rent Drones Feature */}
          <div className="hero__feature-highlight">
            <div className="hero__feature-text">
              <h3 className="hero__feature-title">Buy, Sell, or Rent Drones</h3>
              <p className="hero__feature-desc">Access thousands of verified drone listings and connect with sellers</p>
            </div>
          </div>

          {/* Other Features */}
          <div className="hero__features">
            <div className="hero__feature">
              <div className="hero__feature-text">
                <h3 className="hero__feature-title">Find Drone Job Opportunities</h3>
                <p className="hero__feature-desc">Discover pilot roles, service gigs, and professional opportunities</p>
              </div>
            </div>
            <div className="hero__feature">
              <div className="hero__feature-text">
                <h3 className="hero__feature-title">Stay Updated with Drone Rules</h3>
                <p className="hero__feature-desc">Get latest regulations, compliance updates, and industry guidelines</p>
              </div>
            </div>
          </div>
        </div>

        {/* Phone Mockup with Floating Badges */}
        <div className="hero__mockup">
          {/* Floating Badges */}
          <div className="hero__floating-badges">
            <div className="hero__floating-badge hero__floating-badge--1">
              <span className="hero__badge-text">Buy/Sell Drones</span>
            </div>
            <div className="hero__floating-badge hero__floating-badge--2">
              <span className="hero__badge-text">Drones Marketplace</span>
            </div>
            <div className="hero__floating-badge hero__floating-badge--3">
              <span className="hero__badge-text">Verified Sellers</span>
            </div>
            <div className="hero__floating-badge hero__floating-badge--4">
              <span className="hero__badge-text">Rent a Drone</span>
            </div>
            <div className="hero__floating-badge hero__floating-badge--5">
              <span className="hero__badge-text">Secure Payments</span>
            </div>
          </div>

          <div className="hero__phone">
            <div className="hero__phone-frame">
              <div className="hero__phone-screen">
                {/* Using public folder path */}
                <img 
                  src="images/screenshot1.jpg" 
                  alt="Flyhub Drone App Screenshot" 
                  className="hero__app-screenshot"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default Hero;