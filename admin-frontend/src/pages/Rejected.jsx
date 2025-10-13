import React, { useState, useEffect } from "react";
import "../styles/Rejected.css";

const GRAPHQL_URL = "http://127.0.0.1:5001/graphql";

function Rejected() {
  const [activeType, setActiveType] = useState("drone"); // drone / accessory / part
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Fetch rejected items based on type
  const fetchRejectedItems = async (type) => {
    setLoading(true);
    setError(null);

    // Map type to GraphQL query name
    let queryName;
    switch (type) {
      case "drone":
        queryName = "drones";
        break;
      case "accessory":
        queryName = "accessories";
        break;
      case "part":
        queryName = "parts";
        break;
      default:
        queryName = "drones";
    }

  const queryFields = `
  id
  name
  brand
  ${type === "drone" ? "uin" : ""}
  price
  description
  image
  status
`;

const query = `
  query {
    ${queryName} {
      ${queryFields}
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
      if (result.errors) {
        setError(result.errors[0].message);
      } else {
        const rejectedItems = result.data[queryName].filter(
          (item) => item.status.toLowerCase() === "rejected"
        );
        setItems(rejectedItems);
      }
    } catch (err) {
      setError("Network error: " + err.message);
    } finally {
      setLoading(false);
    }
  };

  // Fetch items whenever type changes
  useEffect(() => {
    fetchRejectedItems(activeType);
  }, [activeType]);

  // Delete item
  const handleDelete = async (id) => {
    const mutationName = activeType === "drone" ? "deleteDrone" :
                         activeType === "accessory" ? "deleteAccessory" :
                         "deletePart";

    const mutation = `
      mutation {
        ${mutationName}(id: "${id}") {
          id
        }
      }
    `;

    try {
      const response = await fetch(GRAPHQL_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ query: mutation }),
      });
      const result = await response.json();
      if (!result.errors) {
        setItems((prev) => prev.filter((item) => item.id !== id));
      }
    } catch (err) {
      console.error("Delete error:", err);
    }
  };

  if (loading) return <p>Loading rejected {activeType}s...</p>;
  if (error) return <p style={{ color: "red" }}>Error: {error}</p>;

  return (
    <div className="page">
      <h2>🚫 Rejected Items</h2>

      <div className="type-buttons">
        <button onClick={() => setActiveType("drone")} className={activeType==="drone" ? "active" : ""}>Drones</button>
        <button onClick={() => setActiveType("part")} className={activeType==="part" ? "active" : ""}>Parts</button>
        <button onClick={() => setActiveType("accessory")} className={activeType==="accessory" ? "active" : ""}>Accessories</button>
      </div>

      <div className="cards-container">
        {items.length === 0 && <p>No rejected {activeType}s yet.</p>}
        {items.map((item) => (
          <div key={item.id} className="card">
            <img src={item.image} alt={item.name} className="card-image" />
            <h3>{item.name}</h3>
            <p><strong>Brand:</strong> {item.brand}</p>
           {activeType === "drone" && item?.uin && (
  <p><strong>UIN:</strong> {item.uin}</p>
)}

            <p><strong>Price:</strong> ${item.price}</p>
            <p><strong>Description:</strong> {item.description}</p>
            <p><strong>Status:</strong> ❌ Rejected</p>
            <button className="delete-btn" onClick={() => handleDelete(item.id)}>🗑</button>
          </div>
        ))}
      </div>
    </div>
  );
}

export default Rejected;