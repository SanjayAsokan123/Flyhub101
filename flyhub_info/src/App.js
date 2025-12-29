import React from 'react';
import { BrowserRouter as Router, Routes, Route, useLocation } from 'react-router-dom';
import Home from './pages/Home';
import Features from './components/Features';
import Categories from './components/Categories';
import Navbar from './components/Navbar'; // Import Navbar
import Footer from './components/Footer'; // Import Footer
import Franchise from './components/Franchise';
import Contact from './components/Contact';
import './styles.css';
import Role from './components/Role';
import BuyerRegisterPage from './components/BuyerRegisterPage';
import SellerRegisterPage from './components/SellerRegisterPage';
import Termsandcondition from './components/Termsandcondition';
import PrivacyPolicy from './components/PrivacyPolicy';
import About from './components/About';



// ScrollToTop component
const ScrollToTop = () => {
  const { pathname } = useLocation();

  React.useEffect(() => {
    window.scrollTo({
      top: 0,
      left: 0,
      behavior: 'smooth' // You can change to 'auto' for instant scroll
    });
  }, [pathname]);

  return null;
};

function App() {
  return (
    <Router>
      <div className="App">
        <ScrollToTop /> {/* Add ScrollToTop here */}
        <Navbar /> {/* Add Navbar here */}
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/features" element={<Features />} />
          <Route path="/categories" element={<Categories />} />
          <Route path="/franchise" element={<Franchise />} />
          <Route path="/contact" element={<Contact />} />
          <Route path="/role" element={<Role />} /> {/* Fixed duplicate path */}
          <Route path="/register/buyer" element={<BuyerRegisterPage />} />
          <Route path="/register/seller" element={<SellerRegisterPage />} />
             <Route path="/terms" element={<Termsandcondition />} />
          <Route path="/privacy" element={<PrivacyPolicy />} />
           <Route path="/about-us" element={<About />} />
        </Routes>
        <Footer /> {/* Add Footer here */}
      </div>
    </Router>
  );
}

export default App;