import React, { useCallback, useEffect, useState } from "react";
import { gql, ApolloClient, InMemoryCache, HttpLink } from "@apollo/client";
import "../styles/SellerApprove.css";

const BACKEND_URL = "http://127.0.0.1:5001/graphql";
const client = new ApolloClient({
  link: new HttpLink({ uri: BACKEND_URL }),
  cache: new InMemoryCache({
    typePolicies: {
      Seller: { keyFields: ["customId"] },
    },
  }),
});

/* GraphQL */
const GET_SELLERS_QUERY = gql`
  query GetSellers {
    getSellers {
      customId
      firebaseUid
      name
      companyName
      PANnumber
      gstNumber
      address
      bankIFCnumber
      bankAccountNumber
      authorized
      email
      phoneNumber
      status
      shippingAddresses
      pickupAddresses
      companyPan
      bankName
    }
  }
`;

const UPDATE_SELLER_STATUS_MUTATION = gql`
  mutation ChangeSellerStatus($customId: ID!, $status: String!) {
    changeSellerStatus(customId: $customId, status: $status) {
      customId
      status
    }
  }
`;

const DELETE_SELLER_MUTATION = gql`
  mutation DeleteSeller($customId: ID!) {
    deleteSeller(customId: $customId) {
      customId
    }
  }
`;

export default function SellerApprovalPanel() {
  const [pending, setPending] = useState([]);
  const [approved, setApproved] = useState([]);
  const [rejected, setRejected] = useState([]);
  const [loading, setLoading] = useState(true);
  const [errMsg, setErrMsg] = useState("");
  const [actionLoading, setActionLoading] = useState(false);

  const fetchSellers = useCallback(async () => {
    try {
      setErrMsg("");
      setLoading(true);

      const { data } = await client.query({
        query: GET_SELLERS_QUERY,
        fetchPolicy: "no-cache",
      });

      const sellers = (data?.getSellers ?? []).filter((s) => s?.customId);

      setPending(sellers.filter((s) => s.status === "pending"));
      setApproved(sellers.filter((s) => s.status === "approved"));
      setRejected(sellers.filter((s) => s.status === "rejected"));
    } catch (err) {
      console.error("Fetch error:", err);
      setErrMsg(err?.message || "Failed to fetch sellers.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchSellers();
  }, [fetchSellers]);

  const updateStatus = useCallback(
    async (customId, status) => {
      if (!customId) return;

      if (!window.confirm(`Change status of ${customId} → ${status}?`)) return;

      try {
        setActionLoading(true);
        await client.mutate({
          mutation: UPDATE_SELLER_STATUS_MUTATION,
          variables: { customId: String(customId), status },
        });
        await fetchSellers();
      } catch (err) {
        console.error("Update error:", err);
        alert(err?.message || "Failed to update status.");
      } finally {
        setActionLoading(false);
      }
    },
    [fetchSellers]
  );

  const deleteSeller = useCallback(
    async (customId) => {
      if (!customId) return;

      if (!window.confirm("Delete this seller permanently?")) return;

      try {
        setActionLoading(true);
        await client.mutate({
          mutation: DELETE_SELLER_MUTATION,
          variables: { customId: String(customId) },
        });
        await fetchSellers();
      } catch (err) {
        console.error("Delete error:", err);
        alert(err?.message || "Failed to delete seller.");
      } finally {
        setActionLoading(false);
      }
    },
    [fetchSellers]
  );

  if (loading) return <p>Loading sellers...</p>;

  const renderTable = (title, list, actions) => (
    <section style={{ marginBottom: 35 }}>
      <h2>{title}</h2>

      <div style={{ overflowX: "auto" }}>
        <table style={{ width: "100%", borderCollapse: "collapse" }}>
          <thead>
            <tr>
              {[
                "Custom ID",
                "Firebase UID",
                "Name",
                "Company",
                "PAN",
                "GST",
                "Address",
                "Bank IFC",
                "Bank Acc No",
                "Bank Name",
                "Authorized",
                "Email",
                "Phone",
                "Company PAN",
                "Shipping Addresses",
                "Pickup Addresses",
                "Actions",
              ].map((h) => (
                <th key={h} style={thStyle}>
                  {h}
                </th>
              ))}
            </tr>
          </thead>

          <tbody>
            {!list || list.length === 0 ? (
              <tr>
                <td colSpan="17" style={emptyCellStyle}>
                  No sellers found
                </td>
              </tr>
            ) : (
              list.map((s) => (
                <tr key={s.customId}>
                  <td style={tdStyle}>{s.customId}</td>
                  <td style={tdStyle}>{s.firebaseUid}</td>
                  <td style={tdStyle}>{s.name}</td>
                  <td style={tdStyle}>{s.companyName}</td>
                  <td style={tdStyle}>{s.PANnumber}</td>
                  <td style={tdStyle}>{s.gstNumber}</td>
                  <td style={tdStyle}>{s.address}</td>
                  <td style={tdStyle}>{s.bankIFCnumber}</td>
                  <td style={tdStyle}>{s.bankAccountNumber}</td>
                  <td style={tdStyle}>{s.bankName}</td>
                  <td style={tdStyle}>{s.authorized}</td>
                  <td style={tdStyle}>{s.email}</td>
                  <td style={tdStyle}>{s.phoneNumber}</td>
                  <td style={tdStyle}>{s.companyPan}</td>
                  <td style={tdStyle}>{s.shippingAddresses?.join(", ")}</td>
                  <td style={tdStyle}>{s.pickupAddresses?.join(", ")}</td>

                  <td style={tdStyle}>{actions(s)}</td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </section>
  );

  return (
    <div style={{ padding: 20 }}>
      <h1>Seller Approval Panel</h1>

      {!!errMsg && (
        <div style={{ marginBottom: 12, color: "crimson" }}>{errMsg}</div>
      )}

      {renderTable("⏳ Pending", pending, (s) => (
        <div style={{ display: "flex", gap: 8 }}>
          <button disabled={actionLoading} onClick={() => updateStatus(s.customId, "approved")}>
            Approve
          </button>
          <button disabled={actionLoading} onClick={() => updateStatus(s.customId, "rejected")}>
            Reject
          </button>
          <button disabled={actionLoading} onClick={() => deleteSeller(s.customId)}>
            Delete
          </button>
        </div>
      ))}

      {renderTable("✅ Approved", approved, (s) => (
        <div style={{ display: "flex", gap: 8 }}>
          <button disabled={actionLoading} onClick={() => updateStatus(s.customId, "pending")}>
            Revert
          </button>
          <button disabled={actionLoading} onClick={() => deleteSeller(s.customId)}>
            Delete
          </button>
        </div>
      ))}

      {renderTable("❌ Rejected", rejected, (s) => (
        <div style={{ display: "flex", gap: 8 }}>
          <button disabled={actionLoading} onClick={() => updateStatus(s.customId, "pending")}>
            Revert
          </button>
          <button disabled={actionLoading} onClick={() => deleteSeller(s.customId)}>
            Delete
          </button>
        </div>
      ))}
    </div>
  );
}

/* table styles */
const thStyle = {
  textAlign: "left",
  padding: "8px 10px",
  borderBottom: "1px solid #ddd",
  background: "#fafafa",
  fontWeight: "600",
  whiteSpace: "nowrap",
};

const tdStyle = {
  padding: "8px 10px",
  borderBottom: "1px solid #eee",
  verticalAlign: "top",
};

const emptyCellStyle = {
  padding: 12,
  textAlign: "center",
  color: "#666",
};
