import React, { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { MdLocalShipping } from "react-icons/md";

import {
  FaUserFriends,
  FaPlane,
  FaCogs,
  FaHome,
  FaTools,
  FaRegNewspaper,
  FaServicestack,
  FaChevronDown,
  FaChevronRight,
  FaUserTie,
  FaUndoAlt,
  FaUserTag,
  FaBriefcase,
  FaShoppingCart,
  FaHelicopter,
  FaSignOutAlt,
  FaBookOpen,
  FaTimesCircle,
  FaBuilding,
} from "react-icons/fa";
import "../styles/Sidebar.css";

function Sidebar() {
  const [openUsers, setOpenUsers] = useState(false);
  const [openSeller, setOpenSeller] = useState(false);
  const [openBuyer, setOpenBuyer] = useState(false);
  const [openRentals, setOpenRentals] = useState(false);

  const navigate = useNavigate();

  const handleLogout = () => {
    localStorage.removeItem("isLoggedIn");
    navigate("/login");
  };

  return (
    <aside className="sidebar">
      {/* Sidebar Header */}
      <div className="sidebar-header">
        <img src="/flyhubicon.svg" alt="Flyhub Logo" className="sidebar-logo" />
      </div>

      {/* Navigation */}
      <nav className="sidebar-nav">
        <ul>
          {/* Dashboard */}
          <li>
            <Link to="/">
              <FaHome /> Dashboard
            </Link>
          </li>

          {/* Users Dropdown */}
          <li className={`dropdown ${openUsers ? "open" : ""}`}>
            <div
              className="dropdown-toggle"
              onClick={() => setOpenUsers(!openUsers)}
            >
              <FaUserFriends /> Users
              {openUsers ? <FaChevronDown /> : <FaChevronRight />}
            </div>

            {openUsers && (
              <ul className="dropdown-menu">

                {/* Seller Dropdown */}
                <li className={`dropdown ${openSeller ? "open" : ""}`}>
                  <div
                    className="dropdown-toggle"
                    onClick={() => setOpenSeller(!openSeller)}
                  >
                    <FaUserTag /> Seller
                    {openSeller ? <FaChevronDown /> : <FaChevronRight />}
                  </div>

                  {openSeller && (
                    <ul className="dropdown-submenu">
                      <li>
                        <Link to="/drones">
                          <FaPlane /> Drones
                        </Link>
                      </li>
                      <li>
                        <Link to="/parts">
                          <FaCogs /> Parts
                        </Link>
                      </li>
                      <li>
                        <Link to="/accessories">
                          <FaTools /> Accessories
                        </Link>
                      </li>
                      <li>
                        <Link to="/seller">
                          <FaBuilding /> Seller Approval
                        </Link>
                      </li>
                      <li>
                        <Link to="/services">
                          <FaServicestack /> Services
                        </Link>
                      </li>
                    </ul>
                  )}
                </li>

                {/* Buyer Dropdown */}
                <li className={`dropdown ${openBuyer ? "open" : ""}`}>
                  <div
                    className="dropdown-toggle"
                    onClick={() => setOpenBuyer(!openBuyer)}
                  >
                    <FaUserTie /> Buyer
                    {openBuyer ? <FaChevronDown /> : <FaChevronRight />}
                  </div>

                  {openBuyer && (
                    <ul className="dropdown-submenu">
                      <li>
                        <Link to="/return-product">
                          <FaUndoAlt /> Return Product
                        </Link>
                      </li>
                      <li>
                        <Link to="/sold-product">
                          <FaShoppingCart /> Sold Product
                        </Link>
                      </li>
                      <li>
                        <Link to="/orders">
                          <MdLocalShipping /> Orders
                        </Link>
                      </li>
                      <li>
                          <Link to="/RegisteredBuyer">
                           <MdLocalShipping /> RegisteredBuyer
                         </Link>
                        </li>
                        <li>
                            <Link to="/RegisteredSeller">
                                 <MdLocalShipping /> RegisteredSeller
                            </Link>
                        </li>

                      <li>
                          <Link to="/PilotBookingStatus">
                            <MdLocalShipping /> PilotBookingStatus
                          </Link>
                      </li>
                      <li>
                          <Link to="/DroneBookingStatus">
                            <MdLocalShipping /> DroneBookingStatus
                          </Link>
                      </li>
                    </ul>
                  )}
                </li>

              </ul>
            )}
          </li>

          {/* Rentals Dropdown */}
          <li className={`dropdown ${openRentals ? "open" : ""}`}>
            <div
              className="dropdown-toggle"
              onClick={() => setOpenRentals(!openRentals)}
            >
              <FaRegNewspaper /> Rentals
              {openRentals ? <FaChevronDown /> : <FaChevronRight />}
            </div>

            {openRentals && (
              <ul className="dropdown-menu">
                <li>
                  <Link to="/rentals">
                    <FaHelicopter /> Drone Rental
                  </Link>
                </li>
                <li>
                  <Link to="/pilot">
                    <FaUserTie /> Pilot
                  </Link>
                </li>
                <li>
                  <Link to="/job">
                    <FaBriefcase /> Job
                  </Link>
                </li>
              </ul>
            )}
          </li>

          {/* Other Links */}
          <li>
            <Link to="/regulatory">
              <FaRegNewspaper /> Regulatory
            </Link>
          </li>

          <li>
            <Link to="/training-page">
              <FaBookOpen /> Training
            </Link>
          </li>

          <li>
            <Link to="/rejected">
              <FaTimesCircle /> Rejected
            </Link>
          </li>

        </ul>
      </nav>

      {/* Logout Button */}
      <div className="sidebar-logout">
        <button onClick={handleLogout} className="logout-btn">
          <FaSignOutAlt /> Logout
        </button>
      </div>
    </aside>
  );
}

export default Sidebar;
