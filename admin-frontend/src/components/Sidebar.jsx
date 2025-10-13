import { Link } from "react-router-dom";
import { FaUserFriends, FaPlane, FaCogs, FaHome,FaTools,FaTimesCircle } from "react-icons/fa";
import "../styles/Sidebar.css";

function Sidebar() {
  return (
    <aside className="sidebar">
      <div className="sidebar-header">⚡ Admin Panel</div>
      <nav className="sidebar-nav">
        <ul>
          <li><Link to="/"><FaHome /> Dashboard</Link></li>
          <li><Link to="/users"><FaUserFriends /> Users</Link></li>
          <li><Link to="/reports">< FaPlane  /> Drones</Link></li>
           <li><Link to="/Parts"><FaCogs/> Parts</Link></li>
            <li><Link to="/accessories"><FaTools /> Accessories</Link></li>
             <li><Link to="/rejected"><FaTimesCircle /> Rejected</Link></li>
            
          <li><Link to="/settings"><FaCogs /> Settings</Link></li>
        </ul>
      </nav>
    </aside>
  );
}

export default Sidebar;