import React, { useState, useEffect } from "react";
import "../styles/Drones.css";

const GRAPHQL_URL = "http://127.0.0.1:5001/graphql";

function DroneApproval() {
  const [drones, setDrones] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [selectedStatus, setSelectedStatus] = useState("pending");

  // Fetch drones
  const fetchDrones = async () => {
    setLoading(true);
    setError(null);

    const query = `
      query {
        drones {
          uin
          name
          brand
          price
          description
          image
          status
        }
      }
    `;

    try {
      const res = await fetch(GRAPHQL_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ query }),
      });

      if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);

      const result = await res.json();

      if (result.errors) {
        setError(result.errors[0].message);
        setDrones([]);
      } else {
        setDrones(result.data.drones);
      }
    } catch (err) {
      setError("Network error: " + err.message);
      setDrones([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDrones();
  }, []);

  // Approve or Reject Drone
  const handleApproval = async (uin, newStatus) => {
    const mutation = `
      mutation UpdateDroneStatus($uin: String!, $status: String!) {
        updateDroneStatus(uin: $uin, status: $status) {
          uin
          status
        }
      }
    `;

    try {
      const res = await fetch(GRAPHQL_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          query: mutation,
          variables: { uin, status: newStatus },
        }),
      });

      if (!res.ok) throw new Error(`HTTP error! status: ${res.status}`);

      const result = await res.json();

      if (result.errors) {
        alert(`Error: ${result.errors[0].message}`);
        return;
      }

      const updated = result.data.updateDroneStatus;

      setDrones((prev) =>
        prev.map((d) =>
          d.uin === updated.uin ? { ...d, status: updated.status } : d
        )
      );

      alert(`Drone ${newStatus} successfully!`);
    } catch (err) {
      alert("Network error: " + err.message);
    }
  };

  if (loading) return <p>Loading drones...</p>;
  if (error) return <p style={{ color: "red" }}>Error: {error}</p>;

  const filtered = drones.filter(
    (d) => d.status.toLowerCase() === selectedStatus
  );

  return (
    <div className="page">
      <h2>🛸 Drone Approval Dashboard</h2>

      {/* Tabs */}
      <div className="status-tabs">
        {["pending", "approved", "rejected"].map((status) => (
          <button
            key={status}
            className={`status-tab ${
              selectedStatus === status ? "active" : ""
            }`}
            onClick={() => setSelectedStatus(status)}
          >
            {status === "pending" && "⏳ Pending"}
            {status === "approved" && "✅ Approved"}
            {status === "rejected" && "❌ Rejected"}
          </button>
        ))}
      </div>

      {/* Drone Grid */}
      <div className="drone-cards">
        {filtered.length === 0 ? (
          <p>No {selectedStatus} drones.</p>
        ) : (
          filtered.map((d) => (
            <div key={d.uin} className="drone-card">
              <div className={`status-badge-top ${d.status.toLowerCase()}`}>
                {d.status}
              </div>

              <img src={d.image} alt={d.name} className="drone-image" />

              <h3>{d.name}</h3>
              <p><strong>Brand:</strong> {d.brand}</p>
              <p><strong>UIN:</strong> {d.uin}</p>
              <p><strong>Price:</strong> ₹{d.price}</p>
              <p><strong>Description:</strong> {d.description}</p>

              <div className="actions">
                {d.status !== "approved" && (
                  <button
                    onClick={() => handleApproval(d.uin, "approved")}
                    className="approve-btn"
                  >
                    ✅ Approve
                  </button>
                )}

                {d.status !== "rejected" && (
                  <button
                    onClick={() => handleApproval(d.uin, "rejected")}
                    className="reject-btn"
                  >
                    ❌ Reject
                  </button>
                )}

                {d.status !== "pending" && (
                  <button
                    onClick={() => handleApproval(d.uin, "pending")}
                    className="reset-btn"
                  >
                    🔄 Move to Pending
                  </button>
                )}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}

export default DroneApproval;
