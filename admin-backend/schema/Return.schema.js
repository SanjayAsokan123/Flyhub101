import { gql } from "apollo-server-express";

export const returnTypeDefs = gql`
  """ Seller information attached to a return """
  type SellerDetails {
    sellerId: String
    name: String
    phone: String
    email: String
    address: String
  }

  """ Buyer information attached to a return """
  type BuyerDetails {
    buyerId: String
    name: String
    email: String
    phone: String
    address: String
  }

  """ Represents a return request record """
  type ReturnRequest {
    returnId: String
    orderId: String
    productId: String
    type: String
    reason: String
    deliveryDate: String
    status: String
    proofUrl: String
    seller: SellerDetails
    buyer: BuyerDetails
  }

  """ Input for creating or updating a return request """
  input ReturnRequestInput {
    orderId: String
    productId: String
    type: String
    reason: String
    deliveryDate: String
    proofUrl: String
  }

  extend type Query {
    """ Fetch all return requests """
    returnRequests: [ReturnRequest]

    """ Fetch return requests filtered by status """
    returnRequestsByStatus(status: String!): [ReturnRequest]
  }

  extend type Mutation {
    """ Buyer requests a product return """
    requestReturn(data: ReturnRequestInput!): ReturnRequest

    """ Update existing return request details (reason, proof, etc.) """
    updateReturnRequest(returnId: String!, data: ReturnRequestInput): ReturnRequest  # ✅ Added

    """ Update return status (admin or seller approval) """
    updateReturnStatus(returnId: String!, status: String!): ReturnRequest

    """ Delete a return request """
    deleteReturn(returnId: String!): ReturnRequest
  }
`;
