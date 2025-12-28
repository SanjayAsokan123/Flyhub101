import React from 'react';
import { FaGooglePlay } from 'react-icons/fa';
import '../styles/Footer.css';

const Footer = () => {
  return (
    <footer className="footer">
      <div className="container">
        <div className="footer-content">
          <div className="footer-section">
            {/* Logo replaces the h3 text */}
            <img src="/images/flyhubicon.svg" alt="FlyHub Logo" className="footer-logo" />
            <p>Your one-stop solution for all drone-related needs. Marketplace, services, jobs, and training.</p>
          </div>
          
          <div className="footer-section">
            <h4>Quick Links</h4>
            <ul>
              <li><a href="#home">Home</a></li>
              <li><a href="#features">Features</a></li>
              <li><a href="#categories">Categories</a></li>
              <li><a href="#download">Download</a></li>
            </ul>
          </div>
          
          <div className="footer-section">
            <h4>Contact</h4>
            <ul>
              <li>Email: info@flyhub.com</li>
              <li>Phone: +91 9876543210</li>
              <li>Location: India</li>
            </ul>
          </div>
          
          <div className="footer-section">
            <h4>Get Our App</h4>
            <a href="https://play.google.com/store" target="_blank" rel="noopener noreferrer" className="google-play-link">
              <div className="google-play-badge">
                <FaGooglePlay className="google-play-icon" />
                <div className="google-play-text">
                  <span className="google-play-small">GET IT ON</span>
                  <span className="google-play-large">Google Play</span>
                </div>
              </div>
            </a>
          </div>
        </div>
        
        <div className="footer-bottom">
          <p>&copy; 2024 Flyhub. All rights reserved.</p>
          <p>Designed for drone enthusiasts and professionals</p>
        </div>
      </div>
    </footer>
  );
};

export default Footer;