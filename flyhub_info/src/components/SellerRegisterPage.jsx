import React, { useState } from 'react';
import { FaUser, FaEnvelope, FaPhone, FaBuilding, FaMapMarkerAlt, FaLock, FaArrowLeft, FaStore, FaTag, FaCertificate } from 'react-icons/fa';
import { useNavigate } from 'react-router-dom';
import emailjs from 'emailjs-com';
import '../styles/Register.css';

const SellerRegisterPage = () => {
  const navigate = useNavigate();
  const [formData, setFormData] = useState({
    fullName: '',
    email: '',
    phone: '',
    company: '',
    location: '',
    password: '',
    confirmPassword: '',
    businessType: '',
    productCategory: '',
    website: '',
    taxId: '',
    yearsInBusiness: ''
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
    if (!formData.company.trim()) newErrors.company = 'Company name is required';
    if (!formData.location.trim()) newErrors.location = 'Location is required';
    if (!formData.password) newErrors.password = 'Password is required';
    else if (formData.password.length < 8) newErrors.password = 'Password must be at least 8 characters';
    
    if (formData.password !== formData.confirmPassword) {
      newErrors.confirmPassword = 'Passwords do not match';
    }
    if (!formData.businessType) newErrors.businessType = 'Business type is required';
    if (!formData.productCategory) newErrors.productCategory = 'Product category is required';

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
      company: formData.company,
      location: formData.location,
      business_type: formData.businessType,
      product_category: formData.productCategory,
      website: formData.website,
      tax_id: formData.taxId,
      years_in_business: formData.yearsInBusiness,
      registration_date: new Date().toLocaleDateString(),
      registration_time: new Date().toLocaleTimeString(),
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
      // Send email using EmailJS
      await emailjs.send(
        'service_08i9xxq',
        'template_rfwj9nv',
        templateParams,
        'JnZ2d3mdX1e6uuo03'
      );
      
      setSubmitSuccess(true);
      console.log('Seller registration data:', formData);
      
      // Reset form
      setFormData({
        fullName: '',
        email: '',
        phone: '',
        company: '',
        location: '',
        password: '',
        confirmPassword: '',
        businessType: '',
        productCategory: '',
        website: '',
        taxId: '',
        yearsInBusiness: ''
      });
      
      // Show success message
      alert('Registration submitted successfully! A confirmation email has been sent to our verification team.');
      
      // Navigate to homepage after 3 seconds
      setTimeout(() => {
        navigate('/');
      }, 3000);
      
    } catch (error) {
      console.error('Error sending email:', error);
      alert('Registration submitted! Your application is pending verification.');
      
      // Still proceed with registration even if email fails
      console.log('Seller registration data (offline):', formData);
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
                <FaStore />
              </div>
              <h1>Application Submitted Successfully!</h1>
              <p className="register-subtitle">
                Thank you for applying as a professional seller. Your application is now under review.
              </p>
              <div className="success-details">
                <p><strong>Application Details:</strong></p>
                <p><strong>Name:</strong> {formData.fullName}</p>
                <p><strong>Company:</strong> {formData.company}</p>
                <p><strong>Status:</strong> Pending Verification</p>
                <p>You will be contacted via email once your application is reviewed.</p>
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
                    placeholder="Enter your business email"
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
                    placeholder="Enter your company name"
                    className={errors.company ? 'error' : ''}
                    disabled={isSubmitting}
                  />
                </div>
                {errors.company && <span className="error-message">{errors.company}</span>}
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
                    placeholder="Enter your location"
                    className={errors.location ? 'error' : ''}
                    disabled={isSubmitting}
                  />
                </div>
                {errors.location && <span className="error-message">{errors.location}</span>}
              </div>

              <div className="form-group">
                <label>Business Type *</label>
                <div className="input-with-icon">
                  <FaBuilding className="input-icon" />
                  <select
                    name="businessType"
                    value={formData.businessType}
                    onChange={handleChange}
                    className={errors.businessType ? 'error' : ''}
                    disabled={isSubmitting}
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
                {errors.businessType && <span className="error-message">{errors.businessType}</span>}
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
                    className={errors.productCategory ? 'error' : ''}
                    disabled={isSubmitting}
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
                {errors.productCategory && <span className="error-message">{errors.productCategory}</span>}
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
                    placeholder="Number of years"
                    min="0"
                    disabled={isSubmitting}
                  />
                </div>
              </div>
            </div>

            {/* Security Information */}
            <div className="form-section full-width">
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
                      placeholder="Create a password"
                      className={errors.password ? 'error' : ''}
                      disabled={isSubmitting}
                    />
                  </div>
                  {errors.password && <span className="error-message">{errors.password}</span>}
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
                I agree to the <a href="/terms">Terms of Service</a>, <a href="/privacy">Privacy Policy</a>, and <a href="/seller-agreement">Seller Agreement</a>
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
                  Submitting Application...
                </>
              ) : (
                'Apply as Seller'
              )}
            </button>

          </div>
        </form>
      </div>
    </div>
  );
};

export default SellerRegisterPage;