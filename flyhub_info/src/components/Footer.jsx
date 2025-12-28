import React from 'react';

const Footer = () => {
  return (
    <footer className="footer">
      <div className="container">
        <div className="footer-content">
          <div className="footer-section">
            <h3>FlyHub</h3>
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
        </div>
        
        <div className="footer-bottom">
          <p>&copy; 2024 FlyHub. All rights reserved.</p>
          <p>Designed for drone enthusiasts and professionals</p>
        </div>
      </div>
    </footer>
  );
};

export default Footer;