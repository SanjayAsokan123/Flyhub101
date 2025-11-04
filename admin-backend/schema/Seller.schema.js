import { gql } from 'apollo-server-express';

export const sellerTypeDefs = gql`
  """
  🧾 Seller Type
  Represents a registered or pending seller in the FlyHub system.
  """
  type Seller {
    customId: ID
    name: String
    companyName: String
    PANnumber: String
    gstNumber: String
    address: String
    bankIFCnumber: String
    bankAccountNumber: String
    authorized: String
    email: String!
    phoneNumber: String
    status: String
    shippingAddresses: [String!]
    pickupAddresses: [String!]
    companyPan: String
    bankName: String
    Drones: [Drone!]
  }

  """
  ✏️ Seller Input
  Used when creating or updating seller details manually.
  """
  input SellerInput {
    name: String!
    companyName: String!
    PANnumber: String!
    gstNumber: String
    address: String!
    bankIFCnumber: String!
    bankAccountNumber: String!
    authorized: String!
    email: String!
    phoneNumber: String!
    shippingAddresses: [String!]
    pickupAddresses: [String!]
    companyPan: String!
    bankName: String!
  }

  """
  📱 FCM Token Update Response
  """
  type UpdateTokenResponse {
    success: Boolean!
    message: String!
    seller: Seller
  }

  """
  🔍 Query Definitions
  """
type Query {
  getSellersByStatus(status: String!): [Seller!]!
  getSellers: [Seller!]!
  getSeller(customId: ID!): Seller

  # 🔍 Unified seller lookup for Firebase/Auth login
  sellerByEmail(
    email: String
    username: String
    phone: String
    customId: String
  ): Seller
}


  """
  🔧 Mutation Definitions
  """
  type Mutation {
    # 🟢 Create a new seller manually (admin or registration form)
    createSeller(input: SellerInput!): Seller!

    # ✏️ Update existing seller details
    updateSeller(customId: ID!, input: SellerInput!): Seller!

    # 🔄 Change seller status (pending → approved / rejected)
    changeSellerStatus(customId: ID!, status: String!): Seller!

    # 🗑️ Delete a seller
    deleteSeller(customId: ID!): Seller

    # 📲 Register or update FCM token
    updateSellerFcmToken(customId: String!, token: String!): UpdateTokenResponse!
  }
`;
