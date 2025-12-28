import React from 'react';

const Categories = () => {
  const categories = [
    {
      title: "Drones",
      items: ["Consumer Drones", "Professional Drones", "Industrial Drones", "Racing Drones"]
    },
    {
      title: "Parts & Accessories",
      items: ["Propellers", "Batteries", "Controllers", "Cameras", "Gimbals"]
    },
    {
      title: "Services",
      items: ["Aerial Photography", "Drone Survey", "Inspections", "Mapping", "Training"]
    },
    {
      title: "Professional",
      items: ["Pilot Hiring", "Job Listings", "Consultation", "Equipment Rental"]
    }
  ];

  return (
    <section className="categories" id="categories">
      <div className="container">
        <h2>Product & Service Categories</h2>
        <p className="section-subtitle">Explore our wide range of drone-related offerings</p>
        
        <div className="categories-grid">
          {categories.map((category, index) => (
            <div key={index} className="category-card">
              <h3>{category.title}</h3>
              <ul>
                {category.items.map((item, idx) => (
                  <li key={idx}>{item}</li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default Categories;