import React from 'react';
import Navbar from '../components/Navbar';
import Hero from '../components/Hero';
import Features from '../components/Features';
import Categories from '../components/Categories';
import AppInfo from '../components/AppInfo';
import Footer from '../components/Footer';

const Home = () => {
  return (
    <div className="home-page">
      <Navbar />
      <Hero />
      <Features />
      <Categories />
      <AppInfo />
      <Footer />
    </div>
  );
};

export default Home;