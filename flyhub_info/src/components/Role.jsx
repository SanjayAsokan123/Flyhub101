import React from 'react';
import { FaShoppingCart, FaStore, FaCheckCircle, FaUsers, FaShieldAlt, FaArrowRight, FaClock, FaUserGraduate, FaStar } from 'react-icons/fa';
import { useNavigate } from 'react-router-dom';
import '../styles/role.css';

// Training courses data with specific images for your courses
const trainingCourses = [
  { 
    id: 1, 
    title: 'Small RPC Training', 
    duration: '5 days', 
    students: 850, 
    rating: 4.7, 
    image: 'https://images.unsplash.com/photo-1671043120956-f35166f77f87?q=80&w=1169&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D' 
  },
  { 
    id: 2, 
    title: 'Medium RPC Training', 
    duration: '5 days', 
    students: 620, 
    rating: 4.8, 
    image: 'https://images.unsplash.com/photo-1657282284426-b9a05867f49b?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D' 
  },
  { 
    id: 3, 
    title: 'Small & Medium RPC', 
    duration: '8 days', 
    students: 1120, 
    rating: 4.9, 
    image: 'https://images.unsplash.com/photo-1514144385048-7d9b93766a5b?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D' 
  },
  { 
    id: 4, 
    title: 'RPC Upgradation', 
    duration: '3 days', 
    students: 450, 
    rating: 4.6, 
    image: 'https://images.unsplash.com/photo-1660141259396-858ed837477a?q=80&w=764&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D' 
  },
  { 
    id: 5, 
    title: 'FPV Training', 
    duration: '14 days', 
    students: 780, 
    rating: 4.8, 
    image: 'https://images.unsplash.com/photo-1721249710785-3a0cb565707b?q=80&w=735&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D' 
  },
  { 
    id: 6, 
    title: 'Crop Monitoring', 
    duration: '5 days', 
    students: 920, 
    rating: 4.7, 
    image: 'https://plus.unsplash.com/premium_photo-1664478063149-295e8449a105?q=80&w=1169&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D' 
  },
  { 
    id: 7, 
    title: 'Agri Drone', 
    duration: '5 days', 
    students: 1340, 
    rating: 4.9, 
    image: 'https://images.unsplash.com/photo-1720071702672-d18c69cb475c?q=80&w=1332&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D' 
  },
  { 
    id: 8, 
    title: 'Aerial Mapping & Surveying', 
    duration: '5 days', 
    students: 1050, 
    rating: 4.8, 
    image: 'https://images.unsplash.com/photo-1674331718483-24725d1080a8?q=80&w=1074&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D' 
  },
];

const Role = () => {
  const navigate = useNavigate();

  const handleBuyerRegister = () => {
    navigate('/register/buyer');
  };

  const handleSellerRegister = () => {
    navigate('/register/seller');
  };

  return (
    <div className="platform-roles">
      {/* Section Header */}
      <div className="section-header">
        <h2>Choose Your Role</h2>
        <p className="section-subtitle">Professional platform for every drone industry participant</p>
      </div>
      
      {/* Role Selection Cards with Images */}
      <div className="roles-compact-container">
        {/* Buyer Card */}
        <div className="compact-role-card buyer-card">
          <div 
            className="role-image"
            style={{ 
              backgroundImage: 'url(https://images.unsplash.com/photo-1642543348781-ed9c6d67ed20?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D)'
            }}
          >
            <div className="image-overlay">
              <div className="compact-card-content">
                <div className="compact-icon">
                  <FaShoppingCart />
                </div>
                <div className="compact-info">
                  <h3>Become a Buyer</h3>
                  <p>Access verified inventory & secure transactions</p>
                </div>
                <button className="compact-cta" onClick={handleBuyerRegister}>
                  <FaArrowRight />
                </button>
              </div>
            </div>
          </div>
        </div>
        
        {/* Seller Card */}
        <div className="compact-role-card seller-card">
          <div 
            className="role-image"
            style={{ 
              backgroundImage: 'url(https://images.unsplash.com/photo-1642543348791-b1cc1b07e756?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D)'
            }}
          >
            <div className="image-overlay">
              <div className="compact-card-content">
                <div className="compact-icon">
                  <FaStore />
                </div>
                <div className="compact-info">
                  <h3>Become a Seller</h3>
                  <p>Reach professional buyers & manage inventory</p>
                </div>
                <button className="compact-cta" onClick={handleSellerRegister}>
                  <FaArrowRight />
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
      
      {/* Training Section */}
      <div className="training-section">
        <div className="training-header">
          <h2>Professional Training Programs</h2>
          <p className="section-subtitle">Master drone technology with industry-certified courses</p>
        </div>
        
        {/* Scrolling Courses Container */}
        <div className="courses-scroll-container">
          <div className="courses-grid">
            {trainingCourses.map((course) => (
              <div key={course.id} className="course-card">
                <div 
                  className="course-image"
                  style={{ backgroundImage: `url(${course.image})` }}
                >
                  <div className="course-info-overlay">
                    <h4>{course.title}</h4>
                    <div className="course-meta">
                      <span className="meta-item">
                        <FaClock /> {course.duration}
                      </span>
                      <span className="meta-item">
                        <FaUserGraduate /> {course.students.toLocaleString()}
                      </span>
                      <span className="meta-item">
                        <FaStar /> {course.rating}
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
      
      {/* Platform Benefits */}
      <div className="platform-benefits">
        <div className="benefit-item">
          <div className="benefit-icon">
            <FaShieldAlt />
          </div>
          <div className="benefit-content">
            <h4>Enterprise Security</h4>
            <p>Bank-level encryption and secure payment processing</p>
          </div>
        </div>
        <div className="benefit-item">
          <div className="benefit-icon">
            <FaUsers />
          </div>
          <div className="benefit-content">
            <h4>Verified Community</h4>
            <p>All users undergo professional verification process</p>
          </div>
        </div>
        <div className="benefit-item">
          <div className="benefit-icon">
            <FaCheckCircle />
          </div>
          <div className="benefit-content">
            <h4>Quality Assurance</h4>
            <p>Rigorous product verification and quality checks</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Role;