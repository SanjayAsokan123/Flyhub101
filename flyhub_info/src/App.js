import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Home from './pages/Home';
import Features from './components/Features';
import Categories from './components/Categories';
import Navbar from './components/Navbar'; // Import Navbar
import Footer from './components/Footer'; // Import Footer
import Franchise from './components/Franchise';
import './styles.css';
import Role from './components/Role';
import BuyerRegisterPage from './components/BuyerRegisterPage';
import SellerRegisterPage from './components/SellerRegisterPage';

function App() {
  return (
    <Router>
      <div className="App">
        <Navbar /> {/* Add Navbar here */}
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/features" element={<Features />} />
          <Route path="/categories" element={<Categories />} />
          <Route path="/franchise" element={<Franchise />} />
                  <Route path="/" element={<Role />} />
        <Route path="/register/buyer" element={<BuyerRegisterPage />} />
        <Route path="/register/seller" element={<SellerRegisterPage />} />

        </Routes>
        <Footer /> {/* Add Footer here */}
      </div>
    </Router>
  );
}

export default App;