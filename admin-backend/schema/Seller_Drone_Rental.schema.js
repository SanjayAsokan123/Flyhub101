import { gql } from "apollo-server-express";

export const sellerDroneRentalTypeDefs = gql`

  type SellerDroneRental {
    _id: ID!
    sellerId: ID!
    name: String!
    phone: String!
    location: String!
    price: String!
    status: String!   # arrived | completed | rejected
    createdAt: String
  }

  # ============================
  # QUERIES
  # ============================
  type Query {
    getSellerArrivedBookings(sellerId: ID!): [SellerDroneRental]
    getSellerCompletedBookings(sellerId: ID!): [SellerDroneRental]
  }

  # ============================
  # MUTATIONS
  # ============================
  type Mutation {
    approveSellerDroneRental(rentalId: ID!): SellerDroneRental
    rejectSellerDroneRental(rentalId: ID!): SellerDroneRental
  }
`;
