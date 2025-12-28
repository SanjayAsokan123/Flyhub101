import React from 'react';
import { FaShoppingCart, FaBriefcase, FaGraduationCap, FaUserTie, FaTools, FaCar } from 'react-icons/fa';
import '../styles/Features.css';
const Features = () => {
  const features = [
    {
      icon: <FaShoppingCart />,
      title: "Marketplace",
      description: "Buy and sell drones, parts, and accessories from verified sellers"
    },
    {
      icon: <FaBriefcase />,
      title: "Job Portal",
      description: "Find drone-related jobs and hire professional pilots"
    },
    {
      icon: <FaGraduationCap />,
      title: "Training",
      description: "Get certified with professional drone training courses"
    },
    {
      icon: <FaUserTie />,
      title: "Pilot Directory",
      description: "Connect with certified drone pilots for hire"
    },
    {
      icon: <FaTools />,
      title: "Services",
      description: "Aerial photography, surveying, inspection services"
    },
    {
      icon: <FaCar />,
      title: "Rentals",
      description: "Rent drones and equipment for short-term projects"
    }
  ];

  return (
    <section className="features" id="features">
      <div className="container">
        <h2>What FlyHub Offers</h2>
        <p className="section-subtitle">Comprehensive drone ecosystem for all your needs</p>
        
        <div className="features-grid">
          {features.map((feature, index) => (
            <div key={index} className="feature-card">
              <div className="feature-icon">{feature.icon}</div>
              <h3>{feature.title}</h3>
              <p>{feature.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default Features;