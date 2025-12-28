import React from 'react';
import { FaCheckCircle, FaMobileAlt, FaShieldAlt, FaUsers, FaGooglePlay, FaArrowRight, FaStar, FaRocket, FaClock, FaHandshake } from 'react-icons/fa';
import '../styles/Appinfo.css';

const AppInfo = () => {
  const appFeatures = [
    {
      icon: <FaMobileAlt />,
      title: "Intuitive Mobile App",
      description: "Streamlined interface designed for drone enthusiasts with zero learning curve",
      highlight: "98% User Satisfaction"
    },
    {
      icon: <FaShieldAlt />,
      title: "Bank-Level Security",
      description: "Advanced encryption and multi-factor authentication protect all transactions",
      highlight: "100% Secure Platform"
    },
    {
      icon: <FaUsers />,
      title: "Thriving Community",
      description: "Connect with 50,000+ drone pilots, sellers, and service providers worldwide",
      highlight: "50K+ Active Users"
    },
    {
      icon: <FaHandshake />,
      title: "Verified Network",
      description: "Every seller, pilot, and service provider undergoes rigorous verification",
      highlight: "100% Verified"
    }
  ];

  const appSteps = [
    {
      step: "1",
      title: "Download App",
      description: "Get FlyHub from Google Play Store",
      detail: "Free download, no hidden fees"
    },
    {
      step: "2",
      title: "Create Profile",
      description: "Set up your account as buyer or seller",
      detail: "Quick 2-minute registration"
    },
    {
      step: "3",
      title: "Explore",
      description: "Browse products, services, jobs, and training",
      detail: "Personalized recommendations"
    },
    {
      step: "4",
      title: "Connect",
      description: "Start buying, selling, or offering services",
      detail: "Direct messaging system"
    }
  ];

  return (
    <section className="app-info" id="download">
      <div className="container">
        <div className="section-header">
          <h2>Experience FlyHub on Your Mobile</h2>
          <p>The complete drone ecosystem in your pocket. Download now and join thousands of drone enthusiasts.</p>
        </div>
        
        <div className="app-info-content">
          <div className="app-visual">
            {/* Phone mockup with floating elements inside */}
            <div className="phone-container">
              <div className="phone-mockup">
                <div className="phone-frame">
                  <div className="phone-screen">
                    {/* Replace placeholder with your app image */}
                    <img 
                      src="/images/screenshot.jpeg" 
                      alt="FlyHub App Screenshot" 
                      className="app-screenshot"
                    />
                  </div>
                </div>
                
                {/* Floating elements now inside phone container */}
                <div className="floating-elements">
                  <div className="float-element element-1">
                    <FaStar className="element-icon" />
                    <span>4.8 Rating</span>
                  </div>
                  <div className="float-element element-2">
                    <FaUsers className="element-icon" />
                    <span>50K+ Users</span>
                  </div>
                  <div className="float-element element-3">
                    <FaShieldAlt className="element-icon" />
                    <span>Secure</span>
                  </div>
                </div>
              </div>
            </div>
            
            {/* Download section directly below phone */}
            <div className="download-section bottom-position">
              <h3>Download Now</h3>
              <p>Get the FlyHub app and take your drone experience to the next level</p>
              <a 
                href="https://play.google.com/store/apps" 
                target="_blank" 
                rel="noopener noreferrer"
                className="download-btn"
              >
                <FaGooglePlay className="play-icon" />
                <div className="btn-text">
                  <span>Get it on</span>
                  <span className="store-name">Google Play</span>
                </div>
                <FaArrowRight className="btn-arrow" />
              </a>
            </div>
          </div>
          
          <div className="app-details">
            <div className="app-features">
              <h3>Why Choose FlyHub App?</h3>
              <div className="features-list">
                {appFeatures.map((feature, index) => (
                  <div key={index} className="feature-item">
                    <div className="feature-icon">{feature.icon}</div>
                    <div className="feature-content">
                      <h4>{feature.title}</h4>
                      <p>{feature.description}</p>
                      <span className="feature-highlight">{feature.highlight}</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
        
        <div className="app-steps">
          <h3>How It Works</h3>
          <div className="steps-container">
            {appSteps.map((step, index) => (
              <div key={index} className="step-item">
                <div className="step-connector"></div>
                <div className="step-card">
                  <div className="step-number">{step.step}</div>
                  <h4>{step.title}</h4>
                  <p>{step.description}</p>
                  <span className="step-detail">{step.detail}</span>
                </div>
              </div>
            ))}
          </div>
        </div>
        </div>
    </section>
  );
};

export default AppInfo;