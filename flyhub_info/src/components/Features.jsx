import React from 'react';
import { FaShoppingCart, FaBriefcase, FaGraduationCap, FaUserTie, FaTools, FaCar, FaArrowRight } from 'react-icons/fa';
import '../styles/Features.css';

const Features = () => {
  const features = [
    {
      title: "Marketplace",
      description: "Buy and sell drones, parts, and accessories from verified sellers",
      userBenefits: "Perfect for: Drone enthusiasts, commercial operators, and equipment suppliers",
      bgImage: "https://images.unsplash.com/photo-1532989029401-439615f3d4b4?q=80&w=688&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
    },
    {
      title: "Job Portal",
      description: "Find drone-related jobs and hire professional pilots",
      userBenefits: "Ideal for: Pilots seeking work and companies needing certified operators",
      bgImage: "https://images.unsplash.com/photo-1552664730-d307ca884978",
    },
    {
      title: "Training",
      description: "Get certified with professional drone training courses",
      userBenefits: "Essential for: New pilots, farmers, and industry professionals",
      bgImage: "https://images.unsplash.com/photo-1733222765056-b0790217baa9?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8dHJhaW5pbmclMjBjb3Vyc2UlMjBpbWFnZXN8ZW58MHx8MHx8fDA%3D",
    },
    {
      title: "Pilot Directory",
      description: "Connect with certified drone pilots for hire",
      userBenefits: "Trusted by: Farmers, real estate agents, and construction managers",
      bgImage: "https://plus.unsplash.com/premium_photo-1664475382326-3dc5510e4ff9?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8ZHJvbmUlMjBwaWxvdHxlbnwwfHwwfHx8MA%3D%3D",
    },
    {
      title: "Services",
      description: "Aerial photography, surveying, inspection services",
      userBenefits: "Used by: Farmers for crop analysis, surveyors, and filmmakers",
      bgImage: "https://plus.unsplash.com/premium_photo-1714618854833-3445b52019d8?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MXx8ZHJvbmUlMjBzZXJ2aWNlc3xlbnwwfHwwfHx8MA%3D%3D",
    },
    {
      title: "Rentals",
      description: "Rent drones and equipment for short-term projects",
      userBenefits: "Great for: Farmers during harvest season, event organizers, and filmmakers",
      bgImage: "https://images.unsplash.com/photo-1577110668630-c7e3e9b3acd6?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Nnx8ZHJvbmUlMjByZW50YWxzfGVufDB8fDB8fHww",
    }
  ];

  return (
    <section className="features" id="features">
      <div className="container">
        <h2>What Flyhub Offers</h2>        
        <div className="features-grid">
          {features.map((feature, index) => (
            <div key={index} className="feature-card" style={{ backgroundImage: `url(${feature.bgImage})` }}>
              <div className="feature-overlay">
                <div className="feature-content">
                  <h3>{feature.title}</h3>
                  <p>{feature.description}</p>
                  <div className="user-benefits">
                    <span>{feature.userBenefits}</span>
                  </div>
                 
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default Features;