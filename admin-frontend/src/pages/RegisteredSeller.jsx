import React, { useEffect, useState } from "react";
import "../styles/RegisteredSeller.css";

const GRAPHQL_URL = "http://127.0.0.1:5001/graphql";

function RegisteredSeller() {
  const [sellers, setSellers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const fetchSellers = async () => {
    setLoading(true);
    setError(null);

    const query = `
      query GetSellers {
        getSellers {
          customId
          name
          companyName
          email
          phoneNumber
          createdAt
        }
      }
    `;

    try {
      const res = await fetch(GRAPHQL_URL, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ query }),
      });

      if (!res.ok) throw new Error("HTTP " + res.status);

      const result = await res.json();
      console.log("Fetched sellers:", result);

      if (result.errors) {
        setError(result.errors[0].message);
        setSellers([]);
        return;
      }

      setSellers(result.data.getSellers || []);

    } catch (err) {
      console.error("Seller fetch error:", err);
      setError("Network error: " + err.message);
      setSellers([]);
    }

    setLoading(false);
  };

  useEffect(() => {
    fetchSellers();
  }, []);

  // ---------------------
  // Date Formatters
  // ---------------------
  const parseDate = (value) => {
    if (!value) return null;

    if (!isNaN(value)) {
      if (value.toString().length === 10) return new Date(value * 1000);
      return new Date(Number(value));
    }

    const d = new Date(value);
    return isNaN(d.getTime()) ? null : d;
  };

  const formatFullDate = (dateValue) => {
    const date = parseDate(dateValue);
    if (!date) return "Invalid Date";

    return date.toLocaleDateString("en-US", {
      day: "numeric",
      month: "long",
      year: "numeric",
    });
  };

  const formatShortDate = (dateValue) => {
    const date = parseDate(dateValue);
    if (!date) return "—";
    return date.toISOString().slice(0, 10);
  };

  if (loading) return <div className="rs-loading">Loading sellers...</div>;
  if (error) return <div className="rs-error">Error: {error}</div>;

  return (
    <div className="registered-seller-container">
      <h1 className="rs-title">Registered Sellers</h1>

      <div className="rs-table-wrapper">
        <table className="rs-table">
          <thead>
            <tr>
              <th>Seller ID</th>
              <th>Name</th>
              <th>Company</th>
              <th>Email</th>
              <th>Phone</th>
              <th>Joined</th>
            </tr>
          </thead>
          <tbody>
            {sellers.map((seller) => (
              <tr key={seller.customId}>
                <td>{seller.customId}</td>
                <td>{seller.name}</td>
                <td>{seller.companyName}</td>
                <td>{seller.email}</td>
                <td>{seller.phoneNumber}</td>
                <td>
                  {formatShortDate(seller.createdAt)}
                  <br />
                  <small className="seller-date-sub">
                    {formatFullDate(seller.createdAt)}
                  </small>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export default RegisteredSeller;
