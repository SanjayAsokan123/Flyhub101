import { gql } from "apollo-server-express";

export const droneTypeDefs = gql`
  type Drone {
    id: ID!
    name: String!
    brand: String!
    uin: String
    price: Float!
    description: String!
    image: String
    status: String!
  }

  input DroneInput {
    name: String!
    brand: String!
    uin: String
    price: Float!
    description: String!
    image: String
  }

  # 🧩 Home Screen Structure for Flutter
  type HomeCategory {
    cname: String!
    image: String!
    click_url: String!
  }

  type TemplateSection {
    template: String!
    items: [HomeCategory!]!
  }

  type Query {
    drones: [Drone!]!
    drone(id: ID!): Drone
    rejectedDrones: [Drone!]!
    homeRequest: [TemplateSection!]!
  }

type BulkApprovalResponse {
  success: Boolean!
  count: Int!
}

  type Mutation {
    createDrone(input: DroneInput!): Drone
    updateDrone(id: ID!, input: DroneInput!): Drone
    updateDroneStatus(id: ID!, status: String!): Drone
    deleteDrone(id: ID!): Drone
    approveAllPendingDrones: BulkApprovalResponse
  }
`;
