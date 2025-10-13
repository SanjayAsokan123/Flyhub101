import React from "react";
import { gql, useQuery } from '@apollo/client';

import Cards from "./Cards";
import Charts from "./Charts";
import Activity from "./Activity";
import "../styles/Page.css";

const GET_DASHBOARD_STATS = gql`
  query {
    getDashboardStats {
      totalSellers
      approvedSellers
      pendingSellers
      rejectedSellers
      totalBuyers
    }
  }
`;

export default function Dashboard() {
  const { loading, error, data } = useQuery(GET_DASHBOARD_STATS);

  if (loading) return <p>Loading dashboard...</p>;
  if (error) return <p style={{ color: "red" }}>Error: {error.message}</p>;

  const stats = data.getDashboardStats;

  return (
    <div className="page dashboard-page">
      <h2>⚡ Flyhub Admin Dashboard</h2>
      {/* Dynamic cards */}
      <Cards stats={stats} />

      {/* Charts (you’ll replace static data soon) */}
      <Charts stats={stats} />

      <Activity />
    </div>
  );
}
