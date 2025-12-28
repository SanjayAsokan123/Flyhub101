import React, { useState } from 'react';
import { 
  FaBusinessTime, 
  FaUserTie, 
  FaChartLine, 
  FaShieldAlt, 
  FaHandshake, 
  FaMoneyCheckAlt,
  FaHeadset,
  FaCalendarAlt,
  FaCheckCircle,
  FaRocket,
  FaBuilding,
  FaUsers,
  FaCertificate,
  FaGlobeAmericas,
  FaLightbulb,
  FaAward
} from 'react-icons/fa';
import '../styles/Franchise.css';

const Franchise = () => {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    city: '',
    experience: '',
    investment: '',
    message: ''
  });

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prevState => ({
      ...prevState,
      [name]: value
    }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    alert('Thank you for your franchise inquiry! Our team will contact you within 24 hours.');
    setFormData({
      name: '',
      email: '',
      phone: '',
      city: '',
      experience: '',
      investment: '',
      message: ''
    });
  };

  const franchiseBenefits = [
    {
      icon: <FaChartLine />,
      title: "Proven Business Model",
      description: "Leverage our successful marketplace platform with established processes"
    },
    {
      icon: <FaShieldAlt />,
      title: "Brand Recognition",
      description: "Join a trusted name in the drone industry with established credibility"
    },
    {
      icon: <FaHandshake />,
      title: "Comprehensive Training",
      description: "Complete training program for operations, sales, and technical support"
    },
    {
      icon: <FaMoneyCheckAlt />,
      title: "Investment Protection",
      description: "Protected territories and competitive ROI with our revenue-sharing model"
    },
    {
      icon: <FaHeadset />,
      title: "Ongoing Support",
      description: "24/7 operational support, marketing assistance, and technical guidance"
    },
    {
      icon: <FaGlobeAmericas />,
      title: "National Network",
      description: "Connect with franchise partners across the country for collaboration"
    }
  ];

  const investmentOptions = [
    {
      level: "Basic",
      investment: "$50,000 - $100,000",
      features: [
        "Single territory rights",
        "Basic training program",
        "Standard marketing kit",
        "Online support",
        "Revenue sharing: 70/30"
      ]
    },
    {
      level: "Professional",
      investment: "$100,000 - $250,000",
      features: [
        "Multiple territory rights",
        "Advanced training program",
        "Premium marketing kit",
        "Dedicated account manager",
        "Revenue sharing: 75/25",
        "Priority technical support"
      ]
    },
    {
      level: "Enterprise",
      investment: "$250,000+",
      features: [
        "Regional master franchise",
        "Complete training ecosystem",
        "Custom marketing solutions",
        "Executive support team",
        "Revenue sharing: 80/20",
        "Tech development input",
        "Brand ambassador program"
      ]
    }
  ];

  return (
    <div className="franchise-page">
      {/* Hero Section */}
      <section className="franchise-hero">
        <div className="container">
          <div className="hero-content">
           
            
            <h1 className="hero-title">
              Own Your Future in the 
              <span className="highlight"> Drone Revolution</span>
            </h1>
            
            <p className="hero-subtitle">
              Join FlyHub as a franchise partner and lead the drone marketplace 
              in your region. Be part of the $100B+ drone industry with our 
              proven business model.
            </p>
            
            <div className="hero-stats">
              <div className="stat">
                <div className="stat-number">300%</div>
                <div className="stat-label">Industry Growth</div>
              </div>
              <div className="stat">
                <div className="stat-number">50+</div>
                <div className="stat-label">Cities Available</div>
              </div>
              <div className="stat">
                <div className="stat-number">24/7</div>
                <div className="stat-label">Support</div>
              </div>
            </div>
            
            <button 
              className="btn btn-primary btn-scroll"
              onClick={() => document.getElementById('apply-form').scrollIntoView({ behavior: 'smooth' })}
            >
              <FaRocket /> Apply Now
            </button>
          </div>
        </div>
      </section>

      {/* Why Franchise Section */}
      <section className="why-franchise">
        <div className="container">
          <div className="section-header">
            <h2>Why Choose FlyHub Franchise?</h2>
            <p className="section-subtitle">
              Join the fastest-growing drone marketplace platform with comprehensive support
            </p>
          </div>
          
          <div className="benefits-grid">
            {franchiseBenefits.map((benefit, index) => (
              <div className="benefit-card" key={index}>
                <div className="benefit-icon">
                  {benefit.icon}
                </div>
                <h3>{benefit.title}</h3>
                <p>{benefit.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Investment Options */}
      <section className="investment-options">
        <div className="container">
          <div className="section-header">
            <h2>Investment Options</h2>
            <p className="section-subtitle">
              Choose the franchise level that matches your ambition and investment capacity
            </p>
          </div>
          
          <div className="investment-grid">
            {investmentOptions.map((option, index) => (
              <div className={`investment-card ${option.level.toLowerCase()}`} key={index}>
                <div className="card-header">
                  <div className="level-badge">{option.level}</div>
                  <div className="investment-amount">{option.investment}</div>
                </div>
                
                <div className="card-body">
                  <ul className="features-list">
                    {option.features.map((feature, idx) => (
                      <li key={idx}>
                        <FaCheckCircle className="feature-check" />
                        {feature}
                      </li>
                    ))}
                  </ul>
                </div>
                
                <div className="card-footer">
                  <button className="btn btn-outline">Learn More</button>
                  <button className="btn btn-primary">Select Plan</button>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Success Stories */}
      <section className="success-stories">
        <div className="container">
          <div className="section-header">
            <h2>Franchise Success Stories</h2>
            <p className="section-subtitle">
              Hear from our successful franchise partners across the country
            </p>
          </div>
          
          <div className="stories-grid">
            <div className="story-card">
              <div className="story-header">
                <div className="avatar">RK</div>
                <div className="story-info">
                  <h4>Rajesh Kumar</h4>
                  <p className="story-location">Mumbai Franchise</p>
                </div>
              </div>
              <div className="story-content">
                <p>
                  "Joining FlyHub was the best business decision I've made. 
                  Within 6 months, we achieved 200% of our revenue targets. 
                  The support system is exceptional."
                </p>
              </div>
              <div className="story-stats">
                <div className="stat">
                  <strong>Revenue Growth:</strong> 300%
                </div>
                <div className="stat">
                  <strong>Time to Profit:</strong> 4 months
                </div>
              </div>
            </div>
            
            <div className="story-card">
              <div className="story-header">
                <div className="avatar">SP</div>
                <div className="story-info">
                  <h4>Sunita Patel</h4>
                  <p className="story-location">Delhi Franchise</p>
                </div>
              </div>
              <div className="story-content">
                <p>
                  "The training and ongoing support from FlyHub gave me the 
                  confidence to succeed. Now I'm expanding to my second territory!"
                </p>
              </div>
              <div className="story-stats">
                <div className="stat">
                  <strong>Customer Satisfaction:</strong> 98%
                </div>
                <div className="stat">
                  <strong>Team Size:</strong> 15+ professionals
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Application Form */}
      <section className="application-form" id="apply-form">
        <div className="container">
          <div className="form-container">
            <div className="form-header">
              <FaCalendarAlt className="form-icon" />
              <h2>Apply for Franchise</h2>
              <p>Fill out the form below and our franchise team will contact you</p>
            </div>
            
            <form onSubmit={handleSubmit} className="franchise-form">
              <div className="form-row">
                <div className="form-group">
                  <label htmlFor="name">Full Name *</label>
                  <input
                    type="text"
                    id="name"
                    name="name"
                    value={formData.name}
                    onChange={handleChange}
                    required
                    placeholder="Enter your full name"
                  />
                </div>
                
                <div className="form-group">
                  <label htmlFor="email">Email Address *</label>
                  <input
                    type="email"
                    id="email"
                    name="email"
                    value={formData.email}
                    onChange={handleChange}
                    required
                    placeholder="Enter your email"
                  />
                </div>
              </div>
              
              <div className="form-row">
                <div className="form-group">
                  <label htmlFor="phone">Phone Number *</label>
                  <input
                    type="tel"
                    id="phone"
                    name="phone"
                    value={formData.phone}
                    onChange={handleChange}
                    required
                    placeholder="Enter your phone number"
                  />
                </div>
                
                <div className="form-group">
                  <label htmlFor="city">City/Region *</label>
                  <input
                    type="text"
                    id="city"
                    name="city"
                    value={formData.city}
                    onChange={handleChange}
                    required
                    placeholder="Enter your city"
                  />
                </div>
              </div>
              
              <div className="form-row">
                <div className="form-group">
                  <label htmlFor="experience">Business Experience</label>
                  <select
                    id="experience"
                    name="experience"
                    value={formData.experience}
                    onChange={handleChange}
                  >
                    <option value="">Select experience level</option>
                    <option value="beginner">Beginner (0-2 years)</option>
                    <option value="intermediate">Intermediate (2-5 years)</option>
                    <option value="experienced">Experienced (5+ years)</option>
                    <option value="executive">Executive (10+ years)</option>
                  </select>
                </div>
                
                <div className="form-group">
                  <label htmlFor="investment">Investment Range *</label>
                  <select
                    id="investment"
                    name="investment"
                    value={formData.investment}
                    onChange={handleChange}
                    required
                  >
                    <option value="">Select investment range</option>
                    <option value="50k-100k">$50,000 - $100,000</option>
                    <option value="100k-250k">$100,000 - $250,000</option>
                    <option value="250k+">$250,000+</option>
                  </select>
                </div>
              </div>
              
              <div className="form-group">
                <label htmlFor="message">Why are you interested in FlyHub franchise? *</label>
                <textarea
                  id="message"
                  name="message"
                  value={formData.message}
                  onChange={handleChange}
                  required
                  rows="4"
                  placeholder="Tell us about your interest, background, and goals..."
                ></textarea>
              </div>
              
              <div className="form-actions">
                <button type="submit" className="btn btn-primary btn-lg">
                  <FaRocket /> Submit Application
                </button>
                <button type="button" className="btn btn-outline btn-lg">
                  <FaHeadset /> Schedule Call
                </button>
              </div>
            </form>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="franchise-cta">
        <div className="container">
          <div className="cta-content">
            <FaBuilding className="cta-icon" />
            <h2>Ready to Build Your Drone Empire?</h2>
            <p>
              Join FlyHub franchise today and become a leader in the booming drone marketplace.
              Limited territories available.
            </p>
            <div className="cta-buttons">
              <button className="btn btn-primary btn-lg">
                <FaUsers /> Book Discovery Call
              </button>
              <button className="btn btn-secondary btn-lg">
                <FaAward /> Download Franchise Kit
              </button>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
};

export default Franchise;