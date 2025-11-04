import { gql } from "apollo-server-express";

export const notificationTypeDefs = gql`
  """ Allows flexible JSON structures in notifications """
  scalar JSON

  """ Notification structure for sellers or admins """
  type Notification {
    notificationId: String!
    sellerId: String!
    title: String!
    message: String!
    type: String
    data: JSON
    url: String
    read: Boolean
    createdAt: String
  }

  """ Input type for creating notifications manually (optional) """
  input NotificationInput {
    sellerId: String!
    title: String!
    message: String!
    type: String
    data: JSON
    url: String
  }

  extend type Query {
    """ Fetch notifications for a specific seller/admin """
    notificationsBySeller(
      sellerId: String!
      status: String
      limit: Int = 50
      skip: Int = 0
    ): [Notification!]!

    """ Get unread notification count (for badges) """
    unreadNotificationCount(sellerId: String!): Int!  # ✅ Added this
  }

  extend type Mutation {
    """ Mark one notification as read """
    markNotificationRead(notificationId: String!): Notification

    """ Mark all notifications as read for a seller """
    markAllNotificationsRead(sellerId: String!): Boolean

    """ Delete all notifications for a seller (optional cleanup) """
    deleteNotifications(sellerId: String!): Boolean

    createTestNotification(
      sellerId: String!
      title: String!
      message: String!
      type: String
      url: String
    ): Notification
  }

  extend type Subscription {
    """ Real-time notification push for a seller """
    notificationAdded(sellerId: String!): Notification
  }
`;
