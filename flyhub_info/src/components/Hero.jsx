import React from 'react';
import { FaShoppingCart, FaStore, FaCheckCircle, FaUsers, FaShieldAlt, FaChartLine, FaSearch, FaTag, FaHandshake } from 'react-icons/fa';
import '../hero.css';

const Hero = () => {
  return (
    <section className="hero" id="home">
      <div className="hero-container">
        <div className="hero-content">
          <div className="header-badge">
            <span className="badge">DRONE MARKETPLACE</span>
          </div>
          <h1>FlyHub Professional Drone Platform</h1>
          <p className="subtitle">
            Streamlined marketplace connecting drone buyers, sellers, and service providers
          </p>
          <p className="description">
            Enterprise-grade platform for commercial drone transactions, services, and networking. 
            Secure, verified, and built for professionals in the drone industry.
          </p>
          
          <div className="hero-stats">
            <div className="stat">
              <div className="stat-number">1K+</div>
              <div className="stat-label">Verified Listings</div>
            </div>
            <div className="stat">
              <div className="stat-number">500+</div>
              <div className="stat-label">Professional Users</div>
            </div>
            <div className="stat">
              <div className="stat-number">50+</div>
              <div className="stat-label">Service Providers</div>
            </div>
            <div className="stat">
              <div className="stat-number">24/7</div>
              <div className="stat-label">Support</div>
            </div>
          </div>
        </div>
        
        <div className="platform-roles">
          <div className="section-header">
            <h2>Choose Your Role</h2>
            <p className="section-subtitle">Professional platform for every drone industry participant</p>
          </div>
          
          <div className="roles-grid">
            <div className="role-card buyer-role">
              <div className="role-header">
                <div className="role-icon buyer-icon">
                  <FaShoppingCart />
                </div>
                <div className="role-title">
                  <h3>Professional Buyer</h3>
                  <span className="role-badge">For Individuals & Businesses</span>
                </div>
              </div>
              
              <div className="role-features">
                <div className="feature-item">
                  <FaCheckCircle className="feature-check" />
                  <span>Access verified drone inventory</span>
                </div>
                <div className="feature-item">
                  <FaSearch className="feature-check" />
                  <span>Advanced filtering & comparison tools</span>
                </div>
                <div className="feature-item">
                  <FaShieldAlt className="feature-check" />
                  <span>Secure enterprise transactions</span>
                </div>
                <div className="feature-item">
                  <FaHandshake className="feature-check" />
                  <span>Direct negotiation with sellers</span>
                </div>
              </div>
              
              <div className="role-description">
                Source commercial drones, parts, and professional services with 
                complete transparency and enterprise-grade security.
              </div>
              
              <div className="role-cta">
                <button className="cta-button primary">
                  <FaShoppingCart /> Start Buying
                </button>
                <a href="#buyer-benefits" className="learn-more">
                  Learn more about buying →
                </a>
              </div>
            </div>
            
            <div className="role-card seller-role">
              <div className="role-header">
                <div className="role-icon seller-icon">
                  <FaStore />
                </div>
                <div className="role-title">
                  <h3>Professional Seller</h3>
                  <span className="role-badge">For Suppliers & Service Providers</span>
                </div>
              </div>
              
              <div className="role-features">
                <div className="feature-item">
                  <FaChartLine className="feature-check" />
                  <span>Reach qualified professional buyers</span>
                </div>
                <div className="feature-item">
                  <FaTag className="feature-check" />
                  <span>Advanced inventory management</span>
                </div>
                <div className="feature-item">
                  <FaShieldAlt className="feature-check" />
                  <span>Verified seller certification</span>
                </div>
                <div className="feature-item">
                  <FaUsers className="feature-check" />
                  <span>Direct client communication</span>
                </div>
              </div>
              
              <div className="role-description">
                Showcase your products and services to serious buyers with 
                professional tools for inventory, pricing, and customer management.
              </div>
              
              <div className="role-cta">
                <button className="cta-button secondary">
                  <FaStore /> Start Selling
                </button>
                <a href="#seller-benefits" className="learn-more">
                  Learn more about selling →
                </a>
              </div>
            </div>
          </div>
          
          <div className="platform-benefits">
            <div className="benefit-item">
              <div className="benefit-icon">
                <FaShieldAlt />
              </div>
              <div className="benefit-content">
                <h4>Enterprise Security</h4>
                <p>Bank-level encryption and secure payment processing</p>
              </div>
            </div>
            <div className="benefit-item">
              <div className="benefit-icon">
                <FaUsers />
              </div>
              <div className="benefit-content">
                <h4>Verified Community</h4>
                <p>All users undergo professional verification process</p>
              </div>
            </div>
            <div className="benefit-item">
              <div className="benefit-icon">
                <FaCheckCircle />
              </div>
              <div className="benefit-content">
                <h4>Quality Assurance</h4>
                <p>Rigorous product verification and quality checks</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default Hero;