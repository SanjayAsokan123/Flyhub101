import React, { useState, useEffect } from "react";
import "../styles/Page.css";

const GRAPHQL_URL = "http://127.0.0.1:5001/graphql";

function PartsApproval() {
  const [parts, setParts] = useState([]);
  const [loading, setLoading] = useState(true);

  const fetchParts = async () => {
    setLoading(true);
    const query = `
      query {
        parts {
          id name brand price description image status
        }
      }
    `;
    try {
      const res = await fetch(GRAPHQL_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ query }),
      });
      const result = await res.json();
      const rejected = JSON.parse(localStorage.getItem("rejectedParts")) || [];
      const filtered = result.data.parts.filter(
        (p) => !rejected.some((r) => r.id === p.id)
      );
      setParts(filtered);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchParts();
  }, []);

  const handleApproval = async (id, status) => {
    const mutation = `
      mutation {
        updatePartStatus(id: "${id}", status: "${status}") { id status }
      }
    `;
    await fetch(GRAPHQL_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ query: mutation }),
    });
    if (status === "rejected") {
      const store = JSON.parse(localStorage.getItem("rejectedParts")) || [];
      store.push({ id });
      localStorage.setItem("rejectedParts", JSON.stringify(store));
    }
    fetchParts();
  };

  const handleApproveAll = async () => {
    const mutation = `
      mutation {
        approveAllPending(type: "parts") { success count message }
      }
    `;
    const res = await fetch(GRAPHQL_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ query: mutation }),
    });
    const result = await res.json();
    alert(result.data.approveAllPending.message);
    fetchParts();
  };

  if (loading) return <p>Loading parts...</p>;

  return (
    <div className="page">
      <h2>⚙️ Parts Approval Dashboard</h2>
      <div className="bulk-actions">
        <button className="approve-all-btn" onClick={handleApproveAll}>
          ✅ Approve All Pending Parts
        </button>
      </div>
      <div className="drone-cards">
        {parts.map((p) => (
          <div key={p.id} className="drone-card">
            <img src={p.image} alt={p.name} className="drone-image" />
            <h3>{p.name}</h3>
            <p><strong>Brand:</strong> {p.brand}</p>
            <p><strong>Price:</strong> ${p.price}</p>
            <p><strong>Description:</strong> {p.description}</p>
            <p><strong>Status:</strong> {p.status}</p>
            {p.status === "pending" && (
              <div className="actions">
                <button onClick={() => handleApproval(p.id, "approved")}>✅ Approve</button>
                <button onClick={() => handleApproval(p.id, "rejected")}>❌ Reject</button>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

export default PartsApproval;
