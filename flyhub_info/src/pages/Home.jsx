import React from 'react';

import Hero from '../components/Hero';
import Features from '../components/Features';
import Categories from '../components/Categories';
import AppInfo from '../components/AppInfo';

import Role from '../components/Role';

const Home = () => {
  return (
    <div className="home-page">
     
      <Hero />
      <Role />
      <Features />
      <Categories />
      <AppInfo />
    
    </div>
  );
};

export default Home;