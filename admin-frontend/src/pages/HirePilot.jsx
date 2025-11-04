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

      // ✅ SELECT QUERY BASED ON TAB - NOW INCLUDING URL FIELDS
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
              status
              email
              phoneNumber
              price {
                perHour
                perDay
              }
              certifications {
                url
              }
              resume {
                url
              }
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
            pendingHirePilots {

              pilotId
              pilotName
              pilotCompany
              location
              availability
              specification
              description
              status
              email
              phoneNumber
              price {
                perHour
                perDay
              }
              certifications {
                url
              }
              resume {
                url
              }
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
            approvedHirePilots {

              pilotId
              pilotName
              pilotCompany
              location
              availability
              specification
              description
              status
              email
              phoneNumber
              price {
                perHour
                perDay
              }
              certifications {
                url
              }
              resume {
                url
              }
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
            rejectedHirePilots {

              pilotId
              pilotName
              pilotCompany
              location
              availability
              specification
              description
              status
              email
              phoneNumber
              price {
                perHour
                perDay
              }
              certifications {
                url
              }
              resume {
                url
              }
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
          // Get pilots array from appropriate query result
          let pilotData = [];
          if (activeTab === "all") pilotData = result.data.hirePilots;
          else if (activeTab === "pending") pilotData = result.data.pendingHirePilots;
          else if (activeTab === "approved") pilotData = result.data.approvedHirePilots;
          else if (activeTab === "rejected") pilotData = result.data.rejectedHirePilots;

          setPilots(pilotData);
        }
      } catch (err) {
        setError("Network error: " + err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchPilots();
  }, [activeTab]); // ✅ Re-fetch when tab changes

  // 📝 Handle pilot approval/rejection
  const handleApproval = async (pilotId, status) => {
    const mutation = `
      mutation {
        updateHirePilotStatus(
          pilotId: "${pilotId}"
          status: "${status}"
        ) {
          pilotId
          status
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
        // Refresh pilots after status change
        setActiveTab("all"); // Go back to all pilots
        alert(`Pilot ${status}!`);
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
        <button
          className={`tab-btn ${activeTab === "all" ? "active" : ""}`}
          onClick={() => setActiveTab("all")}
        >
          All Pilots
        </button>
        <button
          className={`tab-btn ${activeTab === "pending" ? "active" : ""}`}
          onClick={() => setActiveTab("pending")}
        >
          Pending
        </button>
        <button
          className={`tab-btn ${activeTab === "approved" ? "active" : ""}`}
          onClick={() => setActiveTab("approved")}
        >
          Approved
        </button>
        <button
          className={`tab-btn ${activeTab === "rejected" ? "active" : ""}`}
          onClick={() => setActiveTab("rejected")}
        >
          Rejected
        </button>
      </div>

      {/* ✅ PILOTS LIST */}
      {pilots.length === 0 ? (
        <p className="no-pilots">No pilots to display.</p>
      ) : (
        <div className="pilots-grid">
          {pilots.map((pilot) => (
            <div key={pilot.id} className="pilot-card">
              <div className="pilot-header">
                <h2>{pilot.pilotName}</h2>
                <span className={`status status-${pilot.status?.toLowerCase()}`}>
                  {pilot.status}
                </span>
              </div>

              <div className="pilot-details">
                <p><strong>Pilot ID:</strong> {pilot.pilotId}</p>
                {pilot.pilotCompany && <p><strong>Company:</strong> {pilot.pilotCompany}</p>}
                <p><strong>Email:</strong> {pilot.email}</p>
                <p><strong>Phone:</strong> {pilot.phoneNumber}</p>
                {pilot.location && <p><strong>Location:</strong> {pilot.location}</p>}
                <p><strong>Available:</strong> {pilot.availability ? "Yes" : "No"}</p>
                {pilot.specification && <p><strong>Specification:</strong> {pilot.specification}</p>}
                {pilot.description && <p><strong>Description:</strong> {pilot.description}</p>}

                {pilot.price && (
                  <p className="price">
                    <strong>Price:</strong> ₹{pilot.price.perHour}/hr, ₹{pilot.price.perDay}/day
                  </p>
                )}

                {/* ✅ DISPLAY CERTIFICATION PDF LINKS */}
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

                {/* ✅ DISPLAY RESUME PDF LINK */}
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

                {pilot.seller && (
                  <div className="seller-info">
                    <p><strong>Seller:</strong> {pilot.seller.name}</p>
                    <p><strong>Seller Email:</strong> {pilot.seller.email}</p>
                    <p><strong>Seller Phone:</strong> {pilot.seller.phoneNumber}</p>
                  </div>
                )}
              </div>

              {/* ✅ SHOW ACTION BUTTONS ONLY FOR PENDING */}
              {pilot.status?.toLowerCase() === "pending" && (
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