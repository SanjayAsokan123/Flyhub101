import React from 'react';
import { FaCheckCircle, FaMobileAlt, FaShieldAlt, FaUsers } from 'react-icons/fa';
import '../styles/Appinfo.css';
const AppInfo = () => {
  const appFeatures = [
    {
      icon: <FaMobileAlt />,
      title: "Mobile App",
      description: "Available on Android with easy-to-use interface"
    },
    {
      icon: <FaShieldAlt />,
      title: "Secure Platform",
      description: "Verified users and secure transactions"
    },
    {
      icon: <FaUsers />,
      title: "Community",
      description: "Connect with drone enthusiasts and professionals"
    },
    {
      icon: <FaCheckCircle />,
      title: "Quality Assurance",
      description: "All products and services go through verification"
    }
  ];

  const appSteps = [
    {
      step: "1",
      title: "Download App",
      description: "Get FlyHub from Google Play Store"
    },
    {
      step: "2",
      title: "Create Profile",
      description: "Set up your account as buyer or seller"
    },
    {
      step: "3",
      title: "Explore",
      description: "Browse products, services, jobs, and training"
    },
    {
      step: "4",
      title: "Connect",
      description: "Start buying, selling, or offering services"
    }
  ];

  return (
    <section className="app-info" id="download">
      <div className="container">
        <div className="app-info-content">
          <div className="app-features">
            <h2>Why Choose FlyHub App?</h2>
            <div className="features-list">
              {appFeatures.map((feature, index) => (
                <div key={index} className="feature-item">
                  <div className="feature-icon">{feature.icon}</div>
                  <div>
                    <h4>{feature.title}</h4>
                    <p>{feature.description}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
          
          <div className="app-steps">
            <h2>How It Works</h2>
            <div className="steps-grid">
              {appSteps.map((step, index) => (
                <div key={index} className="step-card">
                  <div className="step-number">{step.step}</div>
                  <h4>{step.title}</h4>
                  <p>{step.description}</p>
                </div>
              ))}
            </div>
            
            <div className="download-section">
              <h3>Download Now</h3>
              <a 
                href="https://play.google.com/store/apps" 
                target="_blank" 
                rel="noopener noreferrer"
                className="download-btn"
              >
                <span>Available on</span>
                <span className="store-name">Google Play</span>
              </a>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};

export default AppInfo;