import { Link } from "react-router-dom";
import {
  FaUserFriends,
  FaPlane,
  FaCogs,
  FaHome,
  FaTools,
  FaTimesCircle,
  FaChalkboardTeacher,
  FaBriefcase,
  FaRegClipboard,
  FaHandshake,
  FaWrench,
  FaClipboardCheck,
  FaBuilding,
} from "react-icons/fa";
import "../styles/Sidebar.css";

function Sidebar() {
  return (
    <aside className="sidebar">
      <div className="sidebar-header">⚡ Admin Panel</div>
      <nav className="sidebar-nav">
        <ul>
          <li><Link to="/"><FaHome /> Dashboard</Link></li>
          <li><Link to="/users"><FaUserFriends /> Users</Link></li>
          <li><Link to="/reports"><FaPlane /> Drones</Link></li>
          <li><Link to="/parts"><FaCogs /> Parts</Link></li>
          <li><Link to="/accessories"><FaTools /> Accessories</Link></li>
          <li><Link to="/training"><FaChalkboardTeacher /> Training</Link></li>
          <li><Link to="/rentals"><FaBriefcase /> Rentals</Link></li>
          <li><Link to="/services"><FaWrench /> Services</Link></li>
          <li><Link to="/regulatory"><FaClipboardCheck /> Regulatory</Link></li>
          <li><Link to="/pilot"><FaHandshake /> Hire Pilot</Link></li>
          <li><Link to="/job"><FaRegClipboard /> Hire Job</Link></li>
          <li><Link to="/seller"><FaBuilding /> Seller Approval</Link></li>
          <li><Link to="/rejected"><FaTimesCircle /> Rejected</Link></li>
          <li><Link to="/settings"><FaCogs /> Settings</Link></li>
        </ul>
      </nav>
    </aside>
  );
}

export default Sidebar;
