import React, { useState, useEffect } from "react";
import "../styles/Page.css";

const GRAPHQL_URL = "http://127.0.0.1:5001/graphql";

function AccessoriesApproval() {
  const [accessories, setAccessories] = useState([]);
  const [loading, setLoading] = useState(true);

  const fetchAccessories = async () => {
    setLoading(true);
    const query = `
      query {
        accessories {
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
      const rejected = JSON.parse(localStorage.getItem("rejectedAccessories")) || [];
      const filtered = result.data.accessories.filter(
        (a) => !rejected.some((r) => r.id === a.id)
      );
      setAccessories(filtered);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAccessories();
  }, []);

  const handleApproval = async (id, status) => {
    const mutation = `
      mutation {
        updateAccessoryStatus(id: "${id}", status: "${status}") { id status }
      }
    `;
    await fetch(GRAPHQL_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ query: mutation }),
    });
    if (status === "rejected") {
      const store = JSON.parse(localStorage.getItem("rejectedAccessories")) || [];
      store.push({ id });
      localStorage.setItem("rejectedAccessories", JSON.stringify(store));
    }
    fetchAccessories();
  };

  const handleApproveAll = async () => {
    const mutation = `
      mutation {
        approveAllPending(type: "accessories") { success count message }
      }
    `;
    const res = await fetch(GRAPHQL_URL, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ query: mutation }),
    });
    const result = await res.json();
    alert(result.data.approveAllPending.message);
    fetchAccessories();
  };

  if (loading) return <p>Loading accessories...</p>;

  return (
    <div className="page">
      <h2>🎒 Accessories Approval Dashboard</h2>
      <div className="bulk-actions">
        <button className="approve-all-btn" onClick={handleApproveAll}>
          ✅ Approve All Pending Accessories
        </button>
      </div>
      <div className="drone-cards">
        {accessories.map((a) => (
          <div key={a.id} className="drone-card">
            <img src={a.image} alt={a.name} className="drone-image" />
            <h3>{a.name}</h3>
            <p><strong>Brand:</strong> {a.brand}</p>
            <p><strong>Price:</strong> ${a.price}</p>
            <p><strong>Description:</strong> {a.description}</p>
            <p><strong>Status:</strong> {a.status}</p>
            {a.status === "pending" && (
              <div className="actions">
                <button onClick={() => handleApproval(a.id, "approved")}>✅ Approve</button>
                <button onClick={() => handleApproval(a.id, "rejected")}>❌ Reject</button>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}

export default AccessoriesApproval;
