import { gql } from "apollo-server-express";

export const rentalTypeDefs = gql`
  type RentalDrone {
    id: ID!
    name: String!
    brand: String!
    uin: String
    price: Float!
    description: String!
    image: String
    duration: String
    with_pilot: Boolean
    insurance: Boolean
    available_today: Boolean
    status: String!
  }

  input RentalDroneInput {
    name: String!
    brand: String!
    uin: String
    price: Float!
    description: String!
    image: String
    duration: String
    with_pilot: Boolean
    insurance: Boolean
    available_today: Boolean
    status: String
  }

  type BulkApprovalResponse {
    success: Boolean!
    count: Int!
  }

  type Query {
    rentalDrones: [RentalDrone!]!
    rentalDrone(id: ID!): RentalDrone
    rejectedRentalDrones: [RentalDrone!]!
    pendingRentalDrones: [RentalDrone!]!
  }

  type Mutation {
    createRentalDrone(input: RentalDroneInput!): RentalDrone
    updateRentalDrone(id: ID!, input: RentalDroneInput!): RentalDrone
    updateRentalDroneStatus(id: ID!, status: String!): RentalDrone
    deleteRentalDrone(id: ID!): RentalDrone
    approveAllPendingRentalDrones: BulkApprovalResponse
  }
`;
