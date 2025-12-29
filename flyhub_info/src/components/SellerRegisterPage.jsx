import React, { useState, useEffect } from 'react';
import { FaUser, FaEnvelope, FaPhone, FaBuilding, FaMapMarkerAlt, FaLock, FaArrowLeft, FaStore, FaTag, FaCertificate, FaSpinner, FaCheckCircle } from 'react-icons/fa';
import { useNavigate } from 'react-router-dom';
import '../styles/SellerRegister.css';

const SellerRegisterPage = () => {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    fullName: '',
    email: '',
    phone: '',
    company: '',
    location: '',
    // password: '',
    // confirmPassword: '',
    businessType: '',
    productCategory: '',
    website: '',
    taxId: '',
    yearsInBusiness: ''
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
      case 'company':
        if (!value.trim()) return 'Company name is required';
        break;
      case 'location':
        if (!value.trim()) return 'Location is required';
        break;
      case 'password':
        if (!value) return 'Password is required';
        if (value.length < 8) return 'Password must be at least 8 characters';
        break;
      case 'confirmPassword':
        if (value !== formData.password) return 'Passwords do not match';
        break;
      case 'businessType':
        if (!value) return 'Business type is required';
        break;
      case 'productCategory':
        if (!value) return 'Product category is required';
        break;
      default:
        return '';
    }
    return '';
  };

  const validateForm = () => {
    const newErrors = {};
    
    Object.keys(formData).forEach(key => {
      if (key !== 'website' && key !== 'taxId' && key !== 'yearsInBusiness') {
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
      company: formData.company,
      location: formData.location,
      business_type: formData.businessType,
      product_category: formData.productCategory,
      website: formData.website || 'Not provided',
      tax_id: formData.taxId || 'Not provided',
      years_in_business: formData.yearsInBusiness || 'Not specified',
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
      message: `NEW SELLER REGISTRATION DETAILS:\n\n` +
               `SELLER INFORMATION:\n` +
               `Name: ${formData.fullName}\n` +
               `Email: ${formData.email}\n` +
               `Phone: ${formData.phone}\n\n` +
               `BUSINESS INFORMATION:\n` +
               `Company: ${formData.company}\n` +
               `Location: ${formData.location}\n` +
               `Business Type: ${formData.businessType}\n` +
               `Product Category: ${formData.productCategory}\n` +
               `Website: ${formData.website || 'Not provided'}\n` +
               `Tax ID: ${formData.taxId || 'Not provided'}\n` +
               `Years in Business: ${formData.yearsInBusiness || 'Not specified'}\n\n` +
               `Registration submitted at: ${new Date().toLocaleString()}\n` +
               `Account Status: Pending Verification`
    };

    try {
      // Using FormSubmit.co for email sending
      const response = await fetch('https://formsubmit.co/ajax/flyhubapp@gmail.com', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({
          _subject: `New Seller Registration - ${formData.fullName}`,
          _template: 'table',
          name: formData.fullName,
          email: formData.email,
          phone: formData.phone,
          company: formData.company,
          location: formData.location,
          business_type: formData.businessType,
          product_category: formData.productCategory,
          website: formData.website || 'Not provided',
          tax_id: formData.taxId || 'Not provided',
          years_in_business: formData.yearsInBusiness || 'Not specified',
          registration_date: new Date().toLocaleString(),
          _captcha: 'false',
          _replyto: formData.email
        })
      });

      if (response.ok) {
        setSubmitSuccess(true);
        
        // Reset form
        setFormData({
          fullName: '',
          email: '',
          phone: '',
          company: '',
          location: '',
          // password: '',
          // confirmPassword: '',
          businessType: '',
          productCategory: '',
          website: '',
          taxId: '',
          yearsInBusiness: ''
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
SELLER REGISTRATION DETAILS:

SELLER INFORMATION:
Name: ${formData.fullName}
Email: ${formData.email}
Phone: ${formData.phone}

BUSINESS INFORMATION:
Company: ${formData.company}
Location: ${formData.location}
Business Type: ${formData.businessType}
Product Category: ${formData.productCategory}
Website: ${formData.website || 'Not provided'}
Tax ID: ${formData.taxId || 'Not provided'}
Years in Business: ${formData.yearsInBusiness || 'Not specified'}

Registration Date: ${new Date().toLocaleString()}
Status: Pending Verification
      `.trim();
      
      window.location.href = `mailto:flyhubapp@gmail.com?subject=New Seller Registration - ${formData.fullName}&body=${encodeURIComponent(mailtoBody)}`;
      
      setSubmitSuccess(true);
      
      setTimeout(() => {
        navigate('/');
      }, 3000);
      
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
                <FaCheckCircle />
              </div>
              <h1>Application Submitted Successfully!</h1>
              <p className="register-subtitle">
                Thank you for applying as a professional seller. Your application is now under review.
              </p>
              <div className="success-details">
                <p><strong>Application Details:</strong></p>
                <p><strong>Name:</strong> {formData.fullName}</p>
                <p><strong>Company:</strong> {formData.company}</p>
                <p><strong>Status:</strong> <span style={{color: '#059669', fontWeight: '600'}}>Pending Verification</span></p>
               
                <p style={{marginTop: '0.75rem', color: '#6b7280', fontSize: '0.8rem'}}>
                  You will be redirected to the homepage in 5 seconds...
                </p>
              </div>
            </div>
          </div>
          <div className="success-actions">
            <button className="submit-button secondary" onClick={() => navigate('/')}>
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
          <button className="back-button" onClick={() => navigate(-1)}>
            <FaArrowLeft /> Back
          </button>
          <div className="register-title">
            <div className="register-icon">
              <FaStore />
            </div>
            <h1>Become a Professional Seller</h1>
            <p className="register-subtitle">
              Join our professional drone marketplace and reach qualified buyers worldwide
            </p>
            <p className="email-notice">
              <FaEnvelope /> Application details will be sent to our verification team
            </p>
          </div>
        </div>

        <form className="register-form" onSubmit={handleSubmit} noValidate>
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
                <label>Email Address *</label>
                <div className="input-with-icon">
                  <FaEnvelope className="input-icon" />
                  <input
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
                <label>Phone Number *</label>
                <div className="input-with-icon">
                  <FaPhone className="input-icon" />
                  <input
                    type="tel"
                    name="phone"
                    value={formData.phone}
                    onChange={handleChange}
                    onBlur={handleBlur}
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
            </div>

            {/* Business Information */}
            <div className="form-section">
              <h3><FaBuilding /> Business Information</h3>
              <div className="form-group">
                <label>Company Name *</label>
                <div className="input-with-icon">
                  <FaBuilding className="input-icon" />
                  <input
                    type="text"
                    name="company"
                    value={formData.company}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    placeholder="Enter your company name"
                    className={errors.company && touched.company ? 'error' : ''}
                    disabled={isSubmitting}
                    aria-describedby={errors.company ? "company-error" : undefined}
                  />
                </div>
                {errors.company && touched.company && (
                  <span id="company-error" className="error-message">{errors.company}</span>
                )}
              </div>

              <div className="form-group">
                <label>Location *</label>
                <div className="input-with-icon">
                  <FaMapMarkerAlt className="input-icon" />
                  <input
                    type="text"
                    name="location"
                    value={formData.location}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    placeholder="Enter your location"
                    className={errors.location && touched.location ? 'error' : ''}
                    disabled={isSubmitting}
                    aria-describedby={errors.location ? "location-error" : undefined}
                  />
                </div>
                {errors.location && touched.location && (
                  <span id="location-error" className="error-message">{errors.location}</span>
                )}
              </div>

              <div className="form-group">
                <label>Business Type *</label>
                <div className="input-with-icon">
                  <FaBuilding className="input-icon" />
                  <select
                    name="businessType"
                    value={formData.businessType}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    className={errors.businessType && touched.businessType ? 'error' : ''}
                    disabled={isSubmitting}
                    aria-describedby={errors.businessType ? "businessType-error" : undefined}
                  >
                    <option value="">Select business type</option>
                    <option value="manufacturer">Manufacturer</option>
                    <option value="distributor">Distributor</option>
                    <option value="retailer">Retailer</option>
                    <option value="service-provider">Service Provider</option>
                    <option value="individual">Individual Seller</option>
                    <option value="other">Other</option>
                  </select>
                </div>
                {errors.businessType && touched.businessType && (
                  <span id="businessType-error" className="error-message">{errors.businessType}</span>
                )}
              </div>

              <div className="form-group">
                <label>Tax ID / GST Number</label>
                <div className="input-with-icon">
                  <FaCertificate className="input-icon" />
                  <input
                    type="text"
                    name="taxId"
                    value={formData.taxId}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    placeholder="Enter your tax ID (optional)"
                    disabled={isSubmitting}
                  />
                </div>
              </div>
            </div>

            {/* Product Information */}
            <div className="form-section">
              <h3><FaTag /> Product Information</h3>
              <div className="form-group">
                <label>Product Category *</label>
                <div className="input-with-icon">
                  <FaTag className="input-icon" />
                  <select
                    name="productCategory"
                    value={formData.productCategory}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    className={errors.productCategory && touched.productCategory ? 'error' : ''}
                    disabled={isSubmitting}
                    aria-describedby={errors.productCategory ? "productCategory-error" : undefined}
                  >
                    <option value="">Select category</option>
                    <option value="drones">Complete Drones</option>
                    <option value="parts">Drone Parts</option>
                    <option value="accessories">Accessories</option>
                    <option value="software">Software</option>
                    <option value="training">Training Services</option>
                    <option value="repair">Repair Services</option>
                    <option value="other">Other</option>
                  </select>
                </div>
                {errors.productCategory && touched.productCategory && (
                  <span id="productCategory-error" className="error-message">{errors.productCategory}</span>
                )}
              </div>

              <div className="form-group">
                <label>Website (Optional)</label>
                <div className="input-with-icon">
                  <FaBuilding className="input-icon" />
                  <input
                    type="url"
                    name="website"
                    value={formData.website}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    placeholder="https://yourcompany.com"
                    disabled={isSubmitting}
                  />
                </div>
              </div>

              <div className="form-group">
                <label>Years in Business</label>
                <div className="input-with-icon">
                  <FaCertificate className="input-icon" />
                  <input
                    type="number"
                    name="yearsInBusiness"
                    value={formData.yearsInBusiness}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    placeholder="Number of years"
                    min="0"
                    disabled={isSubmitting}
                  />
                </div>
              </div>
            </div>

            {/* Security Information */}
            {/* <div className="form-section full-width">
              <h3><FaLock /> Security Information</h3>
              <div className="form-row">
                <div className="form-group">
                  <label>Password *</label>
                  <div className="input-with-icon">
                    <FaLock className="input-icon" />
                    <input
                      type="password"
                      name="password"
                      value={formData.password}
                      onChange={handleChange}
                      onBlur={handleBlur}
                      placeholder="Create a password (min 8 characters)"
                      className={errors.password && touched.password ? 'error' : ''}
                      disabled={isSubmitting}
                      aria-describedby={errors.password ? "password-error" : undefined}
                    />
                  </div>
                  {errors.password && touched.password && (
                    <span id="password-error" className="error-message">{errors.password}</span>
                  )}
                  <small className="password-hint">Must be at least 8 characters long</small>
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
                      onBlur={handleBlur}
                      placeholder="Confirm your password"
                      className={errors.confirmPassword && touched.confirmPassword ? 'error' : ''}
                      disabled={isSubmitting}
                      aria-describedby={errors.confirmPassword ? "confirmPassword-error" : undefined}
                    />
                  </div>
                  {errors.confirmPassword && touched.confirmPassword && (
                    <span id="confirmPassword-error" className="error-message">{errors.confirmPassword}</span>
                  )}
                </div>
              </div>
            </div> */}
          </div>

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
                I agree to the <a href="/terms" target="_blank" rel="noopener noreferrer">Terms of Service</a>,{' '}
                <a href="/privacy" target="_blank" rel="noopener noreferrer">Privacy Policy</a>, and{' '}
                <a href="/seller-agreement" target="_blank" rel="noopener noreferrer">Seller Agreement</a>
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
                  Processing Application...
                </>
              ) : (
                'Apply as Seller'
              )}
            </button>

            <div className="form-info">
             
              <p>
                <FaCheckCircle /> Our team will contact you within 24-48 hours
              </p>
            </div>
          </div>
        </form>
      </div>
    </div>
  );
};

export default SellerRegisterPage;