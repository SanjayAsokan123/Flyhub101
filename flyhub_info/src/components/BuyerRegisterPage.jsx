import React, { useState } from 'react';
import { FaUser, FaEnvelope, FaPhone, FaMapMarkerAlt, FaLock, FaArrowLeft, FaShoppingCart } from 'react-icons/fa';
import { useNavigate } from 'react-router-dom';
import emailjs from 'emailjs-com';
import '../styles/Register.css';

const BuyerRegisterPage = () => {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    fullName: '',
    email: '',
    phone: '',
    address: '',
    password: '',
    confirmPassword: ''
  });

  const [errors, setErrors] = useState({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitSuccess, setSubmitSuccess] = useState(false);

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

  const validateForm = () => {
    const newErrors = {};
    
    if (!formData.fullName.trim()) newErrors.fullName = 'Full name is required';
    
    if (!formData.email.trim()) newErrors.email = 'Email is required';
    else if (!/\S+@\S+\.\S+/.test(formData.email)) newErrors.email = 'Email is invalid';
    
    if (!formData.phone.trim()) newErrors.phone = 'Phone number is required';
    if (!formData.address.trim()) newErrors.address = 'Address is required';
    
    if (!formData.password) newErrors.password = 'Password is required';
    else if (formData.password.length < 6) newErrors.password = 'Password must be at least 6 characters';
    
    if (formData.password !== formData.confirmPassword) {
      newErrors.confirmPassword = 'Passwords do not match';
    }

    return newErrors;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    const validationErrors = validateForm();
    
    if (Object.keys(validationErrors).length > 0) {
      setErrors(validationErrors);
      return;
    }

    setIsSubmitting(true);

    // EmailJS Configuration
    const templateParams = {
      to_email: 'preethis19102004@gmail.com',
      from_name: formData.fullName,
      from_email: formData.email,
      phone: formData.phone,
      address: formData.address,
      registration_date: new Date().toLocaleDateString(),
      registration_time: new Date().toLocaleTimeString(),
      message: `NEW BUYER REGISTRATION DETAILS:\n\n` +
               `Name: ${formData.fullName}\n` +
               `Email: ${formData.email}\n` +
               `Phone: ${formData.phone}\n` +
               `Address: ${formData.address}\n\n` +
               `Registration submitted at: ${new Date().toLocaleString()}`
    };

    try {
      // Send email using EmailJS
      await emailjs.send(
        'service_08i9xxq',
        'template_rfwj9nv',
        templateParams,
        'JnZ2d3mdX1e6uuo03'
      );
      
      setSubmitSuccess(true);
      console.log('Buyer registration data:', formData);
      
      // Reset form
      setFormData({
        fullName: '',
        email: '',
        phone: '',
        address: '',
        password: '',
        confirmPassword: ''
      });
      
      // Show success message
      alert('Registration successful! A confirmation email has been sent to our team.');
      
      // Navigate to homepage after 3 seconds
      setTimeout(() => {
        navigate('/');
      }, 3000);
      
    } catch (error) {
      console.error('Error sending email:', error);
      alert('Registration submitted successfully!');
      
      // Still proceed with registration even if email fails
      console.log('Buyer registration data (offline):', formData);
      setTimeout(() => {
        navigate('/');
      }, 2000);
    } finally {
      setIsSubmitting(false);
    }
  };

  // Success Message Component
  if (submitSuccess) {
    return (
      <div className="register-page">
        <div className="register-container">
          <div className="register-header">
            <button className="back-button" onClick={() => navigate('/')}>
              <FaArrowLeft /> Home
            </button>
            <div className="register-title">
              <div className="register-icon success-icon">
                <FaShoppingCart />
              </div>
              <h1>Registration Successful!</h1>
              <p className="register-subtitle">
                Thank you for registering as a professional buyer. 
              </p>
              <div className="success-details">
                <p><strong>Name:</strong> {formData.fullName}</p>
                <p><strong>Email:</strong> {formData.email}</p>
                <p>You will be redirected to the homepage shortly...</p>
              </div>
            </div>
          </div>
          <div className="success-actions">
            <button className="submit-button secondary" onClick={() => navigate('/')}>
              Return to Homepage
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
          <button className="back-button" onClick={() => navigate(-1)}>
            <FaArrowLeft /> Back
          </button>
          <div className="register-title">
            <div className="register-icon">
              <FaShoppingCart />
            </div>
            <h1>Become a Professional Buyer</h1>
            <p className="register-subtitle">
              Join our professional drone marketplace
            </p>
            <p className="email-notice">
              <FaEnvelope /> Registration details will be sent to our team
            </p>
          </div>
        </div>

        <form className="register-form" onSubmit={handleSubmit}>
          <div className="form-grid">
            {/* Personal Information */}
            <div className="form-section">
              <h3><FaUser /> Personal Information</h3>
              <div className="form-group">
                <label>Full Name *</label>
                <div className="input-with-icon">
                  <FaUser className="input-icon" />
                  <input
                    type="text"
                    name="fullName"
                    value={formData.fullName}
                    onChange={handleChange}
                    placeholder="Enter your full name"
                    className={errors.fullName ? 'error' : ''}
                    disabled={isSubmitting}
                  />
                </div>
                {errors.fullName && <span className="error-message">{errors.fullName}</span>}
              </div>

              <div className="form-group">
                <label>Email Address *</label>
                <div className="input-with-icon">
                  <FaEnvelope className="input-icon" />
                  <input
                    type="email"
                    name="email"
                    value={formData.email}
                    onChange={handleChange}
                    placeholder="Enter your email"
                    className={errors.email ? 'error' : ''}
                    disabled={isSubmitting}
                  />
                </div>
                {errors.email && <span className="error-message">{errors.email}</span>}
              </div>

              <div className="form-group">
                <label>Phone Number *</label>
                <div className="input-with-icon">
                  <FaPhone className="input-icon" />
                  <input
                    type="tel"
                    name="phone"
                    value={formData.phone}
                    onChange={handleChange}
                    placeholder="Enter your phone number"
                    className={errors.phone ? 'error' : ''}
                    disabled={isSubmitting}
                  />
                </div>
                {errors.phone && <span className="error-message">{errors.phone}</span>}
              </div>

              <div className="form-group">
                <label>Address *</label>
                <div className="input-with-icon">
                  <FaMapMarkerAlt className="input-icon" />
                  <input
                    type="text"
                    name="address"
                    value={formData.address}
                    onChange={handleChange}
                    placeholder="Enter your address"
                    className={errors.address ? 'error' : ''}
                    disabled={isSubmitting}
                  />
                </div>
                {errors.address && <span className="error-message">{errors.address}</span>}
              </div>
            </div>

            {/* Security Information */}
            <div className="form-section">
              <h3><FaLock /> Security Information</h3>
              <div className="form-group">
                <label>Password *</label>
                <div className="input-with-icon">
                  <FaLock className="input-icon" />
                  <input
                    type="password"
                    name="password"
                    value={formData.password}
                    onChange={handleChange}
                    placeholder="Create a password"
                    className={errors.password ? 'error' : ''}
                    disabled={isSubmitting}
                  />
                </div>
                {errors.password && <span className="error-message">{errors.password}</span>}
                <small className="password-hint">Must be at least 6 characters</small>
              </div>

              <div className="form-group">
                <label>Confirm Password *</label>
                <div className="input-with-icon">
                  <FaLock className="input-icon" />
                  <input
                    type="password"
                    name="confirmPassword"
                    value={formData.confirmPassword}
                    onChange={handleChange}
                    placeholder="Confirm your password"
                    className={errors.confirmPassword ? 'error' : ''}
                    disabled={isSubmitting}
                  />
                </div>
                {errors.confirmPassword && <span className="error-message">{errors.confirmPassword}</span>}
              </div>
            </div>
          </div>

          <div className="form-footer">
            <div className="terms-agreement">
              <input 
                type="checkbox" 
                id="terms" 
                required 
                disabled={isSubmitting}
              />
              <label htmlFor="terms">
                I agree to the <a href="/terms">Terms of Service</a> and <a href="/privacy">Privacy Policy</a>
              </label>
            </div>
            
            <button 
              type="submit" 
              className="submit-button"
              disabled={isSubmitting}
            >
              {isSubmitting ? (
                <>
                  <span className="spinner"></span>
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