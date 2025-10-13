import { gql } from "apollo-server-express";

export const marketplaceTypeDefs = gql`
  type MarketplaceItem {
    id: ID!
    name: String!
    brand: String
    price: Float
    description: String
    image: String
    category: String!
    status: String
  }
type BulkApprovalResponse {
  success: Boolean!
  type: String!
  count: Int!
  message: String!
}

  extend type Query {
    # type can be: "drones" | "parts" | "accessories" | "all"
    marketplace(type: String!): [MarketplaceItem!]!
  }


extend type Mutation {
  approveAllPending(type: String!): BulkApprovalResponse!
}
`;
