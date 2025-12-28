import React from 'react';
import { FaGooglePlay } from 'react-icons/fa';

const Navbar = () => {
  return (
    <nav className="navbar">
      <div className="nav-container">
        <div className="logo">
          <img src="/flyHub_logo.svg" alt="FlyHub Logo" className="logo-image" />
        </div>
        <div className="nav-links">
          <a href="#home">Home</a>
          <a href="#features">Features</a>
          <a href="#categories">Categories</a>
          <a href="#download">Download</a>
        </div>
        <a 
          href="https://play.google.com/store/apps" 
          target="_blank" 
          rel="noopener noreferrer"
          className="play-store-btn"
        >
          <FaGooglePlay className="play-icon" />
          <span className="play-text">Get on Google Play</span>
        </a>
      </div>
    </nav>
  );
};

export default Navbar;