import React, { useState, useEffect } from 'react';
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
  FaAward,
  FaUser,
  FaEnvelope,
  FaPhone,
  FaMapMarkerAlt,
  FaArrowLeft,
  FaSpinner
} from 'react-icons/fa';
import { useNavigate } from 'react-router-dom';
import '../styles/Franchise.css';

const Franchise = () => {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    city: '',
    experience: '',
    investment: '',
    message: ''
  });

  const [errors, setErrors] = useState({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitSuccess, setSubmitSuccess] = useState(false);
  const [touched, setTouched] = useState({});

  // Focus first input on component mount
  useEffect(() => {
    const firstInput = document.querySelector('input[name="name"]');
    if (firstInput) {
      setTimeout(() => firstInput.focus(), 100);
    }
  }, []);

  const handleBlur = (e) => {
    const { name } = e.target;
    setTouched(prev => ({ ...prev, [name]: true }));
    
    // Validate only the blurred field
    if (formData[name].trim() && !errors[name]) {
      const fieldError = validateField(name, formData[name]);
      if (fieldError) {
        setErrors(prev => ({ ...prev, [name]: fieldError }));
      }
    }
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
    
    // Clear error when user starts typing
    if (errors[name]) {
      setErrors(prev => ({
        ...prev,
        [name]: ''
      }));
    }
  };

  const validateField = (name, value) => {
    switch (name) {
      case 'name':
        if (!value.trim()) return 'Full name is required';
        break;
      case 'email':
        if (!value.trim()) return 'Email is required';
        if (!/\S+@\S+\.\S+/.test(value)) return 'Email is invalid';
        break;
      case 'phone':
        if (!value.trim()) return 'Phone number is required';
        break;
      case 'city':
        if (!value.trim()) return 'City/Region is required';
        break;
      case 'message':
        if (!value.trim()) return 'Message is required';
        if (value.length < 50) return 'Please provide more details (minimum 50 characters)';
        break;
      default:
        return '';
    }
    return '';
  };

  const validateForm = () => {
    const newErrors = {};
    
    Object.keys(formData).forEach(key => {
      if (key !== 'experience' && key !== 'investment') {
        const error = validateField(key, formData[key]);
        if (error) newErrors[key] = error;
      }
    });

    return newErrors;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const validationErrors = validateForm();
    
    if (Object.keys(validationErrors).length > 0) {
      setErrors(validationErrors);
      // Mark all fields as touched to show errors
      const allTouched = {};
      Object.keys(formData).forEach(key => {
        if (key !== 'experience' && key !== 'investment') {
          allTouched[key] = true;
        }
      });
      setTouched(allTouched);
      return;
    }

    setIsSubmitting(true);

    try {
      // Using FormSubmit.co for email sending
      const response = await fetch('https://formsubmit.co/ajax/flyhubapp@gmail.com', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          _subject: `New Franchise Application - ${formData.name}`,
          _template: 'table',
          name: formData.name,
          email: formData.email,
          phone: formData.phone,
          city: formData.city,
          experience: formData.experience || 'Not specified',
          investment: formData.investment || 'Not specified',
          message: formData.message,
          application_date: new Date().toLocaleDateString('en-US', { 
            weekday: 'long', 
            year: 'numeric', 
            month: 'long', 
            day: 'numeric' 
          }),
          application_time: new Date().toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit'
          }),
          application_id: `FLY-FRAN-${Date.now().toString().slice(-8)}`,
          _captcha: 'false',
          _replyto: formData.email
        })
      });

      if (response.ok) {
        setSubmitSuccess(true);
        
        // Reset form
        setFormData({
          name: '',
          email: '',
          phone: '',
          city: '',
          experience: '',
          investment: '',
          message: ''
        });
        
        setTimeout(() => {
          navigate('/');
        }, 2000);
        
      } else {
        throw new Error('FormSubmit failed');
      }
      
    } catch (error) {
      console.error('Error sending email:', error);
      
      // Fallback: mailto link
      const mailtoBody = `
FRANCHISE APPLICATION DETAILS:

APPLICANT INFORMATION:
Name: ${formData.name}
Email: ${formData.email}
Phone: ${formData.phone}
City/Region: ${formData.city}
Business Experience: ${formData.experience || 'Not specified'}
Investment Range: ${formData.investment || 'Not specified'}

APPLICATION MESSAGE:
${formData.message}

Application Date: ${new Date().toLocaleString()}
Application ID: FLY-FRAN-${Date.now().toString().slice(-8)}
Status: Under Review
      `.trim();
      
      window.location.href = `mailto:flyhubapp@gmail.com?subject=Franchise Application - ${formData.name}&body=${encodeURIComponent(mailtoBody)}`;
      
      setSubmitSuccess(true);
      
      setTimeout(() => {
        navigate('/');
      }, 3000);
      
    } finally {
      setIsSubmitting(false);
    }
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

  if (submitSuccess) {
    return (
      <div className="franchise-page">
        <div className="container">
          <div className="success-container">
            <div className="success-header">
              <button className="back-button" onClick={() => navigate('/')}>
                <FaArrowLeft /> Home
              </button>
              <div className="success-title">
                <FaCheckCircle className="success-icon" />
                <h1>Franchise Application Submitted!</h1>
                <p className="success-subtitle">
                  Your application has been sent to our franchise team
                </p>
                <div className="success-details">
                  <p><strong>Application ID:</strong> FLY-FRAN-{Date.now().toString().slice(-8)}</p>
                  <p><strong>Name:</strong> {formData.name}</p>
                  <p><strong>Email:</strong> {formData.email}</p>
                  <p><strong>For Region:</strong> {formData.city}</p>
                  <p><strong>Status:</strong> <span style={{color: '#059669', fontWeight: '600'}}>Under Review</span></p>
                  <p style={{marginTop: '0.75rem', color: '#6b7280', fontSize: '0.8rem'}}>
                    You will be redirected to the homepage in 5 seconds...
                  </p>
                </div>
              </div>
            </div>
            <div className="success-actions">
              <button 
                className="btn btn-primary btn-lg" 
                onClick={() => navigate('/')}
              >
                <FaRocket /> Return to Homepage Now
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

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
            
            <form onSubmit={handleSubmit} className="franchise-form" noValidate>
              <div className="form-section">
                <h3><FaUser /> Personal Information</h3>
                
                <div className="form-row">
                  <div className="form-group">
                    <label htmlFor="name">Full Name *</label>
                    <div className="input-with-icon">
                      <FaUser className="input-icon" />
                      <input
                        type="text"
                        id="name"
                        name="name"
                        value={formData.name}
                        onChange={handleChange}
                        onBlur={handleBlur}
                        required
                        placeholder="Enter your full name"
                        className={errors.name && touched.name ? 'error' : ''}
                        disabled={isSubmitting}
                        aria-describedby={errors.name ? "name-error" : undefined}
                      />
                    </div>
                    {errors.name && touched.name && (
                      <span id="name-error" className="error-message">{errors.name}</span>
                    )}
                  </div>
                  
                  <div className="form-group">
                    <label htmlFor="email">Email Address *</label>
                    <div className="input-with-icon">
                      <FaEnvelope className="input-icon" />
                      <input
                        type="email"
                        id="email"
                        name="email"
                        value={formData.email}
                        onChange={handleChange}
                        onBlur={handleBlur}
                        required
                        placeholder="Enter your email"
                        className={errors.email && touched.email ? 'error' : ''}
                        disabled={isSubmitting}
                        aria-describedby={errors.email ? "email-error" : undefined}
                      />
                    </div>
                    {errors.email && touched.email && (
                      <span id="email-error" className="error-message">{errors.email}</span>
                    )}
                  </div>
                </div>
                
                <div className="form-row">
                  <div className="form-group">
                    <label htmlFor="phone">Phone Number *</label>
                    <div className="input-with-icon">
                      <FaPhone className="input-icon" />
                      <input
                        type="tel"
                        id="phone"
                        name="phone"
                        value={formData.phone}
                        onChange={handleChange}
                        onBlur={handleBlur}
                        required
                        placeholder="Enter your phone number"
                        className={errors.phone && touched.phone ? 'error' : ''}
                        disabled={isSubmitting}
                        aria-describedby={errors.phone ? "phone-error" : undefined}
                      />
                    </div>
                    {errors.phone && touched.phone && (
                      <span id="phone-error" className="error-message">{errors.phone}</span>
                    )}
                  </div>
                  
                  <div className="form-group">
                    <label htmlFor="city">City/Region *</label>
                    <div className="input-with-icon">
                      <FaMapMarkerAlt className="input-icon" />
                      <input
                        type="text"
                        id="city"
                        name="city"
                        value={formData.city}
                        onChange={handleChange}
                        onBlur={handleBlur}
                        required
                        placeholder="Enter your city"
                        className={errors.city && touched.city ? 'error' : ''}
                        disabled={isSubmitting}
                        aria-describedby={errors.city ? "city-error" : undefined}
                      />
                    </div>
                    {errors.city && touched.city && (
                      <span id="city-error" className="error-message">{errors.city}</span>
                    )}
                  </div>
                </div>
              </div>

              <div className="form-section">
                <h3><FaBusinessTime /> Business Information</h3>
                
                <div className="form-row">
                  <div className="form-group">
                    <label htmlFor="experience">Business Experience</label>
                    <select
                      id="experience"
                      name="experience"
                      value={formData.experience}
                      onChange={handleChange}
                      onBlur={handleBlur}
                      disabled={isSubmitting}
                      aria-describedby="experience-description"
                    >
                      <option value="">Select experience level</option>
                      <option value="Beginner">Beginner (No prior experience)</option>
                      <option value="Some Experience">Some Experience</option>
                      <option value="Experienced">Experienced Business Owner</option>
                      <option value="Industry Expert">Industry Expert</option>
                    </select>
                  </div>
                  
                  <div className="form-group">
                    <label htmlFor="investment">Investment Range ($)</label>
                    <select
                      id="investment"
                      name="investment"
                      value={formData.investment}
                      onChange={handleChange}
                      onBlur={handleBlur}
                      disabled={isSubmitting}
                      aria-describedby="investment-description"
                    >
                      <option value="">Select investment range</option>
                      <option value="50,000 - 100,000">$50,000 - $100,000</option>
                      <option value="100,000 - 250,000">$100,000 - $250,000</option>
                      <option value="250,000 - 500,000">$250,000 - $500,000</option>
                      <option value="500,000+">$500,000+</option>
                    </select>
                  </div>
                </div>
              </div>

              <div className="form-section">
                <h3><FaHeadset /> Application Details</h3>
                
                <div className="form-group">
                  <label htmlFor="message">Why are you interested in Flyhub franchise? *</label>
                  <textarea
                    id="message"
                    name="message"
                    value={formData.message}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    required
                    rows="4"
                    placeholder="Tell us about your interest, background, and goals... (minimum 50 characters)"
                    className={errors.message && touched.message ? 'error' : ''}
                    disabled={isSubmitting}
                    aria-describedby={errors.message ? "message-error" : undefined}
                  ></textarea>
                  {errors.message && touched.message && (
                    <span id="message-error" className="error-message">{errors.message}</span>
                  )}
                  <small className="char-count">
                    {formData.message.length} characters (minimum 50)
                  </small>
                </div>
              </div>
              
              <div className="form-footer">
                <div className="form-actions">
                  <button 
                    type="submit" 
                    className="btn btn-primary btn-lg"
                    disabled={isSubmitting}
                    aria-busy={isSubmitting}
                  >
                    {isSubmitting ? (
                      <>
                        <FaSpinner className="spinner" /> Processing Application...
                      </>
                    ) : (
                      <>
                        <FaRocket /> Submit Franchise Application
                      </>
                    )}
                  </button>
                </div>
                
                <div className="form-info">
                 
                  <p>
                    <FaCheckCircle /> Our team will contact you within 24-48 hours
                  </p>
                </div>
              </div>
            </form>
          </div>
        </div>
      </section>

      {/* Add inline styles */}
      <style jsx>{`
        .back-button-hero {
          background: transparent;
          border: 2px solid rgba(255, 255, 255, 0.3);
          color: white;
          padding: 10px 20px;
          border-radius: 6px;
          cursor: pointer;
          font-size: 16px;
          display: flex;
          align-items: center;
          gap: 8px;
          margin-bottom: 30px;
          transition: all 0.3s ease;
        }
        
        .back-button-hero:hover {
          background: rgba(255, 255, 255, 0.1);
          border-color: rgba(255, 255, 255, 0.5);
        }
        
        .email-notice {
          background: rgba(255, 255, 255, 0.1);
          padding: 12px 20px;
          border-radius: 8px;
          margin-top: 20px;
          display: inline-flex;
          align-items: center;
          gap: 10px;
          font-size: 16px;
          backdrop-filter: blur(10px);
        }
        
        .success-container {
          max-width: 800px;
          margin: 0 auto;
          background: white;
          border-radius: 20px;
          padding: 40px;
          box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
        }
        
        .success-header {
          text-align: center;
          margin-bottom: 40px;
        }
        
        .success-title {
          margin-top: 20px;
        }
        
        .success-icon {
          font-size: 60px;
          color: #10b981;
          margin-bottom: 20px;
        }
        
        .success-subtitle {
          color: #6b7280;
          font-size: 18px;
          margin-bottom: 30px;
        }
        
        .success-details {
          background: #f9fafb;
          border-radius: 10px;
          padding: 25px;
          text-align: left;
          margin: 30px auto;
          max-width: 600px;
        }
        
        .success-details p {
          margin: 10px 0;
          font-size: 16px;
        }
        
        .back-button {
          background: transparent;
          border: 2px solid #e5e7eb;
          color: #4b5563;
          padding: 10px 20px;
          border-radius: 6px;
          cursor: pointer;
          font-size: 16px;
          display: flex;
          align-items: center;
          gap: 8px;
          transition: all 0.3s ease;
        }
        
        .back-button:hover {
          background: #f9fafb;
          border-color: #d1d5db;
        }
        
        .form-section {
          background: white;
          border-radius: 10px;
          padding: 25px;
          margin-bottom: 25px;
          box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
        }
        
        .form-section h3 {
          display: flex;
          align-items: center;
          gap: 10px;
          color: #374151;
          margin-bottom: 20px;
          font-size: 18px;
        }
        
        .input-with-icon {
          position: relative;
        }
        
        .input-icon {
          position: absolute;
          left: 15px;
          top: 50%;
          transform: translateY(-50%);
          color: #9ca3af;
          font-size: 16px;
        }
        
        input, select, textarea {
          width: 100%;
          padding: 12px 15px 12px 45px;
          border: 2px solid #e5e7eb;
          border-radius: 8px;
          font-size: 16px;
          transition: all 0.3s ease;
          background: white;
        }
        
        input:focus, select:focus, textarea:focus {
          outline: none;
          border-color: #4a6ee0;
          box-shadow: 0 0 0 3px rgba(74, 110, 224, 0.1);
        }
        
        input.error, textarea.error {
          border-color: #ef4444;
        }
        
        .error-message {
          color: #ef4444;
          font-size: 14px;
          margin-top: 5px;
          display: block;
        }
        
        .char-count {
          display: block;
          text-align: right;
          margin-top: 5px;
          color: ${formData.message.length < 50 ? '#ef4444' : '#6b7280'};
          font-size: 14px;
        }
        
        .spinner {
          animation: spin 1s linear infinite;
          margin-right: 10px;
        }
        
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
        
        .form-info {
          text-align: center;
          margin-top: 20px;
          color: #6b7280;
          font-size: 14px;
          padding: 15px;
          background: #f8fafc;
          border-radius: 8px;
        }
        
        .form-info p {
          margin: 5px 0;
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 8px;
        }
        
        button:disabled {
          opacity: 0.6;
          cursor: not-allowed;
        }
        
        .form-actions {
          display: flex;
          justify-content: center;
          margin-top: 30px;
        }
        
        .btn {
          display: inline-flex;
          align-items: center;
          gap: 10px;
          padding: 12px 24px;
          border-radius: 8px;
          font-weight: 600;
          cursor: pointer;
          transition: all 0.3s ease;
          border: none;
          font-size: 16px;
        }
        
        .btn-primary {
          background: #4a6ee0;
          color: white;
        }
        
        .btn-primary:hover:not(:disabled) {
          background: #3a5ed0;
          transform: translateY(-2px);
          box-shadow: 0 4px 12px rgba(74, 110, 224, 0.3);
        }
        
        .btn-lg {
          padding: 15px 30px;
          font-size: 18px;
        }
      `}</style>
    </div>
  );
};

export default Franchise;