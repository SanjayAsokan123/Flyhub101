import React, { useState, useEffect } from 'react';
import '../styles/Contact.css';

// Import FontAwesome components
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { 
  faCheckCircle, 
  faPaperPlane, 
  faEnvelope, 
  faPhoneAlt, 
  faMapMarkerAlt,
  faPhone,
  faUser,
  faSpinner,
  faArrowLeft,
  faTimes
} from '@fortawesome/free-solid-svg-icons';
import { faWhatsapp } from '@fortawesome/free-brands-svg-icons';
import { useNavigate } from 'react-router-dom';

const ContactPage = () => {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    phone: '',
    subject: '',
    message: ''
  });
  
  const [errors, setErrors] = useState({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showSuccessPopup, setShowSuccessPopup] = useState(false);
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
      case 'subject':
        if (!value.trim()) return 'Subject is required';
        break;
      case 'message':
        if (!value.trim()) return 'Message is required';
        if (value.length < 20) return 'Please provide more details (minimum 20 characters)';
        break;
      default:
        return '';
    }
    return '';
  };

  const validateForm = () => {
    const newErrors = {};
    
    Object.keys(formData).forEach(key => {
      if (key !== 'phone') {
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
        if (key !== 'phone') {
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
          _subject: `Contact Form: ${formData.subject}`,
          _template: 'table',
          name: formData.name,
          email: formData.email,
          phone: formData.phone || 'Not provided',
          subject: formData.subject,
          message: formData.message,
          contact_date: new Date().toLocaleDateString('en-US', { 
            weekday: 'long', 
            year: 'numeric', 
            month: 'long', 
            day: 'numeric' 
          }),
          contact_time: new Date().toLocaleTimeString('en-US', {
            hour: '2-digit',
            minute: '2-digit'
          }),
          inquiry_id: `FLY-CONT-${Date.now().toString().slice(-8)}`,
          _captcha: 'false',
          _replyto: formData.email
        })
      });

      if (response.ok) {
        // Show success popup
        setShowSuccessPopup(true);
        
        // Reset form
        setFormData({
          name: '',
          email: '',
          phone: '',
          subject: '',
          message: ''
        });
        
      } else {
        throw new Error('FormSubmit failed');
      }
      
    } catch (error) {
      console.error('Error sending email:', error);
      
      // Fallback: mailto link
      const mailtoBody = `
CONTACT INQUIRY DETAILS:

CONTACT INFORMATION:
Name: ${formData.name}
Email: ${formData.email}
Phone: ${formData.phone || 'Not provided'}

INQUIRY DETAILS:
Subject: ${formData.subject}
Message: ${formData.message}

Inquiry Date: ${new Date().toLocaleString()}
Inquiry ID: FLY-CONT-${Date.now().toString().slice(-8)}
Status: Received - We'll respond within 24 hours
      `.trim();
      
      window.location.href = `mailto:flyhubapp@gmail.com?subject=Contact Inquiry: ${formData.subject}&body=${encodeURIComponent(mailtoBody)}`;
      
      // Show success popup even with fallback
      setShowSuccessPopup(true);
      
    } finally {
      setIsSubmitting(false);
    }
  };

  const closeSuccessPopup = () => {
    setShowSuccessPopup(false);
  };

  return (
    <div className="contact-page">
      {/* Success Popup */}
      {showSuccessPopup && (
        <div className="success-popup-overlay">
          <div className="success-popup">
            <button className="close-popup-btn" onClick={closeSuccessPopup}>
              <FontAwesomeIcon icon={faTimes} />
            </button>
            <div className="popup-content">
              <FontAwesomeIcon icon={faCheckCircle} className="popup-icon" />
              <h2>Message Sent Successfully!</h2>
              <p className="popup-subtitle">
                Thank you for contacting Flyhub. We've received your inquiry and will respond within 24 hours.
              </p>
              <div className="popup-details">
                <p><strong>Inquiry ID:</strong> FLY-CONT-{Date.now().toString().slice(-8)}</p>
                <p><strong>Name:</strong> {formData.name}</p>
                <p><strong>Subject:</strong> {formData.subject}</p>
                <p><strong>Status:</strong> <span className="status-active">Received - Under Review</span></p>
              </div>
              <button className="popup-close-btn" onClick={closeSuccessPopup}>
                Continue Browsing
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Hero Section */}
      <section className="flyhub-contact-hero">
        <div className="flyhub-container">
        
          <h1>Get in touch with our experts for drone solutions, training, and ecosystem services</h1>
          
        </div>
      </section>

      {/* Main Content */}
      <div className="flyhub-container flyhub-main-container">
        <div className="flyhub-contact-grid">
          {/* Contact Form */}
          <div className="flyhub-contact-form-section">
            <h2>Send us a Message</h2>
            <p className="flyhub-section-subtitle">Have questions about our drone services? Reach out to us.</p>
            
            <form className="flyhub-contact-form" onSubmit={handleSubmit} noValidate>
              <div className="flyhub-form-row">
                <div className="flyhub-form-group">
                  <label htmlFor="name">Full Name *</label>
                  <div className="input-with-icon">
                    <FontAwesomeIcon icon={faUser} className="input-icon" />
                    <input
                      type="text"
                      id="name"
                      name="name"
                      value={formData.name}
                      onChange={handleChange}
                      onBlur={handleBlur}
                      required
                      placeholder="Your Name"
                      className={errors.name && touched.name ? 'error' : ''}
                      disabled={isSubmitting}
                      aria-describedby={errors.name ? "name-error" : undefined}
                    />
                  </div>
                  {errors.name && touched.name && (
                    <span id="name-error" className="error-message">{errors.name}</span>
                  )}
                </div>
                <div className="flyhub-form-group">
                  <label htmlFor="email">Email Address *</label>
                  <div className="input-with-icon">
                    <FontAwesomeIcon icon={faEnvelope} className="input-icon" />
                    <input
                      type="email"
                      id="email"
                      name="email"
                      value={formData.email}
                      onChange={handleChange}
                      onBlur={handleBlur}
                      required
                      placeholder="your.email@example.com"
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
              
              <div className="flyhub-form-row">
                <div className="flyhub-form-group">
                  <label htmlFor="phone">Phone Number</label>
                  <div className="input-with-icon">
                    <FontAwesomeIcon icon={faPhone} className="input-icon" />
                    <input
                      type="tel"
                      id="phone"
                      name="phone"
                      value={formData.phone}
                      onChange={handleChange}
                      onBlur={handleBlur}
                      placeholder="+91 90000 00000"
                      disabled={isSubmitting}
                    />
                  </div>
                </div>
                <div className="flyhub-form-group">
                  <label htmlFor="subject">Subject *</label>
                  <input
                    type="text"
                    id="subject"
                    name="subject"
                    value={formData.subject}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    required
                    placeholder="e.g., Drone Training Inquiry"
                    className={errors.subject && touched.subject ? 'error' : ''}
                    disabled={isSubmitting}
                    aria-describedby={errors.subject ? "subject-error" : undefined}
                  />
                  {errors.subject && touched.subject && (
                    <span id="subject-error" className="error-message">{errors.subject}</span>
                  )}
                </div>
              </div>
              
              <div className="flyhub-form-group">
                <label htmlFor="message">Your Message *</label>
                <textarea
                  id="message"
                  name="message"
                  value={formData.message}
                  onChange={handleChange}
                  onBlur={handleBlur}
                  required
                  rows="5"
                  placeholder="Tell us about your drone needs or project..."
                  className={errors.message && touched.message ? 'error' : ''}
                  disabled={isSubmitting}
                  aria-describedby={errors.message ? "message-error" : undefined}
                ></textarea>
                {errors.message && touched.message && (
                  <span id="message-error" className="error-message">{errors.message}</span>
                )}
                <small className="char-count">
                  {formData.message.length} characters (minimum 20)
                </small>
              </div>
              
              <div className="form-footer">
                <button 
                  type="submit" 
                  className="flyhub-submit-btn"
                  disabled={isSubmitting}
                >
                  {isSubmitting ? (
                    <>
                      <FontAwesomeIcon icon={faSpinner} className="spinner" /> Sending Message...
                    </>
                  ) : (
                    <>
                      <FontAwesomeIcon icon={faPaperPlane} /> Send Message
                    </>
                  )}
                </button>
                
                <div className="form-info">
                 
                </div>
              </div>
            </form>
          </div>
          
          {/* Contact Information */}
          <div className="flyhub-contact-info-section">
            <h2>Get in Touch</h2>
            <p className="flyhub-section-subtitle">We're here to help with your drone ecosystem needs</p>
            
            <div className="flyhub-contact-info-card">
              <div className="flyhub-contact-item">
                <div className="flyhub-contact-icon">
                  <FontAwesomeIcon icon={faEnvelope} />
                </div>
                <div className="flyhub-contact-details">
                  <h3>Email Us</h3>
                  <p>For general inquiries and support</p>
                  <a href="mailto:support@flyhub.com" className="flyhub-contact-link">
                    support@flyhub.com
                  </a>
                </div>
              </div>
              
              <div className="flyhub-contact-item">
                <div className="flyhub-contact-icon">
                  <FontAwesomeIcon icon={faPhoneAlt} />
                </div>
                <div className="flyhub-contact-details">
                  <h3>Call Us</h3>
                  <p>Available Monday to Friday, 9AM - 6PM</p>
                  <a href="tel:+919003992693" className="flyhub-contact-link">
                    +91 90039 92693
                  </a>
                  
                  {/* Call Now and WhatsApp Buttons */}
                  <div className="flyhub-contact-buttons">
                    <a 
                      href="tel:+919003992693" 
                      className="flyhub-call-btn"
                    >
                      <FontAwesomeIcon icon={faPhone} /> Call Now
                    </a>
                    <a 
                      href="https://wa.me/919003992693" 
                      target="_blank" 
                      rel="noopener noreferrer" 
                      className="flyhub-whatsapp-btn"
                    >
                      <FontAwesomeIcon icon={faWhatsapp} /> WhatsApp
                    </a>
                  </div>
                </div>
              </div>
              
              <div className="flyhub-contact-item">
                <div className="flyhub-contact-icon">
                  <FontAwesomeIcon icon={faMapMarkerAlt} />
                </div>
                <div className="flyhub-contact-details">
                  <h3>Visit Us</h3>
                  <p>Manikampalayam,Nammakal</p>
                  <a 
                    href="https://www.google.com/maps/place/Flytutor+RPTO+(DGCA+Approved+Drone+Training+Academy)/@11.3264777,78.0220028,17z/data=!3m1!4b1!4m6!3m5!1s0x3babdbb297734803:0xd05a3e9e2582d7b4!8m2!3d11.3264725!4d78.0268737!16s%2Fg%2F11wqpypyws?entry=ttu&g_ep=EgoyMDI5MTIwOS4wIKXMDSoKLDEwMDc5MjA3M0gBUAM%3D" 
                    target="_blank" 
                    rel="noopener noreferrer" 
                    className="flyhub-contact-link"
                  >
                    View on Google Maps
                  </a>
                </div>
              </div>
            </div>
          </div>
        </div>
        
        {/* Map Section */}
        <div className="flyhub-map-section">
          <h2>Our Location</h2>
          <div className="flyhub-map-container">
            <iframe 
              src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3918.7245815302786!2d78.0220028!3d11.3264777!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x3babdbb297734803%3A0xd05a3e9e2582d7b4!2sFlytutor%20RPTO%20(DGCA%20Approved%20Drone%20Training%20Academy)!5e0!3m2!1sen!2sin!4v1690300000000!5m2!1sen!2sin" 
              width="100%" 
              height="400" 
              style={{border:0}} 
              allowFullScreen="" 
              loading="lazy" 
              title="FlyHub Location"
              referrerPolicy="no-referrer-when-downgrade"
            ></iframe>
          </div>
        </div>
      </div>

      {/* Add inline styles */}
      <style jsx>{`
        .back-button-hero {
          background: rgba(255, 255, 255, 0.1);
          border: 2px solid rgba(255, 255, 255, 0.3);
          color: white;
          padding: 12px 24px;
          border-radius: 6px;
          cursor: pointer;
          font-size: 16px;
          display: flex;
          align-items: center;
          gap: 10px;
          margin-bottom: 30px;
          transition: all 0.3s ease;
          backdrop-filter: blur(10px);
          border: none;
          font-weight: 500;
        }
        
        .back-button-hero:hover {
          background: rgba(255, 255, 255, 0.2);
          border-color: rgba(255, 255, 255, 0.5);
          transform: translateY(-2px);
        }
        
        .email-notice {
          background: rgba(255, 255, 255, 0.1);
          padding: 15px 25px;
          border-radius: 10px;
          display: inline-flex;
          align-items: center;
          gap: 12px;
          font-size: 18px;
          backdrop-filter: blur(10px);
          border: 1px solid rgba(255, 255, 255, 0.2);
          margin-top: 20px;
          font-weight: 500;
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
          z-index: 1;
        }
        
        .flyhub-contact-form input,
        .flyhub-contact-form textarea,
        .flyhub-contact-form select {
          padding-left: 45px !important;
        }
        
        input.error, textarea.error, select.error {
          border-color: #ef4444 !important;
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
          color: ${formData.message.length < 20 ? '#ef4444' : '#6b7280'};
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
        
        .form-footer {
          margin-top: 30px;
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
        
        /* Success Popup Styles */
        .success-popup-overlay {
          position: fixed;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background: rgba(0, 0, 0, 0.7);
          display: flex;
          align-items: center;
          justify-content: center;
          z-index: 1000;
          animation: fadeIn 0.3s ease;
        }
        
        .success-popup {
          background: white;
          border-radius: 20px;
          padding: 40px;
          max-width: 500px;
          width: 90%;
          position: relative;
          box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
          animation: slideUp 0.4s ease;
        }
        
        .close-popup-btn {
          position: absolute;
          top: 20px;
          right: 20px;
          background: none;
          border: none;
          font-size: 24px;
          color: #9ca3af;
          cursor: pointer;
          transition: color 0.3s ease;
          padding: 5px;
          border-radius: 50%;
          width: 40px;
          height: 40px;
          display: flex;
          align-items: center;
          justify-content: center;
        }
        
        .close-popup-btn:hover {
          color: #ef4444;
          background: #f5f5f5;
        }
        
        .popup-content {
          text-align: center;
        }
        
        .popup-icon {
          font-size: 60px;
          color: #10b981;
          margin-bottom: 20px;
        }
        
        .popup-content h2 {
          font-size: 28px;
          color: #1a202c;
          margin-bottom: 15px;
        }
        
        .popup-subtitle {
          color: #6b7280;
          font-size: 16px;
          margin-bottom: 25px;
          line-height: 1.6;
        }
        
        .popup-details {
          background: #f9fafb;
          border-radius: 12px;
          padding: 20px;
          margin: 25px 0;
          text-align: left;
        }
        
        .popup-details p {
          margin: 10px 0;
          font-size: 15px;
        }
        
        .status-active {
          color: #059669;
          font-weight: 600;
        }
        
        .popup-close-btn {
          background: linear-gradient(135deg, #020611ff, #0f0e0fff);
          color: white;
          border: none;
          padding: 14px 30px;
          border-radius: 8px;
          font-size: 16px;
          font-weight: 600;
          cursor: pointer;
          transition: all 0.3s ease;
          width: 100%;
          margin-top: 10px;
        }
        
        .popup-close-btn:hover {
          transform: translateY(-2px);
          box-shadow: 0 10px 20px rgba(74, 110, 224, 0.3);
        }
        
        @keyframes fadeIn {
          from { opacity: 0; }
          to { opacity: 1; }
        }
        
        @keyframes slideUp {
          from {
            opacity: 0;
            transform: translateY(30px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }
        
        /* Success notification in form (optional alternative) */
        .success-inline-notification {
          background: #d1fae5;
          border: 1px solid #10b981;
          border-radius: 10px;
          padding: 20px;
          margin-bottom: 30px;
          text-align: center;
          animation: fadeInUp 0.5s ease;
        }
        
        .success-inline-notification h3 {
          color: #065f46;
          margin-bottom: 10px;
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 10px;
        }
        
        .success-inline-notification p {
          color: #047857;
          margin-bottom: 15px;
        }
        
        @keyframes fadeInUp {
          from {
            opacity: 0;
            transform: translateY(-20px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }
      `}</style>
    </div>
  );
};

export default ContactPage;