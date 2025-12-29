import React from 'react';
import '../styles/Categories.css';

const Categories = () => {
  const categories = [
    {
      title: "Drones",
      description: "Explore our comprehensive range of drones for every need and skill level",
      image: "https://images.unsplash.com/photo-1527977966376-1c8408f9f108?q=80&w=580&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
      fallbackImage: "https://images.unsplash.com/photo-1527977966376-1c8408f9f108?q=80&w=580&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
      items: [
        "Consumer Drones - Perfect for hobbyists and beginners",
        "Professional Drones - For commercial photography",
        "Industrial Drones - Heavy-duty for inspections",
        "Racing Drones - High-speed FPV competitions"
      ],
    },
    {
      title: "Parts & Accessories",
      description: "Genuine parts and premium accessories to enhance your drone experience",
      image: "https://images.unsplash.com/photo-1593941707882-a5bba5338fe2?ixlib=rb-4.1.0&auto=format&fit=crop&w=580&q=80",
      fallbackImage: "https://images.unsplash.com/photo-1555255707-c07966088b7b?ixlib=rb-4.1.0&auto=format&fit=crop&w=580&q=80",
      items: [
        "Propellers - High-performance blades",
        "Batteries - Extended flight time",
        "Controllers - Professional remotes",
        "Cameras - Upgrade capabilities",
        "Gimbals - Smooth stabilization"
      ],
      color: "#8b5cf6"
    },
    {
      title: "Services",
      description: "Professional drone services for commercial and industrial applications",
      image: "https://images.unsplash.com/photo-1504890001746-a9a68eda46e2?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OHx8ZHJvbmV8ZW58MHx8MHx8fDA%3D",
      fallbackImage: "https://images.unsplash.com/photo-1504890001746-a9a68eda46e2?w=600&auto=format&fit=crop&q=60&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OHx8ZHJvbmV8ZW58MHx8MHx8fDA%3D",
      items: [
        "Aerial Photography - Stunning visuals",
        "Drone Survey - Precision mapping",
        "Inspections - Infrastructure checks",
        "Mapping - 3D modeling",
        "Training - Pilot certification"
      ],
      color: "#10b981"
    }
  ];

  const handleImageError = (e, fallbackImage) => {
    e.target.onerror = null;
    e.target.src = fallbackImage;
  };

  return (
    <section className="flyhub-categories-section" id="categories">
      <div className="flyhub-categories-container">
        <div className="flyhub-categories-header">
          <h2>Complete Drone Ecosystem</h2>
          <p className="flyhub-categories-subtitle">
            Discover everything you need for successful drone operations
          </p>
        </div>
        
        <div className="flyhub-categories-grid">
          {categories.map((category, index) => (
            <div 
              key={index} 
              className="flyhub-categories-card"
              style={{ '--category-color': category.color }}
            >
              <div className="flyhub-categories-image-container">
                <img 
                  src={category.image} 
                  alt={category.title}
                  loading="lazy"
                  onError={(e) => handleImageError(e, category.fallbackImage)}
                  className="flyhub-categories-img"
                />
                <div className="flyhub-categories-badge" style={{ backgroundColor: category.color }}>
                  {category.title}
                </div>
              </div>
              
              <div className="flyhub-categories-content">
                <h3>{category.title}</h3>
                <p className="flyhub-categories-description">{category.description}</p>
                
                <div className="flyhub-categories-items">
                  <ul>
                    {category.items.map((item, idx) => (
                      <li key={idx} className="flyhub-categories-item">
                        <span className="flyhub-categories-item-bullet" style={{ color: category.color }}>•</span>
                        {item}
                      </li>
                    ))}
                  </ul>
                </div>
              </div>
            </div>
          ))}
        </div>
        
        <div className="flyhub-categories-cta">
          <h3>Need Custom Solutions?</h3>
          <p>Our experts can help you find the perfect products and services tailored to your specific requirements</p>
        </div>
      </div>
    </section>
  );
};

export default Categories;