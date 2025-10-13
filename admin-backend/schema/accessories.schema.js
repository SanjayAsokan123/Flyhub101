import { gql } from "apollo-server-express";

export const accessoryTypeDefs = gql`
  type Accessory {
    id: ID!
    name: String!
    brand: String!
    category: String
    price: Float!
    description: String!
    image: String
    status: String!
  }

  input AccessoryInput {
    name: String!
    brand: String!
    category: String
    price: Float!
    description: String!
    image: String
  }

  type Query {
    accessories: [Accessory]
    accessory(id: ID!): Accessory
    rejectedAccessories: [Accessory!]!
  }

type BulkApprovalResponse {
  success: Boolean!
  count: Int!
}

type Mutation {
  createAccessory(input: AccessoryInput!): Accessory
  updateAccessory(id: ID!, input: AccessoryInput!): Accessory
  updateAccessoryStatus(id: ID!, status: String!): Accessory
  deleteAccessory(id: ID!): Accessory
  approveAllPendingAccessories: BulkApprovalResponse
  }
`;
