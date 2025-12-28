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
              Join Flyhub as a franchise partner and lead the drone marketplace 
              in your region.
            </p>
          </div>
        </div>
      </section>

      {/* Why Franchise Section */}
      <section className="why-franchise">
        <div className="container">
          <div className="section-header">
            <h2>Why Choose Flyhub Franchise?</h2>
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
              
              <div className="form-group">
                <label htmlFor="message">Why are you interested in Flyhub franchise? *</label>
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
    </div>
  );
};

export default Franchise;