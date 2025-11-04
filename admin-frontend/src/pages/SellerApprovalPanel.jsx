import React, { useState, useEffect, useCallback } from 'react';
import { gql, ApolloClient, InMemoryCache, HttpLink } from '@apollo/client';

const BACKEND_URL = "http://127.0.0.1:5001/graphql";

const client = new ApolloClient({
  link: new HttpLink({ uri: BACKEND_URL }),
  cache: new InMemoryCache({
    typePolicies: {
      Seller: { keyFields: ['customId'] },
    },
  }),
});

// ---------------- GRAPHQL ----------------
const GET_SELLERS_QUERY = gql`
  query {
    getSellers {
      customId
      companyName
      PANnumber
      gstNumber
      email
      phoneNumber
      status
    }
  }
`;

const UPDATE_SELLER_STATUS_MUTATION = gql`
  mutation ($customId: ID!, $status: String!) {
    changeSellerStatus(customId: $customId, status: $status) {
      customId
      companyName
      PANnumber
      gstNumber
      email
      phoneNumber
      status
    }
  }
`;

const DELETE_SELLER_MUTATION = gql`
  mutation ($customId: ID!) {
    deleteSeller(customId: $customId) {
      customId
    }
  }
`;

// ---------------- COMPONENT ----------------
export default function SellerApprovalPanel() {
  const [pending, setPending] = useState([]);
  const [approved, setApproved] = useState([]);
  const [rejected, setRejected] = useState([]);
  const [loading, setLoading] = useState(true);
  const [errMsg, setErrMsg] = useState('');

  const fetchSellers = useCallback(async () => {
    try {
      setErrMsg('');
      setLoading(true);
      const { data } = await client.query({
        query: GET_SELLERS_QUERY,
        fetchPolicy: "no-cache",
      });

      // Filter out any seller with null customId
      const sellers = (data?.getSellers ?? []).filter(s => s.customId != null);

      setPending(sellers.filter(s => s.status === 'pending'));
      setApproved(sellers.filter(s => s.status === 'approved'));
      setRejected(sellers.filter(s => s.status === 'rejected'));
    } catch (err) {
      console.error(err);
      setErrMsg(err?.message || 'Failed to fetch sellers.');
      alert(err?.message || "Failed to fetch sellers.");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchSellers();
  }, [fetchSellers]);

  const updateStatus = useCallback(async (customId, status) => {
    try {
      setErrMsg('');
      await client.mutate({
        mutation: UPDATE_SELLER_STATUS_MUTATION,
        variables: { customId: String(customId), status },
      });
      await fetchSellers(); // refresh after update
    } catch (err) {
      console.error(err);
      setErrMsg(err?.message || 'Failed to update status.');
      alert(err?.message || "Failed to update status.");
    }
  }, [fetchSellers]);

  const deleteSeller = useCallback(async (customId) => {
    if (!window.confirm("Delete this seller?")) return;
    try {
      setErrMsg('');
      await client.mutate({
        mutation: DELETE_SELLER_MUTATION,
        variables: { customId: String(customId) },
      });
      await fetchSellers(); // refresh after delete
    } catch (err) {
      console.error(err);
      setErrMsg(err?.message || 'Failed to delete seller.');
      alert(err?.message || "Failed to delete seller.");
    }
  }, [fetchSellers]);

  if (loading) return <p>Loading sellers...</p>;

  const renderTable = (title, list, actions) => (
    <>
      <h2>{title}</h2>
      <table border="1" cellPadding="5" width="100%">
        <thead>
          <tr>
            <th>Custom ID</th>
            <th>Company</th>
            <th>PAN</th>
            <th>GST</th>
            <th>Email</th>
            <th>Phone</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {(!list || list.length === 0) ? (
            <tr><td colSpan="7">No sellers found</td></tr>
          ) : list.map(s => (
            <tr key={s.customId}>
              <td>{s.customId}</td>
              <td>{s.companyName}</td>
              <td>{s.PANnumber}</td>
              <td>{s.gstNumber || '-'}</td>
              <td>{s.email}</td>
              <td>{s.phoneNumber}</td>
              <td>{actions(s)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </>
  );

  return (
    <div style={{ padding: 20 }}>
      <h1>Seller Approval Panel</h1>

      {!!errMsg && (
        <div style={{ marginBottom: 12, color: 'crimson' }}>
          {errMsg}
        </div>
      )}

      {renderTable("⏳ Pending", pending, s => (
        <>
          <button onClick={() => updateStatus(s.customId, 'approved')}>Approve</button>
          <button onClick={() => updateStatus(s.customId, 'rejected')}>Reject</button>
          <button onClick={() => deleteSeller(s.customId)}>Delete</button>
        </>
      ))}

      {renderTable("✅ Approved", approved, s => (
        <>
          <button onClick={() => updateStatus(s.customId, 'pending')}>Revert</button>
          <button onClick={() => deleteSeller(s.customId)}>Delete</button>
        </>
      ))}

      {renderTable("❌ Rejected", rejected, s => (
        <>
          <button onClick={() => updateStatus(s.customId, 'pending')}>Revert</button>
          <button onClick={() => deleteSeller(s.customId)}>Delete</button>
        </>
      ))}
    </div>
  );
}
