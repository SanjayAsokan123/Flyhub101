// typeDefs/baseTypeDefs.js
import { gql } from "apollo-server-express";

export const baseTypeDefs = gql`
  """ Root types to support modular GraphQL schema """
  type Query
  type Mutation
  type Subscription
`;
