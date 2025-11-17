import React, { useState, useEffect } from "react";
import "../styles/HirePilot.css";

const GRAPHQL_URL = "http://127.0.0.1:5001/graphql";

function HirePilotsDashboard() {
  const [pilots, setPilots] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [activeTab, setActiveTab] = useState("all"); // all, pending, approved, rejected

  // 🔄 Fetch pilots based on status tab
  useEffect(() => {
    const fetchPilots = async () => {
      setLoading(true);
      setError(null);

      let query;

      // ✅ SELECT QUERY BASED ON TAB
      if (activeTab === "all") {
        query = `
          query {
            hirePilots {
              pilotId
              pilotName
              pilotCompany
              location
              availability
              specification
              description
              adminStatus
              newemail
              newphoneNumber
              price { perHour perDay }
              certifications { url }
              resume { url }
              sellerId
              seller {
                customId
                name
                email
                phoneNumber
              }
            }
          }
        `;
      } else if (activeTab === "pending") {
        query = `
          query {
            hirePilotsByStatus(adminStatus: "pending") {
              pilotId
              pilotName
              pilotCompany
              location
              availability
              specification
              description
              adminStatus
              newemail
              newphoneNumber
              price { perHour perDay }
              certifications { url }
              resume { url }
              sellerId
              seller {
                customId
                name
                email
                phoneNumber
              }
            }
          }
        `;
      } else if (activeTab === "approved") {
        query = `
          query {
            hirePilotsByStatus(adminStatus: "approved") {
              pilotId
              pilotName
              pilotCompany
              location
              availability
              specification
              description
              adminStatus
              newemail
              newphoneNumber
              price { perHour perDay }
              certifications { url }
              resume { url }
              sellerId
              seller {
                customId
                name
                email
                phoneNumber
              }
            }
          }
        `;
      } else if (activeTab === "rejected") {
        query = `
          query {
            hirePilotsByStatus(adminStatus: "rejected") {
              pilotId
              pilotName
              pilotCompany
              location
              availability
              specification
              description
              adminStatus
              newemail
              newphoneNumber
              price { perHour perDay }
              certifications { url }
              resume { url }
              sellerId
              seller {
                customId
                name
                email
                phoneNumber
              }
            }
          }
        `;
      }

      try {
        const res = await fetch(GRAPHQL_URL, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ query }),
        });

        const result = await res.json();

        if (result.errors) {
          setError(result.errors[0].message);
        } else {
          let pilotData = [];
          if (activeTab === "all") pilotData = result.data.hirePilots;
          else pilotData = result.data.hirePilotsByStatus;

          setPilots(pilotData);
        }
      } catch (err) {
        setError("Network error: " + err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchPilots();
  }, [activeTab]);

  // 📝 Handle pilot approval/rejection
  const handleApproval = async (pilotId, status) => {
    const mutation = `
      mutation {
        adminUpdateHirePilotStatus(
          pilotId: "${pilotId}"
          adminStatus: "${status}"
        ) {
          pilotId
          adminStatus
        }
      }
    `;

    try {
      const res = await fetch(GRAPHQL_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ query: mutation }),
      });

      const result = await res.json();

      if (result.errors) {
        alert("Error updating pilot: " + result.errors[0].message);
      } else {
        // ✅ Use safe concatenation (no backticks)
        alert("Pilot " + status + " successfully!");
        setActiveTab("all"); // Refresh data
      }
    } catch (err) {
      console.error("Error updating pilot status:", err);
    }
  };

  if (loading) return <div className="loading">Loading hire pilots...</div>;
  if (error) return <div className="error">Error: {error}</div>;

  return (
    <div className="pilots-dashboard">
      <h1>Hire Pilots Dashboard</h1>

      {/* ✅ TAB NAVIGATION */}
      <div className="tab-navigation">
        {["all", "pending", "approved", "rejected"].map((tab) => (
          <button
            key={tab}
            className={`tab-btn ${activeTab === tab ? "active" : ""}`}
            onClick={() => setActiveTab(tab)}
          >
            {tab.toUpperCase()}
          </button>
        ))}
      </div>

      {/* ✅ PILOTS LIST */}
      {pilots.length === 0 ? (
        <p className="no-pilots">No pilots to display.</p>
      ) : (
        <div className="pilots-grid">
          {pilots.map((pilot) => (
            <div key={pilot.pilotId} className="pilot-card">
              <div className="pilot-header">
                <h2>{pilot.pilotName}</h2>
                <span className={`status status-${pilot.adminStatus?.toLowerCase()}`}>
                  {pilot.adminStatus}
                </span>
              </div>

              <div className="pilot-details">
                <p><strong>Pilot ID:</strong> {pilot.pilotId}</p>
                {pilot.pilotCompany && <p><strong>Company:</strong> {pilot.pilotCompany}</p>}
                <p><strong>Email:</strong> {pilot.newemail}</p>
                <p><strong>Phone:</strong> {pilot.newphoneNumber}</p>
                {pilot.location && <p><strong>Location:</strong> {pilot.location}</p>}
                <p><strong>Available:</strong> {pilot.availability ? "Yes" : "No"}</p>
                {pilot.specification && <p><strong>Specification:</strong> {pilot.specification}</p>}
                {pilot.description && <p><strong>Description:</strong> {pilot.description}</p>}

                {pilot.price && (
                  <p className="price">
                    <strong>Price:</strong> ₹{pilot.price.perHour}/hr, ₹{pilot.price.perDay}/day
                  </p>
                )}

                {/* ✅ Certifications */}
                {pilot.certifications && pilot.certifications.length > 0 && (
                  <div className="documents-section">
                    <p><strong>Certifications:</strong></p>
                    <ul className="document-links">
                      {pilot.certifications.map((cert, index) => (
                        <li key={index}>
                          <a
                            href={cert.url}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="pdf-link"
                          >
                            📄 Certification {index + 1}
                          </a>
                        </li>
                      ))}
                    </ul>
                  </div>
                )}

                {/* ✅ Resume */}
                {pilot.resume && pilot.resume.url && (
                  <div className="documents-section">
                    <p><strong>Resume:</strong></p>
                    <a
                      href={pilot.resume.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="pdf-link"
                    >
                      📄 View Resume
                    </a>
                  </div>
                )}

                {/* ✅ Seller Info */}
                {pilot.seller && (
                  <div className="seller-info">
                    <p><strong>Seller:</strong> {pilot.seller.name}</p>
                    <p><strong>Seller Email:</strong> {pilot.seller.email}</p>
                    <p><strong>Seller Phone:</strong> {pilot.seller.phoneNumber}</p>
                  </div>
                )}
              </div>

              {/* ✅ Actions for pending pilots */}
              {pilot.adminStatus?.toLowerCase() === "pending" && (
                <div className="pilot-actions">
                  <button
                    className="btn-approve"
                    onClick={() => handleApproval(pilot.pilotId, "approved")}
                  >
                    Approve
                  </button>
                  <button
                    className="btn-reject"
                    onClick={() => handleApproval(pilot.pilotId, "rejected")}
                  >
                    Reject
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

export default HirePilotsDashboard;
