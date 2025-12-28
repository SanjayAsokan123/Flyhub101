import React from 'react';
import '../styles/Categories.css';

const Categories = () => {
  const partsAndAccessories = [
    {
      title: "Propulsion & Power",
      icon: "⚙️",
      items: ["Propellers", "Brushless Motors", "ESC Controllers", "Batteries & Chargers", "Power Distribution"]
    },
    {
      title: "Camera Systems",
      icon: "📷",
      items: ["4K/6K Cameras", "Gimbal Stabilizers", "FPV Cameras", "Lens Filters", "Thermal Imaging"]
    },
    {
      title: "Controllers & FPV",
      icon: "🎮",
      items: ["Radio Controllers", "FPV Goggles", "Transmitters", "Receivers", "Antennas"]
    },
    {
      title: "Frames & Structures",
      icon: "🔧",
      items: ["Carbon Fiber Frames", "Motor Mounts", "Landing Gear", "Protection Guards", "Carrying Cases"]
    },
    {
      title: "Sensors & Navigation",
      icon: "📍",
      items: ["GPS Modules", "Obstacle Sensors", "Compass Modules", "Altimeters", "RTK Systems"]
    },
    {
      title: "Tools & Maintenance",
      icon: "🛠️",
      items: ["Screw Sets", "Soldering Kits", "Calibration Tools", "Cleaning Kits", "Diagnostic Tools"]
    }
  ];

  return (
    <section className="categories" id="categories">
      <div className="container">
        <div className="categories-header">
          <h2 className="section-title">Drone Parts & Accessories</h2>
          <p className="section-subtitle">Premium components for every drone enthusiast and professional</p>
          <div className="section-divider"></div>
        </div>
        
        <div className="categories-grid">
          {partsAndAccessories.map((category, index) => (
            <div key={index} className="category-card" style={{ animationDelay: `${index * 100}ms` }}>
              <div className="category-icon">{category.icon}</div>
              <h3 className="category-title">{category.title}</h3>
              <ul className="category-list">
                {category.items.map((item, idx) => (
                  <li key={idx} className="category-item">
                    <span className="item-bullet">•</span>
                    {item}
                  </li>
                ))}
              </ul>
              <div className="category-hover-overlay"></div>
            </div>
          ))}
        </div>
        
        <div className="categories-footer">
          <p className="availability-note">All parts available with 1-year warranty & technical support</p>
          <button className="cta-button">View Complete Catalog</button>
        </div>
      </div>
    </section>
  );
};

export default Categories;