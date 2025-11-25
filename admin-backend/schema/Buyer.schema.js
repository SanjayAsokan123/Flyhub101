import { gql } from "apollo-server-express";

export const buyerTypeDefs = gql`

  type Buyer {
    id: ID
    buyerId: String
    name: String
    email: String
    phone: String
    token: String
    createdAt: String      # 🔥 Added
    updatedAt: String      # (optional, but useful)
  }

  type Query {
    buyers: [Buyer]

    buyer(id: ID!): Buyer
  }

  # ============================================================
  # 📌 MUTATIONS
  # ============================================================
  type Mutation {
    signupBuyer(
      name: String!
      email: String!
      phone: String!
      password: String!
      firebaseUid: String!
    ): Buyer

    """
    🔵 Buyer Login
    Unified login using:
    - Email
    - Phone
    - BuyerID (FLYHUBB0001)
    """
    loginBuyer(
      input: String!
      password: String!
    ): Buyer

    """
    🔵 OTP Login (Firebase UID only)
    Used when buyer verifies OTP in mobile app
    """
    loginBuyerOtp(
      firebaseUid: String!
    ): Buyer

    """
    ✏️ Update Buyer Profile
    Optional fields
    """
    updateBuyer(
      buyerId: ID!
      name: String
      email: String
      phone: String
      password: String
    ): Buyer

    """
    🗑️ Delete Buyer Account
    Admin or self-delete
    """
    deleteBuyer(buyerId: ID!): String
  }
`;
