import React from 'react';
import { FaGooglePlay, FaInstagram, FaWhatsapp, FaFacebookF, FaLinkedinIn, FaEnvelope, FaPhone, FaMapMarkerAlt } from 'react-icons/fa';
import { Link } from 'react-router-dom';
import '../styles/Footer.css';

const Footer = () => {
  return (
    <footer className="footer">
      <div className="container">
        <div className="footer-content">
          <div className="footer-section">
            <img src="/images/flyhubicon.svg" alt="FlyHub Logo" className="footer-logo" />
            <p className="footer-description">
              Your one-stop solution for all drone-related needs. Marketplace, services, jobs, and training.
            </p>
            <div className="social-icons">
              <a href="https://www.instagram.com/flyhub_info?igsh=OWM2a3E2Ym81bzRs" target="_blank" rel="noopener noreferrer" className="social-icon" aria-label="Instagram">
                <FaInstagram />
              </a>
              <a href="https://whatsapp.com/channel/0029VbCWqYHJP219qPZVns0P" target="_blank" rel="noopener noreferrer" className="social-icon" aria-label="WhatsApp">
                <FaWhatsapp />
              </a>
              <a href="https://www.facebook.com/share/1A8fBiqxmt/'" target="_blank" rel="noopener noreferrer" className="social-icon" aria-label="Facebook">
                <FaFacebookF />
              </a>
              <a href="https://www.linkedin.com/company/flyhubinfo/" target="_blank" rel="noopener noreferrer" className="social-icon" aria-label="LinkedIn">
                <FaLinkedinIn />
              </a>
            </div>
          </div>
          
          <div className="footer-section">
            <h4>Quick Links</h4>
            <ul>
              <li><Link to="/">Home</Link></li>
               <li><Link to="/franchise">Franchise</Link></li>
              <li><Link to="/features">Features</Link></li>
              <li><Link to="/categories">Categories</Link></li>
              <li><Link to="/about-us">About Us</Link></li>
                <li><Link to="/contact">Contact</Link></li>
            </ul>
          </div>
          
          <div className="footer-section">
            <h4>Contact & Legal</h4>
            <ul>
              <li className="contact-item">
                <FaEnvelope className="contact-icon" />
                <span>info@flyhub.com</span>
              </li>
              <li className="contact-item">
                <FaPhone className="contact-icon" />
                <span>+91 9003992693</span>
              </li>
              <li className="contact-item">
                <FaMapMarkerAlt className="contact-icon" />
                <span>Manickampalayam, Tiruchengode, Tamil Nadu 637202</span>
              </li>
              <li className="legal-links">
                <Link to="/terms">Terms & Conditions</Link>
                <span className="separator">|</span>
                <Link to="/privacy">Privacy Policy</Link>
              </li>
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
          <p>&copy; 2025 Flyhub. All rights reserved.</p>
          <p className="design-credit">Designed for drone enthusiasts and professionals</p>
        </div>
      </div>
    </footer>
  );
};

export default Footer;