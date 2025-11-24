import { gql } from "apollo-server-express";

export const sellerTypeDefs = gql`
  """
  🧾 Seller Type
  Represents a registered or pending seller in FlyHub.
  Works with Firebase UID + loginIndex (email / phone / sellerId)
  """
  type Seller {
    customId: ID
    firebaseUid: String!
    name: String
    companyName: String
    PANnumber: String
    gstNumber: String
    address: String
    bankIFCnumber: String
    bankAccountNumber: String
    authorized: String
    email: String
    phoneNumber: String
    status: SellerStatus
    shippingAddresses: [String!]
    pickupAddresses: [String!]
    companyPan: String
    bankName: String

    # Multi-device FCM support
    fcmTokens: [String!]
    fcmToken: String

    Drones: [Drone!]
  }

  """
  🔄 Seller account status enum
  """
  enum SellerStatus {
    pending
    approved
    rejected
  }

  """
  ✏️ Seller Input (Registration / Update)
  Fields made optional because Firebase auto-creates minimal sellers
  """
input SellerInput {
  name: String
  companyName: String
  PANnumber: String
  gstNumber: String
  address: String
  bankIFCnumber: String
  bankAccountNumber: String
  authorized: String
  email: String
  phoneNumber: String
  shippingAddresses: [String!]
  pickupAddresses: [String!]
  companyPan: String
  bankName: String
  firebaseUid: String   # <-- ADD THIS
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
    getSellersByStatus(status: SellerStatus!): [Seller!]!
    getSellers: [Seller!]!
    getSeller(customId: ID!): Seller

    """
    Firebase/Auth unified lookup:
    email / username / phone / sellerId
    Auto-creates pending seller if not found
    """
    sellerByEmail(
      email: String
      username: String
      phone: String
      customId: String
    ): Seller

    """
    Lookup by ANY login key (email, phone, sellerId)
    Used by your unified login logic
    """
    getSellerByLoginKey(key: String!): Seller
  }

  """
  🔧 Mutation Definitions
  """
  type Mutation {
    # 🟢 Create seller (registration form / admin)
    createSeller(input: SellerInput!): Seller!

    # ✏️ Update seller details
    updateSeller(customId: ID!, input: SellerInput!): Seller!

    # 🔄 Change seller status
    changeSellerStatus(customId: ID!, status: SellerStatus!): Seller!

    # 🗑️ Delete a seller
    deleteSeller(customId: ID!): Seller

    # 📲 Register FCM token
    updateSellerFcmToken(customId: String!, token: String!): UpdateTokenResponse!
  }
`;
