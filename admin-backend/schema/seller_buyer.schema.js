import { gql } from "apollo-server-express";

export const seller_buyer_TypeDefs = gql`
  scalar Upload

  type Seller {
    id: ID!
    name: String
    company: String
    phone: String
    email: String
    PANpdf: String
    gstpdf: String
    bankdetailspdf: String
    authorizedpdf: String
    status: String
  }

  type Buyer {
    id: ID!
    name: String!
    email: String!
    phone: String
  }

  input SellerInput {
    name: String
    company: String
    phone: String
    email: String
    PANpdf: Upload
    gstpdf: Upload
    bankdetailspdf: Upload
    authorizedpdf: Upload
  }

  input BuyerInput {
    name: String!
    email: String!
    phone: String
  }

  type SellerTrend {
    date: String
    count: Int
  }

  type BuyerTrend {
    date: String
    count: Int
  }

  type DashboardStats {
    totalSellers: Int
    approvedSellers: Int
    pendingSellers: Int
    rejectedSellers: Int
    totalBuyers: Int
  }

  type Query {
    getSellers: [Seller]
    getBuyers: [Buyer]

    getSellersByStatus(status: String!): [Seller]

    getDashboardStats: DashboardStats

    getSellerTrends(days: Int): [SellerTrend]
    getBuyerTrends(days: Int): [BuyerTrend]
  }

  type Mutation {
    registerSeller(
      name: String!
      company: String!
      phone: String!
      email: String!
    ): Seller

    uploadSellerDocuments(id: ID!, input: SellerInput!): Seller

    registerBuyer(name: String!, email: String!, phone: String!): Buyer

    changeSellerStatus(id: ID!, status: String!): Seller
  }
`;
