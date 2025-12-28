import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { FaGooglePlay, FaBars, FaTimes } from 'react-icons/fa';
import '../styles/Navbar.css';

const Navbar = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);

  const toggleMenu = () => {
    setIsMenuOpen(!isMenuOpen);
  };

  const closeMenu = () => {
    setIsMenuOpen(false);
  };

  return (
    <nav className="navbar">
      <div className="nav-container">
        {/* Logo */}
        <div className="logo">
          <Link to="/" onClick={closeMenu}>
            <img 
              src="/flyHub_logo.svg" 
              alt="FlyHub Logo" 
              className="logo-image" 
            />
          </Link>
        </div>

        {/* Mobile Menu Button */}
        <button 
          className="menu-toggle" 
          onClick={toggleMenu}
          aria-label="Toggle menu"
        >
          {isMenuOpen ? <FaTimes /> : <FaBars />}
        </button>

        {/* Navigation Links & Button */}
        <div className={`nav-content ${isMenuOpen ? 'active' : ''}`}>
          <div className="nav-links">
            <Link to="/" onClick={closeMenu}>Home</Link>
            <Link to="/features" onClick={closeMenu}>Features</Link>
            <Link to="/categories" onClick={closeMenu}>Categories</Link>
            <Link to="/franchise" onClick={closeMenu}>Franchise</Link>
          
          </div>
          
          <a 
            href="https://play.google.com/store/apps" 
            target="_blank" 
            rel="noopener noreferrer"
            className="play-store-btn"
            onClick={closeMenu}
          >
            <FaGooglePlay className="play-icon" />
            <span className="play-text">Get on Google Play</span>
          </a>
        </div>

        {/* Overlay for mobile when menu is open */}
        {isMenuOpen && (
          <div className="menu-overlay" onClick={closeMenu}></div>
        )}
      </div>
    </nav>
  );
};

export default Navbar;