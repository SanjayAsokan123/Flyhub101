import React, { useState, useEffect } from 'react';
import { FaUser, FaEnvelope, FaPhone, FaMapMarkerAlt, FaLock, FaArrowLeft, FaCheckCircle, FaSpinner } from 'react-icons/fa';
import { useNavigate } from 'react-router-dom';
import '../styles/Register.css';

const BuyerRegisterPage = () => {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    fullName: '',
    email: '',
    phone: '',
    address: '',
    // password: '',
    // confirmPassword: ''
  });

  const [errors, setErrors] = useState({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitSuccess, setSubmitSuccess] = useState(false);
  const [touched, setTouched] = useState({});

  // Focus first input on component mount
  useEffect(() => {
    const firstInput = document.querySelector('input[name="fullName"]');
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
      case 'fullName':
        if (!value.trim()) return 'Full name is required';
        break;
      case 'email':
        if (!value.trim()) return 'Email is required';
        if (!/\S+@\S+\.\S+/.test(value)) return 'Email is invalid';
        break;
      case 'phone':
        if (!value.trim()) return 'Phone number is required';
        break;
      case 'address':
        if (!value.trim()) return 'Address is required';
        break;
      // case 'password':
      //   if (!value) return 'Password is required';
      //   if (value.length < 6) return 'Password must be at least 6 characters';
      //   break;
      // case 'confirmPassword':
      //   if (value !== formData.password) return 'Passwords do not match';
      //   break;
      default:
        return '';
    }
    return '';
  };

  const validateForm = () => {
    const newErrors = {};
    
    Object.keys(formData).forEach(key => {
      const error = validateField(key, formData[key]);
      if (error) newErrors[key] = error;
    });

    return newErrors;
  };

  const sendEmailUsingSMTP = async (emailData) => {
    // Using FormSubmit.co as a proxy for Gmail SMTP
    const response = await fetch('https://formsubmit.co/ajax/flyhubapp@gmail.com', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify({
        _subject: `New Buyer Registration - ${emailData.from_name}`,
        _template: 'table',
        name: emailData.from_name,
        email: emailData.from_email,
        phone: emailData.phone,
        address: emailData.address,
        registration_date: emailData.registration_date,
        registration_time: emailData.registration_time,
        message: emailData.message,
        _captcha: 'false',
        _replyto: emailData.from_email
      })
    });
    
    return response.ok;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const validationErrors = validateForm();
    
    if (Object.keys(validationErrors).length > 0) {
      setErrors(validationErrors);
      // Mark all fields as touched to show errors
      const allTouched = {};
      Object.keys(formData).forEach(key => {
        allTouched[key] = true;
      });
      setTouched(allTouched);
      return;
    }

    setIsSubmitting(true);

    const emailData = {
      to_email: 'flyhubapp@gmail.com',
      from_name: formData.fullName,
      from_email: formData.email,
      phone: formData.phone,
      address: formData.address,
      registration_date: new Date().toLocaleDateString('en-US', { 
        weekday: 'long', 
        year: 'numeric', 
        month: 'long', 
        day: 'numeric' 
      }),
      registration_time: new Date().toLocaleTimeString('en-US', {
        hour: '2-digit',
        minute: '2-digit'
      }),
      message: `NEW BUYER REGISTRATION DETAILS:\n\n` +
               `Name: ${formData.fullName}\n` +
               `Email: ${formData.email}\n` +
               `Phone: ${formData.phone}\n` +
               `Address: ${formData.address}\n\n` +
               `Registration submitted at: ${new Date().toLocaleString()}`
    };

    try {
      // Using FormSubmit.co as SMTP proxy
      const success = await sendEmailUsingSMTP(emailData);
      
      if (success) {
        setSubmitSuccess(true);
        setTimeout(() => navigate('/'), 2000);
      } else {
        throw new Error('FormSubmit failed');
      }
      
    } catch (error) {
      console.error('Error sending email:', error);
      
      // Fallback 1: Try using mailgun with environment variables
      try {
        const mailgunResponse = await fetch('https://api.mailgun.net/v3/YOUR_DOMAIN/messages', {
          method: 'POST',
          headers: {
            'Authorization': 'Basic ' + btoa('api:' + process.env.REACT_APP_MAILGUN_API_KEY),
            'Content-Type': 'application/x-www-form-urlencoded'
          },
          body: new URLSearchParams({
            from: `Flyhub Registration <${process.env.REACT_APP_EMAIL_USER}>`,
            to: 'flyhubapp@gmail.com',
            subject: `New Buyer Registration - ${formData.fullName}`,
            text: `Name: ${formData.fullName}\nEmail: ${formData.email}\nPhone: ${formData.phone}\nAddress: ${formData.address}`
          })
        });
        
        if (mailgunResponse.ok) {
          setSubmitSuccess(true);
          setTimeout(() => navigate('/'), 5000);
        } else {
          throw new Error('Mailgun failed');
        }
      } catch (mailgunError) {
        console.error('Mailgun error:', mailgunError);
        
        // Final fallback: mailto link
        const mailtoBody = `
BUYER REGISTRATION DETAILS:

Name: ${formData.fullName}
Email: ${formData.email}
Phone: ${formData.phone}
Address: ${formData.address}

Registration Date: ${new Date().toLocaleString()}
        `.trim();
        
        window.location.href = `mailto:flyhubapp@gmail.com.com?subject=New Buyer Registration - ${formData.fullName}&body=${encodeURIComponent(mailtoBody)}`;
        
        setSubmitSuccess(true);
        setTimeout(() => navigate('/'), 3000);
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  if (submitSuccess) {
    return (
      <div className="register-page">
        <div className="register-container">
          <div className="register-header">
            <button className="back-button" onClick={() => navigate('/')}>
              <FaArrowLeft /> Home
            </button>
            <div className="register-title">
              <h1>Registration Successful!</h1>
              <p className="register-subtitle">
                Welcome to our professional drone marketplace
              </p>
              <div className="success-details">
                <p><strong>Name:</strong> {formData.fullName}</p>
                <p><strong>Email:</strong> {formData.email}</p>
                <p><strong>Phone:</strong> {formData.phone}</p>
                <p><strong>Status:</strong> <span style={{color: '#059669', fontWeight: '600'}}>Pending Verification</span></p>
                <p style={{marginTop: '0.75rem', color: '#6b7280', fontSize: '0.8rem'}}>
                  You will be redirected to the homepage in 5 seconds...
                </p>
              </div>
            </div>
          </div>
          <div className="success-actions">
            <button 
              className="submit-button" 
              onClick={() => navigate('/')}
            >
              Return to Homepage Now
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="register-page">
      <div className="register-container">
        <div className="register-header">
          <button 
            className="back-button" 
            onClick={() => navigate(-1)}
            aria-label="Go back"
          >
            <FaArrowLeft /> Back
          </button>
          <div className="register-title">
            <h1>Become a Professional Buyer</h1>
            <p className="register-subtitle">
              Join our exclusive network of drone professionals
            </p>
            <p className="email-notice">
              <FaEnvelope /> Registration details will be sent to our verification team
            </p>
          </div>
        </div>

        <form className="register-form" onSubmit={handleSubmit} noValidate>
          <div className="form-section">
            <h3><FaUser /> Personal Information</h3>
            
            <div className="form-group">
              <label htmlFor="fullName">Full Name *</label>
              <div className="input-with-icon">
                <FaUser className="input-icon" />
                <input
                  id="fullName"
                  type="text"
                  name="fullName"
                  value={formData.fullName}
                  onChange={handleChange}
                  onBlur={handleBlur}
                  placeholder="Enter your full name"
                  className={errors.fullName && touched.fullName ? 'error' : ''}
                  disabled={isSubmitting}
                  aria-describedby={errors.fullName ? "fullName-error" : undefined}
                />
              </div>
              {errors.fullName && touched.fullName && (
                <span id="fullName-error" className="error-message">{errors.fullName}</span>
              )}
            </div>

            <div className="form-group">
              <label htmlFor="email">Email Address *</label>
              <div className="input-with-icon">
                <FaEnvelope className="input-icon" />
                <input
                  id="email"
                  type="email"
                  name="email"
                  value={formData.email}
                  onChange={handleChange}
                  onBlur={handleBlur}
                  placeholder="Enter your business email"
                  className={errors.email && touched.email ? 'error' : ''}
                  disabled={isSubmitting}
                  aria-describedby={errors.email ? "email-error" : undefined}
                />
              </div>
              {errors.email && touched.email && (
                <span id="email-error" className="error-message">{errors.email}</span>
              )}
            </div>

            <div className="form-group">
              <label htmlFor="phone">Phone Number *</label>
              <div className="input-with-icon">
                <FaPhone className="input-icon" />
                <input
                  id="phone"
                  type="tel"
                  name="phone"
                  value={formData.phone}
                  onChange={handleChange}
                  onBlur={handleBlur}
                  placeholder="Enter your contact number"
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
              <label htmlFor="address">Address *</label>
              <div className="input-with-icon">
                <FaMapMarkerAlt className="input-icon" />
                <input
                  id="address"
                  type="text"
                  name="address"
                  value={formData.address}
                  onChange={handleChange}
                  onBlur={handleBlur}
                  placeholder="Enter your complete address"
                  className={errors.address && touched.address ? 'error' : ''}
                  disabled={isSubmitting}
                  aria-describedby={errors.address ? "address-error" : undefined}
                />
              </div>
              {errors.address && touched.address && (
                <span id="address-error" className="error-message">{errors.address}</span>
              )}
            </div>
          </div>

          {/* <div className="form-section">
            <h3><FaLock /> Security Information</h3>
            
            <div className="form-group">
              <label htmlFor="password">Password *</label>
              <div className="input-with-icon">
                <FaLock className="input-icon" />
                <input
                  id="password"
                  type="password"
                  name="password"
                  value={formData.password}
                  onChange={handleChange}
                  onBlur={handleBlur}
                  placeholder="Create a secure password"
                  className={errors.password && touched.password ? 'error' : ''}
                  disabled={isSubmitting}
                  aria-describedby={errors.password ? "password-error" : undefined}
                />
              </div>
              {errors.password && touched.password && (
                <span id="password-error" className="error-message">{errors.password}</span>
              )}
              <small className="password-hint">Must be at least 6 characters long</small>
            </div>

            <div className="form-group">
              <label htmlFor="confirmPassword">Confirm Password *</label>
              <div className="input-with-icon">
                <FaLock className="input-icon" />
                <input
                  id="confirmPassword"
                  type="password"
                  name="confirmPassword"
                  value={formData.confirmPassword}
                  onChange={handleChange}
                  onBlur={handleBlur}
                  placeholder="Re-enter your password"
                  className={errors.confirmPassword && touched.confirmPassword ? 'error' : ''}
                  disabled={isSubmitting}
                  aria-describedby={errors.confirmPassword ? "confirmPassword-error" : undefined}
                />
              </div>
              {errors.confirmPassword && touched.confirmPassword && (
                <span id="confirmPassword-error" className="error-message">{errors.confirmPassword}</span>
              )}
            </div>
          </div> */}

          <div className="form-footer">
            <div className="terms-agreement">
              <input 
                type="checkbox" 
                id="terms" 
                required 
                disabled={isSubmitting}
                aria-describedby="terms-description"
              />
              <label htmlFor="terms">
                I agree to the <a href="/terms" target="_blank" rel="noopener noreferrer">Terms of Service</a> and{' '}
                <a href="/privacy" target="_blank" rel="noopener noreferrer">Privacy Policy</a>
                <span id="terms-description" style={{display: 'none'}}>
                  Required to create your account
                </span>
              </label>
            </div>
            
            <button 
              type="submit" 
              className="submit-button"
              disabled={isSubmitting}
              aria-busy={isSubmitting}
            >
              {isSubmitting ? (
                <>
                  <FaSpinner className="spinner" aria-hidden="true" />
                  Processing Registration...
                </>
              ) : (
                'Create Buyer Account'
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

export default BuyerRegisterPage;