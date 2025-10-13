import React, { useState, useEffect } from "react";
import "../styles/Page.css";

const GRAPHQL_URL = "http://127.0.0.1:5001/graphql";

function DroneApproval() {
  const [drones, setDrones] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const fetchDrones = async () => {
    setLoading(true);
    setError(null);

    const query = `
      query {
        drones {
          id
          name
          brand
          uin
          price
          description
          image
          status
        }
      }
    `;

    try {
      const response = await fetch(GRAPHQL_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ query }),
      });
      const result = await response.json();

      if (result.errors) setError(result.errors[0].message);
      else {
        const rejected = JSON.parse(localStorage.getItem("rejectedDrones")) || [];
        const filtered = result.data.drones.filter(
          (d) => !rejected.some((r) => r.id === d.id)
        );
        setDrones(filtered);
      }
    } catch (err) {
      setError("Network error: " + err.message);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDrones();
  }, []);

  const handleApproval = async (id, status) => {
    const mutation = `
      mutation {
        updateDroneStatus(id: "${id}", status: "${status}") {
          id status
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
      if (!result.errors) {
        setDrones((prev) =>
          prev
            .map((d) => (d.id === id ? { ...d, status } : d))
            .filter((d) => d.status !== "rejected")
        );
        if (status === "rejected") {
          const store = JSON.parse(localStorage.getItem("rejectedDrones")) || [];
          store.push(result.data.updateDroneStatus);
          localStorage.setItem("rejectedDrones", JSON.stringify(store));
        }
      }
    } catch (e) {
      console.error("Error:", e);
    }
  };

  const handleApproveAll = async () => {
    const mutation = `
      mutation {
        approveAllPending(type: "drones") {
          success count message
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
      if (result.errors) alert("❌ " + result.errors[0].message);
      else {
        alert("✅ " + result.data.approveAllPending.message);
        fetchDrones();
      }
    } catch (err) {
      alert("Network error: " + err.message);
    }
  };

  if (loading) return <p>Loading drones...</p>;
  if (error) return <p style={{ color: "red" }}>Error: {error}</p>;

  return (
    <div className="page">
      <h2>🛸 Drone Approval Dashboard</h2>
      <div className="bulk-actions">
        <button className="approve-all-btn" onClick={handleApproveAll}>
          ✅ Approve All Pending Drones
        </button>
      </div>

      <div className="drone-cards">
        {drones.length === 0 && <p>No drones to approve.</p>}
        {drones.map((d) => (
          <div key={d.id} className="drone-card">
            <img src={d.image} alt={d.name} className="drone-image" />
            <h3>{d.name}</h3>
            <p><strong>Brand:</strong> {d.brand}</p>
            <p><strong>UIN:</strong> {d.uin}</p>
            <p><strong>Price:</strong> ${d.price}</p>
            <p><strong>Description:</strong> {d.description}</p>
            <p><strong>Status:</strong> {d.status}</p>

            {d.status.toLowerCase() === "pending" && (
              <div className="actions">
                <button onClick={() => handleApproval(d.id, "approved")}>✅ Approve</button>
                <button onClick={() => handleApproval(d.id, "rejected")}>❌ Reject</button>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

export default DroneApproval;
